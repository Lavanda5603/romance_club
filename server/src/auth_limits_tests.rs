use super::*; // Подключаю ограничения попыток
use crate::{auth_service::AuthApiService, jwt::JwtKeys, romance_club::{auth_api_client::AuthApiClient, auth_api_server::AuthApiServer, LoginRequest, RegisterRequest}}; // Подключаю публичный API входа
use surrealdb::{Surreal, engine::remote::ws::Client}; // Подключаю пустое тестовое соединение
use tonic::{Code, transport::{Server, server::TcpConnectInfo}}; // Подключаю gRPC и настоящий адрес клиента

fn setup(capacity: usize) -> (Arc<AuthLimits>, Arc<Mutex<Instant>>) {
    let clock = Arc::new(Mutex::new(Instant::now()));
    let current = clock.clone();
    (Arc::new(AuthLimits::testing(capacity, Arc::new(move || *current.lock().unwrap()))), clock)
}
fn advance(clock: &Mutex<Instant>, seconds: u64) { *clock.lock().unwrap() += Duration::from_secs(seconds); }
fn ip(last: u8) -> IpAddr { IpAddr::V4(Ipv4Addr::new(127,0,0,last)) }
fn retry(status: Status) -> u64 {
    assert_eq!(status.code(), Code::ResourceExhausted);
    status.metadata().get("retry-after").unwrap().to_str().unwrap().parse().unwrap()
}

#[test]
fn source_and_registration_have_separate_quotas() {
    let (limits, clock) = setup(100);
    for _ in 0..30 { limits.check_source(ip(1),Operation::Login).unwrap(); }
    assert_eq!(retry(limits.check_source(ip(1),Operation::Login).unwrap_err()),60);
    limits.check_source(ip(2),Operation::Login).unwrap();
    advance(&clock,60);
    for _ in 0..5 { limits.check_source(ip(1),Operation::Register).unwrap(); }
    assert_eq!(retry(limits.check_source(ip(1),Operation::Register).unwrap_err()),60);
    limits.check_source(ip(1),Operation::Login).unwrap();
}

#[test]
fn pair_cooldown_expires_without_extension_by_denied_requests() {
    let (limits, clock) = setup(100);
    for _ in 0..5 { limits.check_account(ip(1),"alice",Operation::Login).unwrap(); }
    assert_eq!(retry(limits.check_account(ip(1),"alice",Operation::Login).unwrap_err()),30);
    limits.check_account(ip(2),"alice",Operation::Login).unwrap();
    limits.check_account(ip(1),"bob",Operation::Login).unwrap();
    advance(&clock,29);
    for _ in 0..10 { assert_eq!(retry(limits.check_account(ip(1),"alice",Operation::Login).unwrap_err()),1); }
    advance(&clock,1);
    limits.check_account(ip(1),"alice",Operation::Login).unwrap();
}

#[test]
fn changing_sources_cannot_bypass_the_account_quota() {
    let (limits, clock) = setup(100);
    for source in 1..=20 { limits.check_account(ip(source),"alice",Operation::Login).unwrap(); }
    assert_eq!(retry(limits.check_account(ip(21),"alice",Operation::Login).unwrap_err()),60);
    limits.check_account(ip(21),"bob",Operation::Login).unwrap();
    limits.check_account(ip(21),"alice",Operation::Register).unwrap();
    advance(&clock,60);
    limits.check_account(ip(21),"alice",Operation::Login).unwrap();
}

#[test]
fn counter_storage_is_bounded_and_expired_entries_are_removed() {
    let (limits, clock) = setup(4);
    for source in 1..=4 { limits.check_source(ip(source),Operation::Login).unwrap(); }
    assert_eq!(retry(limits.check_source(ip(5),Operation::Login).unwrap_err()),1);
    assert_eq!(limits.state.lock().unwrap().entries.len(),4);
    limits.check_source(ip(1),Operation::Login).unwrap();
    advance(&clock,60);
    limits.check_source(ip(5),Operation::Login).unwrap();
    assert_eq!(limits.state.lock().unwrap().entries.len(),1);
}

#[test]
fn transport_ip_ignores_forwarded_headers_ports_and_ipv4_mapped_aliases() {
    let mut request = Request::new(());
    request.metadata_mut().insert("x-forwarded-for","8.8.8.8".parse().unwrap());
    request.extensions_mut().insert(TcpConnectInfo {local_addr:None,remote_addr:Some("[::ffff:127.0.0.1]:1234".parse().unwrap())});
    assert_eq!(peer_ip(&request),ip(1));
    request.extensions_mut().insert(TcpConnectInfo {local_addr:None,remote_addr:Some("127.0.0.1:9876".parse().unwrap())});
    assert_eq!(peer_ip(&request),ip(1));
    assert_eq!(peer_ip(&Request::new(())),IpAddr::V4(Ipv4Addr::UNSPECIFIED));
}

