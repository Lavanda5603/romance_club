use super::*; // Подключаю сервис авторизации
use surrealdb::{engine::remote::ws::Ws, opt::auth::Root}; // Подключаю тестовую базу
use tonic::Code; // Подключаю коды ошибок gRPC

type TestResult = Result<(), Box<dyn std::error::Error + Send + Sync>>;

fn keys() -> JwtKeys {
    JwtKeys::from_secret("test-only-login-index-key-0123456789").unwrap()
}

// Разные клиенты проверяют гонку уникального индекса, а не квоту одного IP
fn client<T>(body: T, index: usize) -> Request<T> {
    let mut request = Request::new(body);
    request.extensions_mut().insert(tonic::transport::server::TcpConnectInfo {
        local_addr:None, remote_addr:Some(format!("127.0.0.{}:12345",index+1).parse().unwrap()),
    });
    request
}

async fn rows(db: &Surreal<Client>, login: &str) -> Result<Vec<Value>, surrealdb::Error> {
    db.query("SELECT id, login, email, password_hash FROM player WHERE login=$login;")
        .bind(("login", login.to_owned())).await?.take(0)
}

async fn scenarios(db: Surreal<Client>) -> TestResult {
    db.query(include_str!("../migrations/005_player.surql")).await?.check()?;
    db.query(include_str!("../migrations/012_player_admin.surql")).await?.check()?;
    let hash = AuthApiService::hash_password("Legacy1!").await?;
    db.query("CREATE player:old_a CONTENT {login:'old_login',email:'a@example.test',password_hash:$hash}; CREATE player:old_b CONTENT {login:'old_login',email:'b@example.test',password_hash:$hash};")
        .bind(("hash", hash)).await?.check()?;
    // Дубликаты останавливают миграцию, оба старых аккаунта остаются целыми
    let before = rows(&db, "old_login").await?;
    let mut failed = db.query(include_str!("../migrations/021_player_login_unique.surql")).await?;
    let errors = failed.take_errors().values().map(ToString::to_string).collect::<Vec<_>>().join("; ");
    assert!(errors.contains("PLAYER_LOGIN_DUPLICATES"), "{errors}");
    assert_eq!(rows(&db, "old_login").await?, before);
    // Имитирую явно выполненное владельцем исправление одного логина
    db.query("UPDATE player:old_b SET login='renamed_login';").await?.check()?;
    for _ in 0..2 {
        db.query(include_str!("../migrations/021_player_login_unique.surql")).await?.check()?;
    }
    let api = AuthApiService::new(db.clone(), keys());
    let old = api.login(Request::new(LoginRequest {login:"old_login".into(),password:"Legacy1!".into()})).await?.into_inner();
    assert!(old.success);
    assert_eq!(old.player.unwrap().id, "player:old_a");
    // Индекс защищает и прямые SQL-запросы, а не только регистрацию
    assert!(db.query("CREATE player CONTENT {login:'old_login',email:'x@example.test',password_hash:'hash'};").await?.check().is_err());
    assert!(db.query("UPDATE player:old_b SET login='old_login';").await?.check().is_err());
    assert_eq!(rows(&db,"old_login").await?.len(), 1);
    assert_eq!(rows(&db,"renamed_login").await?.len(), 1);

    // Отправляю регистрации одновременно из разных экземпляров сервиса
    let mut tasks = Vec::new();
    let gate = std::sync::Arc::new(tokio::sync::Barrier::new(8));
    for index in 0..8 {
        let db = db.clone();
        let gate = gate.clone();
        tasks.push(tokio::spawn(async move {
            let api = AuthApiService::new(db, keys());
            gate.wait().await;
            api.register(client(RegisterRequest {login:"same_login".into(),
                email:format!("user{index}@example.test"),password:format!("Password{index}!")},index)).await
        }));
    }
    let mut winner = None;
    for (index, task) in tasks.into_iter().enumerate() {
        let result = task.await??.into_inner();
        if result.success {
            assert!(winner.replace(index).is_none());
            assert!(!result.token.is_empty());
            assert!(!result.is_admin);
        } else {
            assert_eq!(result.message,"Игрок с таким логином уже существует");
            assert!(result.player.is_none() && result.token.is_empty());
        }
    }
    let winner = winner.expect("Одна регистрация должна пройти");
    assert_eq!(rows(&db,"same_login").await?.len(), 1);
    for index in 0..8 {
        let result = api.login(client(LoginRequest {login:"same_login".into(),password:format!("Password{index}!")},index)).await?.into_inner();
        assert_eq!(result.success,index == winner);
    }
    // Даже обход предварительного SELECT заканчивается понятным конфликтом
    assert!(api.create_player("same_login","other@example.test","hash").await?.is_none());
    for login in ["CaseUser", "caseuser"] {
        assert!(api.register(Request::new(RegisterRequest {login:login.into(),email:"case@example.test".into(),password:"Password1!".into()})).await?.into_inner().success);
    }
    // Ошибку другого поля не выдаю за занятый логин
    db.query("DEFINE FIELD OVERWRITE email ON player TYPE string ASSERT $value != 'reject@example.test';").await?.check()?;
    assert_eq!(api.create_player("new_login","reject@example.test","hash").await.unwrap_err().code(),Code::Internal);
    assert!(rows(&db,"new_login").await?.is_empty());
    Ok(())
}

#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
#[ignore = "Нужна SurrealDB; регистрацию проверяю в отдельной БД"]
async fn unique_login_survives_parallel_registration() -> TestResult {
    let db = Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
    let name = format!("auth_test_{}", uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club").await?;
    db.query(format!("DEFINE DATABASE {name};")).await?.check()?;
    db.use_db(&name).await?;
    let result = tokio::spawn(scenarios(db.clone())).await;
    db.query(format!("REMOVE DATABASE {name};")).await?.check()?;
    result?
}