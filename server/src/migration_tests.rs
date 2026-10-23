use super::*; // Подключаю запуск миграций
use surrealdb::{engine::remote::ws::Ws, opt::auth::Root}; // Подключаю отдельную БД

type TestResult = Result<(), Box<dyn Error + Send + Sync>>;

async fn snapshot(db: &Surreal<Client>) -> Result<serde_json::Value, surrealdb::Error> {
    let mut rows = db.query("RETURN {scenes:(SELECT * FROM scene ORDER BY id),actions:(SELECT * FROM action ORDER BY id),versions:(SELECT * FROM schema_migration ORDER BY id)};").await?.check()?;
    Ok(rows.take::<Option<serde_json::Value>>(0)?.unwrap())
}

async fn scenarios(db: Surreal<Client>, folder: std::path::PathBuf) -> TestResult {
    // Первый запуск на старой числовой схеме
    db.query("DEFINE TABLE scene SCHEMALESS; DEFINE FIELD next_scene_id ON scene TYPE int DEFAULT 0;
        DEFINE TABLE action SCHEMALESS; DEFINE FIELD scene_id ON action TYPE option<int>;
        CREATE scene:200 SET next_scene_id=220; CREATE scene:220 SET next_scene_id=0;
        CREATE action:one SET type='nextScene',scene_id=220,flag_name='keep',flag_value=true;
        CREATE scene:300 SET next_scene_id=220,next_scene_key='scene:custom';
        CREATE action:two SET type='nextScene',scene_id=220,scene_key='scene:custom';").await?.check()?;
    std::fs::write(folder.join("023_scene_links_preserve.surql"),include_str!("../migrations/023_scene_links_preserve.surql"))?;
    apply_dir(&db,&folder).await?;
    let first = snapshot(&db).await?;
    assert_eq!(first["scenes"][0]["next_scene_key"],"scene:220");
    assert_eq!(first["scenes"][0]["next_scene_id"],220);
    assert_eq!(first["scenes"][1]["next_scene_key"],"");
    assert_eq!(first["actions"][0]["scene_key"],"scene:220");
    assert_eq!(first["actions"][0]["flag_value"],true);
    assert_eq!(first["scenes"][2]["next_scene_key"],"scene:custom");
    assert_eq!(first["actions"][1]["scene_key"],"scene:custom");
    for _ in 0..2 { apply_dir(&db,&folder).await?; assert_eq!(snapshot(&db).await?,first); }
    // После редактирования перезапуск не возвращает прежние значения
    db.query("UPDATE scene:200 SET next_scene_key='scene:branch'; UPDATE action:one SET scene_key='scene:branch';").await?.check()?;
    let edited = snapshot(&db).await?;
    for _ in 0..2 { apply_dir(&db,&folder).await?; assert_eq!(snapshot(&db).await?,edited); }

    // Неудачная миграция не записывает версию и не оставляет часть изменений
    std::fs::write(folder.join("024_failure.surql"),"BEGIN TRANSACTION;\nUPDATE scene:200 SET next_scene_key='broken';\nTHROW 'TEST_MIGRATION_FAILURE';\nCOMMIT TRANSACTION;")?;
    assert!(apply_dir(&db,&folder).await.unwrap_err().to_string().contains("TEST_MIGRATION_FAILURE"));
    assert_eq!(snapshot(&db).await?,edited);
    std::fs::write(folder.join("024_failure.surql"),"UPDATE scene:200 SET next_scene_key='scene:branch';")?;
    apply_dir(&db,&folder).await?;
    let repaired = snapshot(&db).await?;
    assert_eq!(repaired["versions"].as_array().unwrap().len(),2);
    // Изменённый применённый файл не выполняю молча заново
    std::fs::write(folder.join("024_failure.surql"),"UPDATE scene:200 SET next_scene_key='broken';")?;
    assert!(apply_dir(&db,&folder).await.unwrap_err().to_string().contains("Изменена применённая миграция"));
    assert_eq!(snapshot(&db).await?,repaired);
    // Проверяю и полный набор файлов для базы со строками из старой 014
    db.query("REMOVE TABLE schema_migration; REMOVE TABLE scene; REMOVE TABLE action;").await?.check()?;
    std::fs::remove_file(folder.join("023_scene_links_preserve.surql"))?;
    std::fs::remove_file(folder.join("024_failure.surql"))?;
    for entry in std::fs::read_dir("migrations")? {
        let path = entry?.path();
        let file = path.file_name().unwrap().to_str().unwrap();
        if file <= "012_zz.surql" { std::fs::copy(&path,folder.join(file))?; }
    }
    apply_dir(&db,&folder).await?;
    db.query("DEFINE FIELD OVERWRITE next_scene_id ON scene TYPE string DEFAULT '';
        DEFINE FIELD OVERWRITE scene_id ON action TYPE option<string>;
        CREATE scene:200 CONTENT {episode_id:episode:1,title:'Начало',background:'',character:'',character_emotion:'',texts:['Текст'],condition:'',text_position:'bottom',character_position:'center',order_index:0,next_scene_id:'scene:220'};
        CREATE action:one CONTENT {choice_id:choice:one,type:'nextScene',title:'Выбор',scene_id:'scene:220',counter_name:'points',counter_value:5};").await?.check()?;
    for entry in std::fs::read_dir("migrations")? {
        let path = entry?.path();
        std::fs::copy(&path,folder.join(path.file_name().unwrap()))?;
    }
    apply_dir(&db,&folder).await?;
    let strings = snapshot(&db).await?;
    assert_eq!(strings["scenes"][0]["next_scene_id"],"scene:220");
    assert_eq!(strings["scenes"][0]["next_scene_key"],"scene:220");
    assert_eq!(strings["actions"][0]["scene_id"],"scene:220");
    assert_eq!(strings["actions"][0]["scene_key"],"scene:220");
    assert_eq!(strings["actions"][0]["counter_value"],5);
    for _ in 0..2 { apply_dir(&db,&folder).await?; assert_eq!(snapshot(&db).await?,strings); }
    Ok(())
}

#[tokio::test]
#[ignore = "Нужна отдельная SurrealDB; рабочую базу не использую"]
async fn upgrade_preserves_story_and_runs_once() -> TestResult {
    let db = Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
    let name = format!("migration_test_{}",uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club").use_db(&name).await?;
    let folder = std::env::temp_dir().join(&name);
    std::fs::create_dir(&folder)?;
    let result = tokio::spawn(scenarios(db.clone(),folder.clone())).await;
    db.query(format!("REMOVE DATABASE {name};")).await?.check()?;
    std::fs::remove_dir_all(folder)?;
    result?
}

// Проверяю, что архивирование никогда не удаляет сцену с живой ссылкой.
async fn hidden_cleanup_cases(db: Surreal<Client>) -> TestResult {
    db.query("DEFINE TABLE scene SCHEMALESS; DEFINE TABLE episode SCHEMALESS;
        DEFINE TABLE choice SCHEMALESS; DEFINE TABLE action SCHEMALESS;
        DEFINE TABLE progress SCHEMALESS; DEFINE TABLE story_archive SCHEMALESS PERMISSIONS NONE;
        CREATE scene:339 SET episode_id=episode:6,title='сцена 1';").await?.check()?;
    let cleanup = include_str!("../migrations/028_hidden_scenes_and_cleanup.surql")
        .split("-- Добавляю необязательные разговоры.").next().unwrap();
    for guard in [
        "CREATE scene:guard SET next_scene_key='scene:339';",
        "CREATE scene:guard SET next_scene_id=339;",
        "CREATE scene:guard SET next_scene_id='scene:339';",
        "CREATE scene:guard SET routes=[{condition:'',scene_key:'scene:339'}];",
        "CREATE action:guard SET scene_key='scene:339';",
        "CREATE action:guard SET scene_id=339;",
        "CREATE action:guard SET scene_id='scene:339';",
        "CREATE choice:guard SET scene_id=scene:339;",
        "CREATE progress:guard SET scene_id='scene:339';",
        "CREATE episode:6 SET title='Эпизод восстановлен';",
        "UPDATE scene:339 SET title='Авторская сцена';",
        "CREATE story_archive:orphan_scene_339 SET data='Прежний архив';",
    ] {
        // После каждой проверки убираю только временные записи из тестовой БД.
        db.query(format!("BEGIN TRANSACTION; {guard} {cleanup}
            IF !record::exists(scene:339) {{ THROW 'Удалена связанная или изменённая сцена'; }};
            COMMIT TRANSACTION;")).await?.check()?;
        db.query("DELETE scene:guard; DELETE action:guard; DELETE choice:guard;
            DELETE progress:guard; DELETE episode:6; DELETE story_archive:orphan_scene_339;
            UPDATE scene:339 SET title='сцена 1';").await?.check()?;
    }
    // Сбой общей транзакции должен вернуть сцену и убрать незавершённый архив.
    let mut failed = db.query(format!("BEGIN TRANSACTION; {cleanup}
        THROW 'Проверяю откат'; COMMIT TRANSACTION;")).await?;
    assert!(!failed.take_errors().is_empty());
    let mut before = db.query("RETURN {scene:record::exists(scene:339),archive:record::exists(story_archive:orphan_scene_339)};").await?.check()?;
    let before: Option<serde_json::Value> = before.take(0)?;
    assert_eq!(before.unwrap(),serde_json::json!({"scene":true,"archive":false}));
    db.query(format!("BEGIN TRANSACTION; {cleanup} COMMIT TRANSACTION;")).await?.check()?;
    let mut archived = db.query("SELECT * FROM ONLY story_archive:orphan_scene_339;").await?.check()?;
    let archived: Option<serde_json::Value> = archived.take(0)?;
    let archived = archived.unwrap();
    assert_eq!(archived["data"]["id"],"scene:339");
    assert_eq!(archived["data"]["episode_id"],"episode:6");
    assert_eq!(archived["data"]["title"],"сцена 1");
    // Повторный запуск сохраняет тот же архив без второй записи.
    db.query(format!("BEGIN TRANSACTION; {cleanup} COMMIT TRANSACTION;")).await?.check()?;
    let mut repeated = db.query("SELECT * FROM ONLY story_archive:orphan_scene_339; RETURN record::exists(scene:339);").await?.check()?;
    assert_eq!(repeated.take::<Option<serde_json::Value>>(0)?.unwrap(),archived);
    assert!(!repeated.take::<Option<bool>>(1)?.unwrap());
    Ok(())
}

#[tokio::test]
#[ignore = "Нужна отдельная SurrealDB; рабочую базу не использую"]
async fn hidden_cleanup_archives_only_unreferenced_orphan() -> TestResult {
    let db = Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
    let name = format!("hidden_cleanup_{}",uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club").use_db(&name).await?;
    let result = tokio::spawn(hidden_cleanup_cases(db.clone())).await;
    db.query(format!("REMOVE DATABASE {name};")).await?.check()?;
    result?
}