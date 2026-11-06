use super::*; // Подключаю проверку ID и удаление
use crate::{asset_service::AssetApiService, admin_service::AdminApiService, jwt::Claims, romance_club::*}; // Подключаю сервисы и запросы
use crate::romance_club::{asset_api_server::AssetApi, admin_api_server::AdminApi}; // Подключаю оба API
use surrealdb::{engine::remote::ws::Ws, opt::auth::Root}; // Подключаю отдельную тестовую базу
use tonic::{Request, Code}; // Подключаю запросы и коды ошибок

type TestResult = Result<(), Box<dyn std::error::Error + Send + Sync>>;
fn admin<T>(body: T) -> Request<T> {
    let mut request = Request::new(body);
    request.extensions_mut().insert(Claims {sub:"player:test".into(),login:"test".into(),is_admin:true,exp:usize::MAX});
    request
}

#[tokio::test]
async fn reject_foreign_ids_before_database_access() {
    let db = Surreal::<Client>::init();
    let assets = AssetApiService::new(db.clone());
    let admins = AdminApiService::new(db);
    for id in ["", "asset:", "asset", "player:test", "episode:1", "progress:test", "asset:one; DELETE player", "asset:1..9", "asset:[]", "asset:*", " asset:test", "asset:test "] {
        assert_eq!(assets.delete_asset(admin(DeleteAssetRequest {id:id.into()})).await.unwrap_err().code(),Code::InvalidArgument,"{id}");
        assert_eq!(admins.delete_asset(admin(AdminDeleteAssetRequest {asset_id:id.into()})).await.unwrap_err().code(),Code::InvalidArgument,"{id}");
    }
    assert_eq!(asset_id("asset:123").unwrap().key,RecordIdKey::Number(123));
    assert_eq!(asset_id("asset:test").unwrap().key,RecordIdKey::String("test".into()));
    assert_eq!(asset_id("asset:`player:test`").unwrap().key,RecordIdKey::String("player:test".into()));
}

async fn snapshot(db: &Surreal<Client>) -> Result<serde_json::Value, surrealdb::Error> {
    let value: Option<serde_json::Value> = db.query("RETURN {players:(SELECT * FROM player ORDER BY id),episodes:(SELECT * FROM episode ORDER BY id),progress:(SELECT * FROM progress ORDER BY id)};").await?.take(0)?;
    Ok(value.unwrap())
}

// Проверяю весь RPC, включая токен, тип параметра SQL и ответ сервера
async fn grpc_scenarios(db: Surreal<Client>, limited: Surreal<Client>) -> TestResult {
    use crate::romance_club::{admin_api_client::AdminApiClient, admin_api_server::AdminApiServer}; // Подключаю клиент и сервер
    use tonic::transport::Server; // Подключаю настоящий gRPC-сервер
    let keys = crate::jwt::JwtKeys::from_secret("test-only-asset-delete-key-0123456789")?;
    let admin_token = keys.create_token("player:test", "test", true)?;
    let player_token = keys.create_token("player:test", "test", false)?;
    let listener = std::net::TcpListener::bind("127.0.0.1:0")?;
    let address = listener.local_addr()?;
    drop(listener);
    let (shutdown, stopped) = tokio::sync::oneshot::channel();
    let service = AdminApiService::new(db.clone()).with_delete_db(limited);
    let server = tokio::spawn(Server::builder().add_service(AdminApiServer::with_interceptor(
        service, crate::AuthInterceptor {jwt:keys}))
        .serve_with_shutdown(address, async {let _ = stopped.await;}));
    let result = async {
        db.query("CREATE asset:review; CREATE asset:44;").await?.check()?;
        let mut attempts = 0;
        let mut client = loop {
            match AdminApiClient::connect(format!("http://{address}")).await {
                Ok(client) => break client,
                Err(error) if attempts >= 100 => return Err(error.into()),
                Err(_) => { attempts += 1; tokio::time::sleep(std::time::Duration::from_millis(10)).await; }
            }
        };
        assert_eq!(client.delete_asset(AdminDeleteAssetRequest {asset_id:"asset:review".into()}).await.unwrap_err().code(),Code::Unauthenticated);
        let request = |id: &str, token: &str| {
            let mut request = Request::new(AdminDeleteAssetRequest {asset_id:id.into()});
            request.metadata_mut().insert("authorization",format!("Bearer {token}").parse().unwrap());
            request
        };
        assert_eq!(client.delete_asset(request("asset:review",&player_token)).await.unwrap_err().code(),Code::PermissionDenied);
        assert_eq!(client.delete_asset(request("player:test",&admin_token)).await.unwrap_err().code(),Code::InvalidArgument);
        for id in ["asset:review","asset:44"] {
            assert!(client.delete_asset(request(id,&admin_token)).await?.into_inner().success);
            assert_eq!(client.delete_asset(request(id,&admin_token)).await.unwrap_err().code(),Code::NotFound);
        }
        // Повторное чтение каталога не возвращает удалённые записи
        let ids: Vec<RecordId> = db.query("SELECT VALUE id FROM asset;").await?.check()?.take(0)?;
        assert_eq!(ids,vec![RecordId::new("asset","other")]);
        db.query("DEFINE EVENT rpc_refuse_delete ON asset WHEN $event='DELETE' THEN { THROW 'delete_refused'; };").await?.check()?;
        assert_eq!(client.delete_asset(request("asset:other",&admin_token)).await.unwrap_err().code(),Code::Internal);
        let ids: Vec<RecordId> = db.query("SELECT VALUE id FROM asset;").await?.check()?.take(0)?;
        assert_eq!(ids,vec![RecordId::new("asset","other")]);
        db.query("REMOVE EVENT rpc_refuse_delete ON asset;").await?.check()?;
        Ok::<(),Box<dyn std::error::Error + Send + Sync>>(())
    }.await;
    let _ = shutdown.send(());
    server.await??;
    result
}

