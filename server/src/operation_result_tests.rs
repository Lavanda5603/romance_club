use crate::{achievement_service::AchievementApiService, admin_service::AdminApiService, progress_service::ProgressApiService, shop_service::ShopApiService, jwt::Claims, romance_club::*};
use crate::romance_club::{achievement_api_server::AchievementApi, admin_api_server::AdminApi, progress_api_server::ProgressApi, shop_api_server::ShopApi, episode_api_server::EpisodeApi};
use surrealdb::{Surreal, engine::remote::ws::{Client, Ws}, opt::auth::Root};
use tonic::{Request, Code};
use serde_json::Value;
type TestResult = Result<(), Box<dyn std::error::Error + Send + Sync>>;
fn own<T>(body: T) -> Request<T> {
    let mut req = Request::new(body);
    req.extensions_mut().insert(Claims { sub:"player:test".into(), login:"test".into(), is_admin:true, exp:usize::MAX });
    req
}

#[tokio::test]
async fn unavailable_database_never_returns_success() {
    let db = Surreal::<Client>::init();
    let achievements = AchievementApiService::new(db.clone());
    let progress = ProgressApiService::new(db);
    assert_eq!(achievements.unlock_achievement(own(UnlockAchievementRequest { player_id:"player:test".into(), name:"test".into() })).await.unwrap_err().code(), Code::Internal);
    assert_eq!(progress.reset_progress(own(ResetProgressRequest { player_id:"player:test".into() })).await.unwrap_err().code(), Code::Internal);
    assert_eq!(progress.save_progress(own(SaveProgressRequest { player_id:"player:test".into(), episode_id:1, scene_id:"scene:test".into(), ..Default::default() })).await.unwrap_err().code(), Code::Internal);
}

async fn scenarios(db: Surreal<Client>) -> TestResult {
    crate::apply_migrations(&db).await.map_err(|e|e.to_string())?;
    let achievements = AchievementApiService::new(db.clone());
    let unlock = || own(UnlockAchievementRequest { player_id:"player:test".into(), name:"test".into() });
    db.query("DEFINE FIELD OVERWRITE name ON achievement TYPE string ASSERT $value != 'test';").await?.check()?;
    assert_eq!(achievements.unlock_achievement(unlock()).await.unwrap_err().code(), Code::Internal);
    let mut result = db.query("SELECT * FROM achievement;").await?.check()?;
    let rows: Vec<Value> = result.take(0)?;
    assert!(rows.is_empty());
    db.query("DEFINE FIELD OVERWRITE name ON achievement TYPE string;").await?.check()?;
    assert!(achievements.unlock_achievement(unlock()).await?.into_inner().success);
    assert!(achievements.unlock_achievement(unlock()).await?.into_inner().success);
    let mut result = db.query("SELECT * FROM achievement;").await?.check()?;
    let rows: Vec<Value> = result.take(0)?;
    assert_eq!(rows.len(), 1);

    let shop = ShopApiService::new(db.clone());
    db.query("DEFINE FIELD OVERWRITE diamonds ON player_currency TYPE int ASSERT $value < 50;").await?.check()?;
    assert_eq!(shop.purchase(own(PurchaseRequest { player_id:"player:test".into(), item_id:"diamonds_100".into(), item_type:"currency".into(), request_id:"test-topup".into() })).await.unwrap_err().code(), Code::Internal);
    let mut result = db.query("SELECT * FROM purchase; SELECT * FROM player_currency;").await?.check()?;
    let purchases: Vec<Value> = result.take(0)?;
    let balances: Vec<Value> = result.take(1)?;
    assert!(purchases.is_empty() && balances.is_empty());

    db.query("CREATE asset:test CONTENT {type:'background',name:'x',url:'x',display_name:'x'}; DEFINE EVENT refuse_delete ON asset WHEN $event = 'DELETE' THEN { THROW 'delete_refused'; };").await?.check()?;
    let admin = AdminApiService::new(db.clone());
    assert_eq!(admin.delete_asset(own(AdminDeleteAssetRequest { asset_id:"asset:test".into() })).await.unwrap_err().code(), Code::Internal);
    db.query("REMOVE EVENT refuse_delete ON asset;").await?.check()?;
    assert!(admin.delete_asset(own(AdminDeleteAssetRequest { asset_id:"asset:test".into() })).await?.into_inner().success);
    let episodes = crate::EpisodeApiService::new(db.clone());
    for id in [1, 2] {
        episodes.save_episode(own(SaveEpisodeRequest { episode: Some(Episode {
            id, title:"Удаление".into(), version:1, scenes:vec![Scene {
                scene_key:format!("draft:{id}"), choices:vec![Choice { text:"Выбор".into(),
                    actions:vec![Action { r#type:"setFlag".into(), flag_name:"test".into(), flag_value:true, ..Default::default() }], ..Default::default() }], ..Default::default()
            }],
        }) })).await?;
    }
    db.query("DEFINE EVENT refuse_delete ON choice WHEN $event = 'DELETE' THEN { THROW 'delete_refused'; };").await?.check()?;
    assert_eq!(admin.delete_episode(own(AdminDeleteEpisodeRequest { episode_id:1 })).await.unwrap_err().code(), Code::Internal);
    assert_eq!(episodes.delete_episode(own(DeleteEpisodeRequest { id:2 })).await.unwrap_err().code(), Code::Internal);
    db.query("REMOVE EVENT refuse_delete ON choice;").await?.check()?;
    assert!(admin.delete_episode(own(AdminDeleteEpisodeRequest { episode_id:1 })).await?.into_inner().success);
    assert!(episodes.delete_episode(own(DeleteEpisodeRequest { id:2 })).await?.into_inner().success);
    let mut result = db.query("SELECT * FROM episode; SELECT * FROM scene; SELECT * FROM choice; SELECT * FROM action;").await?.check()?;
    for index in 0..4 {
        let rows: Vec<Value> = result.take(index)?;
        assert!(rows.is_empty());
    }
    Ok(())
}

#[tokio::test]
#[ignore = "Нужна SurrealDB; ошибки SQL проверяю в отдельной БД"]
async fn sql_errors_never_return_success() -> TestResult {
    let db = Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
    let name = format!("results_test_{}", uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club").await?;
    db.query(format!("DEFINE DATABASE {name};")).await?.check()?;
    db.use_db(&name).await?;
    let result = tokio::spawn(scenarios(db.clone())).await;
    db.query(format!("REMOVE DATABASE {name};")).await?.check()?;
    result?
}