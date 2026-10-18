use super::*;
use crate::{jwt::Claims, progress_service::ProgressApiService, EpisodeApiService};
use crate::romance_club::{progress_api_server::ProgressApi, episode_api_server::EpisodeApi};
use surrealdb::{engine::remote::ws::Ws, opt::auth::Root};
type TestResult = Result<(), Box<dyn std::error::Error + Send + Sync>>;
fn own<T>(body:T) -> Request<T> {
    let mut req = Request::new(body);
    req.extensions_mut().insert(Claims {sub:"player:test".into(), login:"test".into(), is_admin:true, exp:usize::MAX});
    req
}
async fn names(api:&AchievementApiService) -> Result<Vec<String>, Status> {
    Ok(api.get_achievements(own(GetAchievementsRequest {player_id:"player:test".into()})).await?.into_inner().achievements.into_iter().map(|a|a.name).collect())
}
async fn finish(api:&ProgressApiService, episode_id:i32, scene_id:&str, ending:&str, completed:bool) -> Result<(), Status> {
    let saved = api.get_progress(own(crate::romance_club::GetProgressRequest {player_id:"player:test".into(),episode_id})).await?.into_inner();
    api.save_progress(own(crate::romance_club::SaveProgressRequest {
        player_id:"player:test".into(), episode_id, scene_id:scene_id.into(), ending:ending.into(), completed,
        expected_revision:saved.revision, ..Default::default()
    })).await?;
    Ok(())
}
async fn scenarios(db:Surreal<Client>) -> TestResult {
    use crate::romance_club::*;
    crate::apply_migrations(&db).await.map_err(|e|e.to_string())?;
    let episodes = EpisodeApiService::new(db.clone());
    let progress = ProgressApiService::new(db.clone());
    let achievements = AchievementApiService::new(db.clone());
    let mut keys = Vec::new();
    for id in [1,2] {
        episodes.save_episode(own(SaveEpisodeRequest {episode:Some(Episode {id,title:format!("Эпизод {id}"),version:1,
            scenes:vec![Scene {scene_key:format!("draft:{id}"),texts:vec!["Конец".into()],..Default::default()}]})})).await?;
        keys.push(episodes.get_episode(own(GetEpisodeRequest {id})).await?.into_inner().scenes[0].scene_key.clone());
    }
    db.query("CREATE episode_completion:other CONTENT {player_id:player:other,episode_id:episode:1,endings:['МариАдриан','МариКот','Лука','АдриБаг','СуперБаг']}; CREATE episode_completion:other2 CONTENT {player_id:player:other,episode_id:episode:2,endings:[]};").await?.check()?;
    db.query("CREATE achievement:legacy CONTENT {player_id:player:test,name:'all_endings',unlocked_at:time::now()};").await?.check()?;
    assert!(names(&achievements).await?.is_empty());
    let mut rows = db.query("SELECT * FROM achievement:legacy;").await?.check()?;
    let legacy:Vec<Value> = rows.take(0)?;
    assert_eq!(legacy.len(),1,"Старое достижение сохраняю в БД");
    for name in ["all_episodes","all_endings"] {
        assert_eq!(achievements.unlock_achievement(own(UnlockAchievementRequest {player_id:"player:test".into(),name:name.into()})).await.unwrap_err().code(), tonic::Code::FailedPrecondition);
    }
    finish(&progress,1,&keys[0],"МариАдриан",false).await?;
    assert!(names(&achievements).await?.is_empty());
    finish(&progress,1,&keys[0],"МариАдриан",true).await?;
    assert!(names(&achievements).await?.is_empty());
    finish(&progress,1,&keys[0],"",false).await?;
    finish(&progress,2,&keys[1],"МариКот",true).await?;
    let unlocked = names(&achievements).await?;
    assert!(unlocked.contains(&"all_episodes".into()));
    assert!(!unlocked.contains(&"all_endings".into()));
    for ending in ["МариКот","МариКот","Лука","АдриБаг"] {
        finish(&progress,2,&keys[1],ending,true).await?;
        assert!(!names(&achievements).await?.contains(&"all_endings".into()));
    }
    finish(&progress,2,&keys[1],"СуперБаг",true).await?;
    assert!(names(&achievements).await?.contains(&"all_endings".into()));
    db.query("CREATE choice:custom CONTENT {scene_id:type::record($scene),text:'Секрет',title:'Секрет',order_index:0}; CREATE action:custom CONTENT {choice_id:choice:custom,type:'ending',title:'Секрет'};").bind(("scene", keys[0].clone())).await?.check()?;
    assert!(!names(&achievements).await?.contains(&"all_endings".into()));
    finish(&progress,2,&keys[1],"Секрет",true).await?;
    assert!(names(&achievements).await?.contains(&"all_endings".into()));
    db.query(include_str!("../migrations/017_episode_completion.surql")).await?.check()?;
    let mut rows = db.query("SELECT * FROM episode_completion WHERE player_id=player:test;").await?.check()?;
    let history:Vec<Value> = rows.take(0)?;
    assert_eq!(history.len(),2);
    let seen = history.iter().flat_map(|row|row["endings"].as_array().unwrap()).collect::<Vec<_>>();
    assert_eq!(seen.len(),6,"Повторы концовки не добавляют новые записи");
    // Отказ записи истории откатывает и прогресс, и выдачу достижения
    db.query("DEFINE FIELD OVERWRITE endings ON episode_completion TYPE array<string> ASSERT !('failure' IN $value);").await?.check()?;
    assert_eq!(finish(&progress,2,&keys[1],"failure",true).await.unwrap_err().code(), tonic::Code::Internal);
    let saved = progress.get_progress(own(GetProgressRequest {player_id:"player:test".into(),episode_id:2})).await?.into_inner();
    assert_eq!(saved.ending,"Секрет");
    progress.reset_progress(own(ResetProgressRequest {player_id:"player:test".into()})).await?;
    assert!(names(&achievements).await?.contains(&"all_endings".into()));
    Ok(())
}
#[tokio::test]
#[ignore = "Нужна SurrealDB; проверяю историю в отдельной БД"]
async fn achievements_require_all_completions_and_endings() -> TestResult {
    let db = Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
    let name=format!("achievement_test_{}",uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club").await?;
    db.query(format!("DEFINE DATABASE {name};")).await?.check()?;
    db.use_db(&name).await?;
    let result=tokio::spawn(scenarios(db.clone())).await;
    db.query(format!("REMOVE DATABASE {name};")).await?.check()?;
    result?
}