async fn scenarios(db: Surreal<Client>, database: String) -> TestResult {
    db.query("CREATE player:test SET marker='keep'; CREATE episode:1 SET marker='keep'; CREATE progress:test SET marker='keep'; CREATE asset:one; CREATE asset:123; CREATE asset:`player:test`; CREATE asset:other;").await?.check()?;
    let before = snapshot(&db).await?;
    db.query(include_str!("../migrations/022_asset_delete_access.surql")).await?.check()?;
    let limited = connection(&db,"romance_club",&database).await?;
    // Даже прямой запрос ограниченного подключения не трогает чужие таблицы
    let _ = limited.query("DELETE player; DELETE episode; DELETE progress; DELETE asset_delete_identity; UPDATE player SET marker='changed'; CREATE player:intruder;").await?;
    assert_eq!(snapshot(&db).await?,before);
    let assets = AssetApiService::new(db.clone()).with_delete_db(limited.clone());
    let admins = AdminApiService::new(db.clone()).with_delete_db(limited.clone());
    for id in ["player:test","episode:1","progress:test"] {
        assert_eq!(assets.delete_asset(admin(DeleteAssetRequest {id:id.into()})).await.unwrap_err().code(),Code::InvalidArgument);
        assert_eq!(admins.delete_asset(admin(AdminDeleteAssetRequest {asset_id:id.into()})).await.unwrap_err().code(),Code::InvalidArgument);
    }
    assert!(assets.delete_asset(admin(DeleteAssetRequest {id:"asset:one".into()})).await?.into_inner().success);
    assert!(admins.delete_asset(admin(AdminDeleteAssetRequest {asset_id:"asset:123".into()})).await?.into_inner().success);
    assert!(assets.delete_asset(admin(DeleteAssetRequest {id:"asset:`player:test`".into()})).await?.into_inner().success);
    assert_eq!(assets.delete_asset(admin(DeleteAssetRequest {id:"asset:one".into()})).await.unwrap_err().code(),Code::NotFound);
    assert_eq!(admins.delete_asset(admin(AdminDeleteAssetRequest {asset_id:"asset:missing".into()})).await.unwrap_err().code(),Code::NotFound);
    assert_eq!(snapshot(&db).await?,before);
    let mut result = db.query("SELECT VALUE id FROM asset;").await?.check()?;
    let remaining: Vec<RecordId> = result.take(0)?;
    assert_eq!(remaining,vec![RecordId::new("asset","other")]);
    grpc_scenarios(db.clone(),limited).await?;
    // Ошибку SQL возвращаю как ошибку, оставляя запись на месте
    db.query("DEFINE EVENT refuse_delete ON asset WHEN $event='DELETE' THEN { THROW 'delete_refused'; };").await?.check()?;
    assert_eq!(admins.delete_asset(admin(AdminDeleteAssetRequest {asset_id:"asset:other".into()})).await.unwrap_err().code(),Code::Internal);
    Ok(())
}

#[tokio::test]
#[ignore = "Нужна SurrealDB; удаление проверяю только в отдельной БД"]
async fn asset_deletion_cannot_touch_other_tables() -> TestResult {
    let db = Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
    let name = format!("asset_delete_test_{}",uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club").await?;
    db.query(format!("DEFINE DATABASE {name};")).await?.check()?;
    db.use_db(&name).await?;
    let result = tokio::spawn(scenarios(db.clone(),name.clone())).await;
    db.query(format!("REMOVE DATABASE {name};")).await?.check()?;
    result?
}
