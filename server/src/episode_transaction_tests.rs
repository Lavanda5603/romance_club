use crate::{EpisodeApiService, jwt::Claims}; // Подключаю модули сервера
use crate::romance_club::{Episode, Scene, Choice, Action, SaveEpisodeRequest, GetEpisodeRequest, SceneRoute}; // Подключаю модули сервера
use crate::romance_club::episode_api_server::EpisodeApi; // Подключаю модули сервера
use serde_json::Value; // Подключаю работу с JSON
use surrealdb::{Surreal, engine::remote::ws::{Client, Ws}, opt::auth::Root}; // Подключаю работу с SurrealDB
use tonic::{Request, Code}; // Подключаю запросы, ответы и ошибки gRPC

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
    crate::request_auth::seed_test_admin(&db,"player:editor").await?;
    let api = EpisodeApiService::new(db.clone());
    let original = Episode {
        id: 1, title: "Исходный эпизод".into(), version: 1,
        scenes: vec![
            Scene { scene_key: "draft:first".into(), title: "Первая".into(), texts: vec!["Исходный текст".into()],
                next_scene_key: "draft:second".into(), routes:vec![SceneRoute {condition:"friendship>=5 AND flag:met=true".into(),scene_key:"draft:second".into()}], choices: vec![Choice { title: "Выбор".into(), text: "Дальше".into(),
                    actions: vec![Action { r#type: "nextScene".into(), scene_key: "draft:second".into(), title: "Переход".into(), ..Default::default() }],
                    ..Default::default() }], ..Default::default() },
            Scene { scene_key: "draft:second".into(), title: "Вторая".into(), ..Default::default() },
        ], ..Default::default()
    };
    assert!(api.save_episode(admin(SaveEpisodeRequest { episode: Some(original) })).await?.into_inner().success);
    let loaded = api.get_episode(admin(GetEpisodeRequest { id: 1 })).await?.into_inner();
    assert_eq!(loaded.scenes[0].routes[0].scene_key,loaded.scenes[1].scene_key);
    assert_eq!(loaded.scenes[0].routes[0].condition,"friendship>=5 AND flag:met=true");
    let before = snapshot(&db).await?;
    assert_eq!(before.iter().map(Vec::len).collect::<Vec<_>>(), vec![1, 2, 1, 1]);

    let mut edited = loaded.clone();
    edited.title = "Изменённый эпизод".into();
    edited.version = 2;
    edited.scenes.pop();
    edited.scenes[0].title = "Изменённая сцена".into();
    edited.scenes[0].texts = vec!["Новый текст".into()];
    edited.scenes[0].routes.clear();
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
    record_filters_round_trip(&api,&db).await?;
    legacy_route_rules(&api,&db).await?;
    Ok(())
}

// Проверяю конфигурацию прежних веток и сохранение новых правил сервером
async fn legacy_route_rules(api:&EpisodeApiService,db:&Surreal<Client>) -> TestResult<()> {
    for (episode, ids) in [(4,vec![220,221,226,236,231]),(5,vec![307,308,314,320,334,328])] {
        db.query("UPSERT type::record('episode',$ep) SET title='Ветки',version=1;
            FOR $key IN $keys { CREATE type::record('scene',$key) CONTENT {episode_id:type::record('episode',$ep),title:'Ветка',background:'',character:'',character_emotion:'',texts:[],condition:'',text_position:'bottom',character_position:'center',order_index:$key}; };")
            .bind(("ep",episode)).bind(("keys",ids)).await?.check()?;
    }
    db.query(include_str!("../migrations/026_story_route_rules.surql")).await?.check()?;
    for (episode, key, count, default) in [(4,"scene:220",4,"scene:221"),(5,"scene:307",5,"scene:308")] {
        let mut tree=api.get_episode(admin(GetEpisodeRequest {id:episode})).await?.into_inner();
        let scene=tree.scenes.iter().find(|s|s.scene_key==key).unwrap();
        assert_eq!(scene.routes.len(),count);
        assert_eq!(scene.next_scene_key,default);
        assert!(scene.routes.iter().all(|r|tree.scenes.iter().any(|s|s.scene_key==r.scene_key)));
        tree.scenes.iter_mut().find(|s|s.scene_key==key).unwrap().routes[0].condition="friendship>=42".into();
        api.save_episode(admin(SaveEpisodeRequest {episode:Some(tree.clone())})).await?;
        let saved=api.get_episode(admin(GetEpisodeRequest {id:episode})).await?.into_inner();
        assert_eq!(saved.scenes.iter().find(|s|s.scene_key==key).unwrap().routes[0].condition,"friendship>=42");
        db.query(include_str!("../migrations/026_story_route_rules.surql")).await?.check()?;
        assert_eq!(api.get_episode(admin(GetEpisodeRequest {id:episode})).await?.into_inner(),saved);
    }
    Ok(())
}

// Тип записи проверяю на смешанных ключах, а не только на автоматически созданных ID
async fn record_filters_round_trip(api: &EpisodeApiService, db: &Surreal<Client>) -> TestResult<()> {
    db.query("CREATE episode:4 SET title='Проверка record ID',version=1;
        CREATE scene:777 CONTENT {episode_id:episode:4,title:'Числовой ключ',background:'room',character:'hero',character_emotion:'happy',texts:['Первая реплика'],condition:'',text_position:'bottom_center',character_position:'center',order_index:0,next_scene_id:0,next_scene_key:'scene:branch'};
        CREATE scene:branch CONTENT {episode_id:episode:4,title:'Строковый ключ',background:'street',character:'hero',character_emotion:'sad',texts:['Вторая реплика'],condition:'',text_position:'bottom_center',character_position:'left',order_index:1,next_scene_id:0,next_scene_key:''};
        CREATE choice:named CONTENT {scene_id:scene:777,text:'Первый вариант',title:'Первый',order_index:0};
        CREATE choice:17 CONTENT {scene_id:scene:777,text:'Второй вариант',title:'Второй',order_index:1};
        CREATE choice:99 CONTENT {scene_id:scene:branch,text:'Последний вариант',title:'Третий',order_index:0};
        CREATE action:1 CONTENT {choice_id:choice:named,type:'nextScene',scene_id:'scene:branch',scene_key:'scene:branch',title:'Переход',counter_name:'friendship',counter_value:2,flag_name:'met',flag_value:true};
        CREATE action:named CONTENT {choice_id:choice:17,type:'changeCounter',title:'Баллы',counter_name:'points',counter_value:-3};
        CREATE action:3 CONTENT {choice_id:choice:99,type:'changeFlag',title:'Флаг',flag_name:'secret',flag_value:true};").await?.check()?;
    // Строка действительно не равна record; рабочий фильтр должен сохранить тип
    let mut proof = db.query("SELECT VALUE id FROM choice WHERE scene_id IN ['scene:777'];
        LET $ids = SELECT VALUE id FROM scene WHERE episode_id=episode:4;
        SELECT VALUE id FROM choice WHERE scene_id IN $ids;").await?.check()?;
    assert!(proof.take::<Vec<Value>>(0)?.is_empty());
    assert_eq!(proof.take::<Vec<surrealdb::types::RecordId>>(2)?.len(),3);
    let loaded = api.get_episode(admin(GetEpisodeRequest {id:4})).await?.into_inner();
    assert_eq!(loaded.scenes.iter().map(|scene|scene.scene_key.as_str()).collect::<Vec<_>>(),vec!["scene:777","scene:branch"]);
    assert_eq!(loaded.scenes.iter().map(|scene|scene.choices.len()).collect::<Vec<_>>(),vec![2,1]);
    assert_eq!(loaded.scenes.iter().flat_map(|scene|&scene.choices).map(|choice|choice.actions.len()).collect::<Vec<_>>(),vec![1,1,1]);
    assert_eq!(loaded.scenes[0].choices[0].actions[0].scene_key,"scene:branch");
    assert_eq!(loaded.scenes[0].choices[0].actions[0].counter_value,2);
    assert!(loaded.scenes[1].choices[0].actions[0].flag_value);
    // Простое изменение названия не должно удалить выборы или их эффекты
    let mut edited = loaded;
    edited.title = "Новое название без потери дерева".into();
    for _ in 0..2 {
        assert!(api.save_episode(admin(SaveEpisodeRequest {episode:Some(edited.clone())})).await?.into_inner().success);
        let reloaded = api.get_episode(admin(GetEpisodeRequest {id:4})).await?.into_inner();
        assert_eq!(reloaded,edited);
    }
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