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
    // Проверяю пакетную загрузку: порядок, пустые ветки и чужой эпизод
    let tree = Episode {
        id: 2, title: "Проверка загрузки".into(), version: 3,
        scenes: vec![
            Scene { scene_key: "draft:z".into(), title: "Сначала".into(),
                texts: vec!["Текст".into()], background: "room".into(), character: "hero".into(),
                next_scene_key: "draft:a".into(), choices: vec![
                    Choice { text: "Первый".into(), title: "С действиями".into(), actions: vec![
                        Action { r#type: "setFlag".into(), flag_name: "met".into(), flag_value: true, title: "Флаг".into(), ..Default::default() },
                        Action { r#type: "changeCounter".into(), counter_name: "score".into(), counter_value: -3, title: "Баллы".into(), ..Default::default() },
                    ] },
                    Choice { text: "Второй".into(), title: "Без действий".into(), ..Default::default() },
                ], ..Default::default() },
            Scene { scene_key: "draft:a".into(), title: "Потом".into(), ..Default::default() },
        ],
    };
    api.save_episode(admin(SaveEpisodeRequest { episode: Some(tree) })).await?;
    api.save_episode(admin(SaveEpisodeRequest { episode: Some(Episode { id: 3, title: "Пустой".into(), version: 1, scenes: vec![] }) })).await?;
    let loaded = api.get_episode(admin(GetEpisodeRequest { id: 2 })).await?.into_inner();
    assert_eq!(loaded.title, "Проверка загрузки");
    assert_eq!(loaded.version, 3);
    assert_eq!(loaded.scenes.len(), 2);
    assert_eq!(loaded.scenes[0].title, "Сначала");
    assert_eq!(loaded.scenes[1].title, "Потом");
    assert_eq!(loaded.scenes[0].next_scene_key, loaded.scenes[1].scene_key);
    assert_eq!(loaded.scenes[0].texts, vec!["Текст"]);
    assert_eq!(loaded.scenes[0].background, "room");
    assert_eq!(loaded.scenes[0].character, "hero");
    assert!(loaded.scenes[1].choices.is_empty());
    let choices = &loaded.scenes[0].choices;
    assert_eq!(choices.len(), 2);
    assert_eq!(choices[0].text, "Первый");
    assert_eq!(choices[1].text, "Второй");
    assert!(choices[1].actions.is_empty());
    assert_eq!(choices[0].actions.len(), 2);
    assert!(choices[0].actions.iter().any(|a| a.flag_name == "met" && a.flag_value));
    assert!(choices[0].actions.iter().any(|a| a.counter_name == "score" && a.counter_value == -3));
    assert!(api.get_episode(admin(GetEpisodeRequest { id: 3 })).await?.into_inner().scenes.is_empty());
    assert_eq!(api.get_episode(admin(GetEpisodeRequest { id: 404 })).await.unwrap_err().code(), Code::NotFound);
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