use crate::{EpisodeApiService, admin_service::AdminApiService, jwt::Claims}; // Подключаю проверяемые сервисы и права
use crate::romance_club::{DeleteEpisodeRequest, AdminDeleteEpisodeRequest, episode_api_server::EpisodeApi, admin_api_server::AdminApi}; // Подключаю оба API удаления
use surrealdb::{Surreal, engine::remote::ws::{Client, Ws}, opt::auth::Root}; // Подключаю отдельную тестовую базу
use serde_json::Value; // Подключаю снимки содержимого таблиц
use tonic::{Request, Code}; // Подключаю запросы и коды ошибок

type TestResult<T> = Result<T, Box<dyn std::error::Error + Send + Sync>>;

fn admin<T>(body:T) -> Request<T> {
    let mut request = Request::new(body);
    request.extensions_mut().insert(Claims {sub:"player:editor".into(),login:"editor".into(),is_admin:true,exp:usize::MAX});
    request
}

async fn remove(db:&Surreal<Client>, admin_api:bool, id:i32) -> Result<bool,tonic::Status> {
    if admin_api {
        Ok(AdminApiService::new(db.clone()).delete_episode(admin(AdminDeleteEpisodeRequest {episode_id:id})).await?.into_inner().success)
    } else {
        Ok(EpisodeApiService::new(db.clone()).delete_episode(admin(DeleteEpisodeRequest {id})).await?.into_inner().success)
    }
}

async fn snapshot(db:&Surreal<Client>) -> TestResult<Vec<Vec<Value>>> {
    let mut response = db.query("SELECT * FROM episode ORDER BY id; SELECT * FROM scene ORDER BY id; SELECT * FROM choice ORDER BY id; SELECT * FROM action ORDER BY id;").await?.check()?;
    Ok((0..4).map(|index|response.take(index)).collect::<Result<_,_>>()?)
}

async fn scenarios(db:Surreal<Client>) -> TestResult<()> {
    for admin_api in [false,true] {
        // Смешиваю числовые и строковые ключи, соседний эпизод должен остаться целым
        db.query("CREATE episode:1; CREATE episode:2;
            CREATE scene:10 SET episode_id=episode:1;
            CREATE scene:branch SET episode_id=episode:1;
            CREATE scene:other SET episode_id=episode:2;
            CREATE choice:20 SET scene_id=scene:10;
            CREATE choice:branch SET scene_id=scene:branch;
            CREATE choice:other SET scene_id=scene:other;
            CREATE action:30 SET choice_id=choice:20;
            CREATE action:branch SET choice_id=choice:branch;
            CREATE action:other SET choice_id=choice:other;").await?.check()?;
        let before=snapshot(&db).await?;
        assert_eq!(before.iter().map(Vec::len).collect::<Vec<_>>(),vec![2,3,3,3]);
        // Ошибка на каждом шаге откатывает даже уже выполненные DELETE
        for table in ["action","choice","scene","episode"] {
            db.query(format!("DEFINE EVENT fail_delete ON {table} WHEN $event='DELETE' THEN {{ THROW 'Тестовый отказ удаления'; }};")).await?.check()?;
            assert_eq!(remove(&db,admin_api,1).await.unwrap_err().code(),Code::Internal);
            assert_eq!(snapshot(&db).await?,before,"После ошибки {table} дерево должно сохраниться");
            db.query(format!("REMOVE EVENT fail_delete ON {table};")).await?.check()?;
        }
        assert!(remove(&db,admin_api,1).await?);
        let after=snapshot(&db).await?;
        assert_eq!(after, before.iter().map(|rows|rows.iter().filter(|row| {
            let id=row["id"].as_str().unwrap();
            id=="episode:2" || id.ends_with(":other")
        }).cloned().collect()).collect::<Vec<Vec<Value>>>());
        assert!(remove(&db,admin_api,1).await?,"Повторное удаление безопасно");
        assert_eq!(remove(&db,admin_api,0).await.unwrap_err().code(),Code::InvalidArgument);
        assert!(remove(&db,admin_api,2).await?);
        assert!(snapshot(&db).await?.iter().all(Vec::is_empty));
        db.query("CREATE episode:3;").await?.check()?;
        assert!(remove(&db,admin_api,3).await?,"Удаляю также эпизод без дочерних записей");
    }
    Ok(())
}

#[tokio::test]
#[ignore = "Нужна локальная SurrealDB; удаляю только данные отдельной тестовой БД"]
async fn both_apis_delete_whole_tree_or_roll_back() -> TestResult<()> {
    let db=Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
    let name=format!("episode_delete_test_{}",uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club").await?;
    db.query(format!("DEFINE DATABASE {name};")).await?.check()?;
    db.use_db(&name).await?;
    let result=tokio::spawn(scenarios(db.clone())).await;
    db.query(format!("REMOVE DATABASE {name};")).await?.check()?;
    result?
}
