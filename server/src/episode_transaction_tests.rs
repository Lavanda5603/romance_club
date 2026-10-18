use crate::{EpisodeApiService, jwt::Claims};
use crate::romance_club::{Episode, Scene, Choice, Action, SaveEpisodeRequest, GetEpisodeRequest};
use crate::romance_club::episode_api_server::EpisodeApi;
use serde_json::Value;
use surrealdb::{Surreal, engine::remote::ws::{Client, Ws}, opt::auth::Root};
use tonic::{Request, Code};

type TestResult<T> = Result<T, Box<dyn std::error::Error + Send + Sync>>;

fn admin<T>(body: T) -> Request<T> {
    let mut request = Request::new(body);
    request.extensions_mut().insert(Claims {
        sub: "player:editor".into(), login: "editor".into(), is_admin: true, exp: usize::MAX,
    });
    request
}

async fn snapshot(db: &Surreal<Client>) -> TestResult<Vec<Vec<Value>>> {
    let mut response = db.query("SELECT * FROM episode ORDER BY id; SELECT * FROM scene ORDER BY id; SELECT * FROM choice ORDER BY id; SELECT * FROM action ORDER BY id;").await?.check()?;
    Ok((0..4).map(|index| response.take(index)).collect::<Result<_, _>>()?)
}

async fn scenarios(db: Surreal<Client>) -> TestResult<()> {
    crate::apply_migrations(&db).await.map_err(|e| e.to_string())?;
    let api = EpisodeApiService::new(db.clone());
    let original = Episode {
        id: 1, title: "Исходный эпизод".into(), version: 1,
        scenes: vec![
            Scene { scene_key: "draft:first".into(), title: "Первая".into(), texts: vec!["Исходный текст".into()],
                next_scene_key: "draft:second".into(), choices: vec![Choice { title: "Выбор".into(), text: "Дальше".into(),
                    actions: vec![Action { r#type: "nextScene".into(), scene_key: "draft:second".into(), title: "Переход".into(), ..Default::default() }],
                    ..Default::default() }], ..Default::default() },
            Scene { scene_key: "draft:second".into(), title: "Вторая".into(), ..Default::default() },
        ], ..Default::default()
    };
    assert!(api.save_episode(admin(SaveEpisodeRequest { episode: Some(original) })).await?.into_inner().success);
    let loaded = api.get_episode(admin(GetEpisodeRequest { id: 1 })).await?.into_inner();
    let before = snapshot(&db).await?;
    assert_eq!(before.iter().map(Vec::len).collect::<Vec<_>>(), vec![1, 2, 1, 1]);

    let mut edited = loaded.clone();
    edited.title = "Изменённый эпизод".into();
    edited.version = 2;
    edited.scenes.pop();
    edited.scenes[0].title = "Изменённая сцена".into();
    edited.scenes[0].texts = vec!["Новый текст".into()];
    edited.scenes[0].next_scene_key.clear();
    edited.scenes[0].next_scene_id = 0;
    edited.scenes[0].choices[0].title = "Новый выбор".into();
    edited.scenes[0].choices[0].actions = vec![Action {
        r#type: "changeCounter".into(), counter_name: "points".into(), counter_value: 5,
        title: "Новые баллы".into(), ..Default::default()
    }];
    // Эта новая сцена успевает записаться до ошибки в следующей
    edited.scenes.insert(0, Scene { scene_key: "draft:added".into(), title: "Новая сцена".into(), ..Default::default() });

    for table in ["scene", "choice", "action"] {
        db.query(format!("DEFINE FIELD OVERWRITE title ON {table} TYPE string ASSERT $value != '__fail__';")).await?.check()?;
        let mut invalid = edited.clone();
        match table {
            "scene" => invalid.scenes[1].title = "__fail__".into(),
            "choice" => invalid.scenes[1].choices[0].title = "__fail__".into(),
            _ => {
                let mut failing = invalid.scenes[1].choices[0].actions[0].clone();
                failing.title = "__fail__".into();
                invalid.scenes[1].choices[0].actions.push(failing);
            }
        }
        let result = api.save_episode(admin(SaveEpisodeRequest { episode: Some(invalid) })).await;
        assert_eq!(result.unwrap_err().code(), Code::Internal, "Ошибка {table} не должна возвращать success");
        assert_eq!(snapshot(&db).await?, before, "После ошибки {table} дерево должно полностью откатиться");
        db.query(format!("DEFINE FIELD OVERWRITE title ON {table} TYPE string;")).await?.check()?;
    }

    // Без искусственной ошибки сохраняются все части дерева
    assert!(api.save_episode(admin(SaveEpisodeRequest { episode: Some(edited) })).await?.into_inner().success);
    let after = snapshot(&db).await?;
    assert_eq!(after.iter().map(Vec::len).collect::<Vec<_>>(), vec![1, 2, 1, 1]);
    assert_eq!(after[0][0]["title"], "Изменённый эпизод");
    assert_eq!(after[0][0]["version"], 2);
    assert!(after[1].iter().all(|row| row["id"] != loaded.scenes[1].scene_key));
    assert!(after[1].iter().any(|row| row["title"] == "Новая сцена"));
    assert_eq!(after[2][0]["title"], "Новый выбор");
    assert_eq!(after[3][0]["counter_value"], 5);
    Ok(())
}

#[tokio::test]
#[ignore = "Нужна локальная SurrealDB; проверяю откат в отдельной тестовой БД"]
async fn episode_save_rolls_back_every_part_of_tree() -> TestResult<()> {
    let db = Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root { username: std::env::var("SURREAL_USER")?, password: std::env::var("SURREAL_PASS")? }).await?;
    let name = format!("episode_tx_test_{}", uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club").await?;
    db.query(format!("DEFINE DATABASE {name};")).await?.check()?;
    db.use_db(&name).await?;
    let result = tokio::spawn(scenarios(db.clone())).await;
    db.query(format!("REMOVE DATABASE {name};")).await?.check()?;
    result?
}