#[test]
fn field_limits_are_in_bytes_and_apply_before_expensive_work() {
    check_fields(&"a".repeat(64),Some(&"e".repeat(254)),&"я".repeat(512)).unwrap();
    for result in [check_fields(&"a".repeat(65),None,"Password1!"),
        check_fields("alice",Some(&"e".repeat(255)),"Password1!"),check_fields("alice",None,&"я".repeat(513))] {
        assert_eq!(result.unwrap_err().code(),Code::InvalidArgument);
    }
}

#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
async fn concurrent_requests_cannot_exceed_the_same_pair_quota() {
    let (limits,_) = setup(100);
    let mut tasks = Vec::new();
    let gate = Arc::new(tokio::sync::Barrier::new(40));
    for _ in 0..40 {
        let limits = limits.clone();
        let gate = gate.clone();
        tasks.push(tokio::spawn(async move {gate.wait().await; limits.check_account(ip(1),"alice",Operation::Login)}));
    }
    let mut accepted = 0;
    for task in tasks {
        match task.await.unwrap() {Ok(()) => accepted+=1,Err(error) => assert_eq!(error.code(),Code::ResourceExhausted)}
    }
    assert_eq!(accepted,5);
}

#[tokio::test]
async fn public_grpc_rejects_repeated_attempts_before_database_access() -> Result<(),Box<dyn std::error::Error + Send + Sync>> {
    let (limits,clock) = setup(100);
    let api = AuthApiService::new(Surreal::<Client>::init(),JwtKeys::from_secret("test-only-rate-limit-key-0123456789")?).with_attempts(limits);
    let listener = std::net::TcpListener::bind("127.0.0.1:0")?;
    let address = listener.local_addr()?;
    drop(listener);
    let (shutdown,stopped) = tokio::sync::oneshot::channel();
    let server = tokio::spawn(Server::builder().add_service(AuthApiServer::new(api).max_decoding_message_size(MAX_AUTH_MESSAGE_BYTES))
        .serve_with_shutdown(address,async {let _ = stopped.await;}));
    let result = async {
        let mut tries = 0;
        let mut client = loop {
            match AuthApiClient::connect(format!("http://{address}")).await {
                Ok(client) => break client,
                Err(error) if tries >= 100 => return Err(error.into()),
                Err(_) => {tries+=1;tokio::time::sleep(Duration::from_millis(10)).await;}
            }
        };
        // Поля отклоняются до обращения к неинициализированной БД
        for request in [LoginRequest {login:"a".repeat(65),password:"Password1!".into()},
            LoginRequest {login:"alice".into(),password:"a".repeat(1025)}] {
            assert_eq!(client.login(request).await.unwrap_err().code(),Code::InvalidArgument);
        }
        for attempt in 0..5 {
            if attempt == 3 { client = AuthApiClient::connect(format!("http://{address}")).await?; }
            let mut request = Request::new(LoginRequest {login:"alice".into(),password:"Password1!".into()});
            request.metadata_mut().insert("x-forwarded-for",format!("10.0.0.{}",attempt+1).parse()?);
            assert_eq!(client.login(request).await.unwrap_err().code(),Code::Internal);
        }
        assert_eq!(retry(client.login(LoginRequest {login:"alice".into(),password:"Password1!".into()}).await.unwrap_err()),30);
        advance(&clock,31);
        // После паузы запрос снова доходит до БД; постоянной блокировки нет
        assert_eq!(client.login(LoginRequest {login:"alice".into(),password:"Password1!".into()}).await.unwrap_err().code(),Code::Internal);
        advance(&clock,60);
        for _ in 0..5 {
            let response = client.register(RegisterRequest {login:"alice".into(),email:"invalid".into(),password:"Password1!".into()}).await?.into_inner();
            assert!(!response.success);
        }
        assert_eq!(retry(client.register(RegisterRequest {login:"alice".into(),email:"invalid".into(),password:"Password1!".into()}).await.unwrap_err()),60);
        assert_eq!(client.register(RegisterRequest {login:"alice".into(),email:"a@example.test".into(),password:"a".repeat(6000)}).await.unwrap_err().code(),Code::OutOfRange);
        Ok::<(),Box<dyn std::error::Error + Send + Sync>>(())
    }.await;
    let _ = shutdown.send(());
    server.await??;
    result
}
