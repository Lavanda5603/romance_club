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
