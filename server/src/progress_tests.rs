use super::*;
use crate::jwt::Claims;
use surrealdb::{engine::remote::ws::Ws, opt::auth::Root};
use tonic::Code;

fn request<T>(body: T) -> Request<T> {
    let mut request = Request::new(body);
    request.extensions_mut().insert(Claims {
        sub: "player:test".into(), login: "test".into(), is_admin: false, exp: usize::MAX,
    });
    request
}

fn save(revision: i32, points: i32) -> Request<SaveProgressRequest> {
    request(SaveProgressRequest {
        player_id: "player:test".into(), episode_id: 1, scene_id: "scene:test".into(),
        expected_revision: revision,
        flags: [("chosen".into(), true)].into(),
        counters: [("points".into(), points)].into(),
    })
}

async fn read(api: &ProgressApiService) -> Result<Progress, Status> {
    api.get_progress(request(GetProgressRequest { player_id: "player:test".into(), episode_id: 1 }))
        .await.map(Response::into_inner)
}

async fn scenarios(db: Surreal<Client>) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    db.query(include_str!("../migrations/006_progress.surql")).await?.check()?;
    // Дубли специально создаю до миграции и проверяю сохранность обеих версий
    db.query("CREATE progress:old CONTENT {player_id:player:test,episode_id:episode:1,scene_id:scene:test,flags:{},counters:{points:1},updated_at:d'2026-01-01T00:00:00Z'}; CREATE progress:new CONTENT {player_id:player:test,episode_id:episode:1,scene_id:scene:test,flags:{chosen:true},counters:{points:2},updated_at:d'2026-01-02T00:00:00Z'};").await?.check()?;
    db.query(include_str!("../migrations/014_progress_atomic.surql")).await?.check()?;
    db.query(include_str!("../migrations/014_progress_atomic.surql")).await?.check()?;
    let mut counts = db.query("SELECT * FROM progress; SELECT * FROM progress_archive;").await?.check()?;
    let rows: Vec<Value> = counts.take(0)?;
    let archive: Vec<Value> = counts.take(1)?;
    assert_eq!(rows.len(), 1);
    assert_eq!(archive.len(), 2);
    assert_eq!(rows[0]["counters"]["points"], 2);
    assert!(db.query("CREATE progress:duplicate CONTENT {player_id:player:test,episode_id:episode:1,scene_id:scene:test,flags:{},counters:{}};").await?.check().is_err());
    db.query("CREATE scene:test CONTENT {episode_id:episode:1};").await?.check()?;
    let api = std::sync::Arc::new(ProgressApiService::new(db.clone()));
    assert_eq!(read(&api).await?.counters["points"], 2);

    // Несколько клиентов одновременно меняют одну загруженную версию
    let mut tasks = Vec::new();
    for points in 10..30 {
        let api = api.clone();
        tasks.push(tokio::spawn(async move { api.save_progress(save(0, points)).await }));
    }
    let mut successful = 0;
    for task in tasks {
        match task.await? {
            Ok(response) => { successful += 1; assert_eq!(response.into_inner().revision, 1); }
            Err(error) => assert_eq!(error.code(), Code::Aborted, "{error}"),
        }
    }
    assert_eq!(successful, 1);
    let previous = read(&api).await?;
    assert_eq!(previous.revision, 1);
    assert!(previous.flags["chosen"]);
    assert_eq!(api.save_progress(save(0, 999)).await.unwrap_err().code(), Code::Aborted);

    // Ошибка внутри SQL не стирает последний успешный снимок
    db.query("DEFINE FIELD OVERWRITE counters ON progress TYPE object FLEXIBLE ASSERT $value.points < 100;").await?.check()?;
    assert_eq!(api.save_progress(save(1, 999)).await.unwrap_err().code(), Code::Internal);
    let unchanged = read(&api).await?;
    assert_eq!(unchanged.revision, previous.revision);
    assert_eq!(unchanged.counters, previous.counters);
    assert!(api.save_progress(save(1, 50)).await?.into_inner().success);
    let mut foreign_scene = save(2, 60);
    foreign_scene.get_mut().scene_id = "scene:missing".into();
    assert_eq!(api.save_progress(foreign_scene).await.unwrap_err().code(), Code::InvalidArgument);
    assert_eq!(read(&api).await?.counters["points"], 50);
    api.reset_progress(request(ResetProgressRequest { player_id: "player:test".into() })).await?;
    let reset = read(&api).await?;
    assert!(reset.scene_id.is_empty());
    assert_eq!(reset.revision, 3);
    assert_eq!(api.save_progress(save(2, 60)).await.unwrap_err().code(), Code::Aborted);
    assert_eq!(api.save_progress(save(3, 5)).await?.into_inner().revision, 4);

    // Отдельно проверяю гонку при самом первом сохранении
    db.query("DELETE progress;").await?.check()?;
    assert_eq!(api.save_progress(save(4, 7)).await.unwrap_err().code(), Code::Aborted);
    let (a, b) = tokio::join!(api.save_progress(save(0, 7)), api.save_progress(save(0, 8)));
    assert_ne!(a.is_ok(), b.is_ok());
    let mut result = db.query("SELECT * FROM progress;").await?.check()?;
    let rows: Vec<Value> = result.take(0)?;
    assert_eq!(rows.len(), 1);
    assert_eq!(read(&api).await?.revision, 1);
    // Сводка выбирает только свои активные записи существующих эпизодов
    db.query("DEFINE TABLE episode SCHEMALESS; CREATE episode:1; CREATE episode:2; CREATE episode:3; CREATE progress:other CONTENT {player_id:player:other,episode_id:episode:2,scene_id:scene:test,flags:{},counters:{}}; CREATE progress:reset CONTENT {player_id:player:test,episode_id:episode:2,flags:{},counters:{}}; CREATE progress:third CONTENT {player_id:player:test,episode_id:episode:3,scene_id:scene:test,flags:{},counters:{}}; CREATE progress:orphan CONTENT {player_id:player:test,episode_id:episode:99,scene_id:scene:test,flags:{},counters:{}};").await?.check()?;
    let summary = api.get_progress_summary(request(GetProgressSummaryRequest {player_id:"player:test".into()})).await?.into_inner();
    assert_eq!(summary.episode_ids, vec![1, 3]);
    api.reset_progress(request(ResetProgressRequest {player_id:"player:test".into()})).await?;
    assert!(api.get_progress_summary(request(GetProgressSummaryRequest {player_id:"player:test".into()})).await?.into_inner().episode_ids.is_empty());
    Ok(())
}

#[tokio::test]
#[ignore = "Нужна локальная SurrealDB; создаю и удаляю отдельную тестовую БД"]
async fn atomic_progress_with_parallel_clients() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let db = Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {
        username: std::env::var("SURREAL_USER")?, password: std::env::var("SURREAL_PASS")?,
    }).await?;
    let name = format!("progress_test_{}", uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club").await?;
    db.query(format!("DEFINE DATABASE {name};")).await?.check()?;
    db.use_db(&name).await?;
    let result = tokio::spawn(scenarios(db.clone())).await;
    db.query(format!("REMOVE DATABASE {name};")).await?.check()?;
    result?
}
