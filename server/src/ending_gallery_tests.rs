use crate::{jwt::Claims, progress_service::ProgressApiService}; // Подключаю прогресс и владельца запроса
use crate::romance_club::{GetProgressSummaryRequest, ResetProgressRequest, progress_api_server::ProgressApi}; // Подключаю методы коллекции
use surrealdb::{engine::remote::ws::Ws, opt::auth::Root}; // Подключаю отдельную БД для теста
use tonic::{Request, Code}; // Подключаю проверку доступа

fn own<T>(body: T) -> Request<T> {
    let mut request = Request::new(body);
    request.extensions_mut().insert(Claims {sub:"player:gallery".into(),login:"gallery".into(),is_admin:false,exp:usize::MAX});
    request
}

#[tokio::test]
async fn rejects_other_players_collection() {
    let api = ProgressApiService::new(surrealdb::Surreal::init());
    let error = api.get_progress_summary(own(GetProgressSummaryRequest {novel_id:String::new(),player_id:"player:other".into()})).await.unwrap_err();
    assert_eq!(error.code(),Code::PermissionDenied);
}

#[tokio::test]
#[ignore = "Проверяю историю в отдельной случайной БД"]
async fn gallery_preserves_history_and_filters_owner_and_final_episode() -> Result<(),Box<dyn std::error::Error + Send + Sync>> {
    let db = surrealdb::Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
    let name = format!("gallery_{}",uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club_test").use_db(&name).await?;
    let result = async {
        crate::apply_migrations(&db).await.map_err(|e| e.to_string())?;
        let api = ProgressApiService::new(db.clone());
        let request = || own(GetProgressSummaryRequest {novel_id:String::new(),player_id:"player:gallery".into()});
        let empty = api.get_progress_summary(request()).await?.into_inner();
        assert!(empty.endings_available);
        assert!(empty.seen_endings.is_empty());
        db.query("CREATE episode_completion:mine CONTENT {player_id:player:gallery,episode_id:episode:5,endings:['Лука','Лука','Выбираю себя','Неизвестный']}; CREATE episode_completion:early CONTENT {player_id:player:gallery,episode_id:episode:1,endings:['МариКот']}; CREATE episode_completion:other CONTENT {player_id:player:other,episode_id:episode:5,endings:['СуперБаг']};").await?.check()?;
        let seen = api.get_progress_summary(request()).await?.into_inner().seen_endings;
        assert_eq!(seen.len(),2);
        assert!(seen.contains(&"Лука".to_string()));
        assert!(seen.contains(&"Выбираю себя".to_string()));
        // Два настоящих завершения сохраняются в коллекции, хотя текущий прогресс один.
        db.query("CREATE episode:5 CONTENT {title:'Финал',version:1}; CREATE scene:gallery CONTENT {episode_id:episode:5,title:'Последняя сцена',background:'',character:'',character_emotion:'',texts:['Финал'],condition:'',text_position:'bottom_center',character_position:'center',order_index:0};").await?.check()?;
        for ending in ["МариАдриан", "МариКот"] {
            let current = api.get_progress(own(crate::romance_club::GetProgressRequest {player_id:"player:gallery".into(),episode_id:5})).await?.into_inner();
            api.save_progress(own(crate::romance_club::SaveProgressRequest {
                player_id:"player:gallery".into(),episode_id:5,scene_id:"scene:gallery".into(),completed:true,ending:ending.into(),
                expected_revision:current.revision,expected_generation:current.generation,..Default::default()
            })).await?;
        }
        let seen = api.get_progress_summary(request()).await?.into_inner().seen_endings;
        assert_eq!(seen.len(),4);
        assert!(seen.contains(&"МариАдриан".to_string()));
        assert!(seen.contains(&"МариКот".to_string()));
        api.reset_progress(own(ResetProgressRequest {player_id:"player:gallery".into()})).await?;
        assert_eq!(api.get_progress_summary(request()).await?.into_inner().seen_endings,seen);
        Ok::<(),Box<dyn std::error::Error + Send + Sync>>(())
    }.await;
    db.query(format!("REMOVE DATABASE {name}")).await?.check()?;
    result
}