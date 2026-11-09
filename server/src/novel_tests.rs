use crate::romance_club::{*,novel_api_server::NovelApi,episode_api_server::EpisodeApi}; // Подключаю каталог
use crate::novel_service::NovelApiService; // Подключаю сервис
use surrealdb::{engine::remote::ws::Ws,opt::auth::Root}; // Подключаю тестовую БД
use tonic::Request; // Подключаю запрос админа
fn admin<T>(body:T)->Request<T> {
    let mut request=Request::new(body);
    request.extensions_mut().insert(crate::jwt::Claims {sub:"player:novel_editor".into(),login:"novel_editor".into(),is_admin:true,exp:usize::MAX});request
}
#[tokio::test]
#[ignore="Проверяю две новеллы только в отдельной БД"]
async fn isolate_novels()->Result<(),Box<dyn std::error::Error+Send+Sync>> {
    let db=surrealdb::Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
    let name=format!("novels_{}",uuid::Uuid::new_v4().simple());db.use_ns("romance_club_test").use_db(&name).await?;
    let result=async {
        // Старый эпизод существует до добавления поля новеллы.
        db.query(include_str!("../migrations/001_episode.surql")).await?.check()?;
        db.query("CREATE episode:5 CONTENT {title:'Старая история',version:1};").await?.check()?;
        crate::apply_migrations(&db).await.map_err(|e|e.to_string())?;
        crate::apply_migrations(&db).await.map_err(|e|e.to_string())?;
        crate::request_auth::seed_test_admin(&db,"player:novel_editor").await?;
        let api=NovelApiService::new(db.clone());let episodes=crate::EpisodeApiService::new(db.clone());
        let list=api.list_novels(Request::new(ListNovelsRequest {})).await?.into_inner();
        assert_eq!(list.novels.len(),1);assert_eq!(list.novels[0].id,"novel:ladybug");
        let config=serde_json::json!({"relationships":[],"endings":[],"hidden":[],"final_episode_id":0,"legacy_rules":false}).to_string();
        let second=api.save_novel(admin(Novel {title:"Вторая история".into(),config_json:config,..Default::default()})).await?.into_inner();
        let a=api.create_novel_episode(admin(CreateNovelEpisodeRequest {novel_id:second.id.clone(),title:"Глава 1".into()}));
        let b=api.create_novel_episode(admin(CreateNovelEpisodeRequest {novel_id:second.id.clone(),title:"Глава 2".into()}));
        let (a,b)=tokio::join!(a,b);let a=a?.into_inner();let b=b?.into_inner();assert_ne!(a.id,b.id);assert!(a.id>5&&b.id>5);
        let old=episodes.get_all_episodes(Request::new(GetAllEpisodesRequest {novel_id:"novel:ladybug".into()})).await?.into_inner();assert_eq!(old.episodes.len(),1);
        let own=episodes.get_all_episodes(Request::new(GetAllEpisodesRequest {novel_id:second.id.clone()})).await?.into_inner();assert_eq!(own.episodes.len(),2);
        let mut changed=second.clone();changed.title="Новое название".into();assert_eq!(api.save_novel(admin(changed)).await?.into_inner().revision,2);
        assert_eq!(api.save_novel(admin(second.clone())).await.unwrap_err().code(),tonic::Code::Aborted);
        let bytes=include_bytes!("../../assets/audio/button_click.mp3").to_vec();
        let audio=api.upload_audio(admin(UploadNovelAudioRequest {novel_id:second.id.clone(),kind:"click".into(),data:bytes.clone()})).await?.into_inner();
        let loaded=api.get_audio(Request::new(NovelAudioRequest {novel_id:second.id,id:audio.id.clone()})).await?.into_inner();assert_eq!(loaded.data,bytes);
        assert_eq!(api.get_audio(Request::new(NovelAudioRequest {novel_id:"novel:ladybug".into(),id:audio.id})).await.unwrap_err().code(),tonic::Code::NotFound);
        Ok::<(),Box<dyn std::error::Error+Send+Sync>>(())
    }.await;
    db.query(format!("REMOVE DATABASE {name}")).await?.check()?;result
}