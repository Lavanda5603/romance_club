use tonic::{transport::Server, Request, Response, Status};
use surrealdb::engine::remote::ws::{Client, Ws};
use surrealdb::opt::auth::Root;
use surrealdb::Surreal;
use surrealdb::types::SurrealValue;

// Подключаю сгенерированный код
pub mod romance_club {
    tonic::include_proto!("romance_club");
}

use romance_club::episode_api_server::{EpisodeApi, EpisodeApiServer};
use romance_club::{
    Episode, GetEpisodeRequest, GetAllEpisodesRequest, GetAllEpisodesResponse,
    SaveEpisodeRequest, SaveEpisodeResponse,
    Scene, Choice, Action,
};

// Структура эпизода (то, что хранится в SurrealDB)
#[derive(Debug, SurrealValue)]
struct EpisodeRecord {
    title: String, // Название
    version: i32, // Версия
}

// Структура сцены (то, что хранится в SurrealDB)
#[derive(Debug, SurrealValue)]
struct SceneRecord {
    title: String, // Название
    background: String, // Фон
    character: String, // Персонаж
    texts: Vec<String>, // Тексты
    condition: String, // Условие
    text_position: String, // Позиция текста
    character_position: String, // Позиция персонажа
    order_index: i32, // Порядок
}

// Структура выбора (то, что хранится в SurrealDB)
#[derive(Debug, SurrealValue)]
struct ChoiceRecord {
    text: String, // Текст выбора
    title: String, // Название
    order_index: i32, // Порядок
}

// Структура действия (то, что хранится в SurrealDB)
#[derive(Debug, SurrealValue)]
struct ActionRecord {
    r#type: String, // Тип действия
    scene_id: Option<i64>, // ID сцены
    flag_name: Option<String>, // Имя флага
    flag_value: Option<bool>, // Значение флага
    counter_name: Option<String>, // Имя счётчика
    counter_value: Option<i64>, // Значение счётчика
    sound_path: Option<String>, // Путь к звуку
    image_path: Option<String>, // Путь к картинке
    title: String, // Название
}

// Сервис для работы с эпизодами
pub struct EpisodeApiService {
    db: Surreal<Client>, // Подключение к SurrealDB
}

impl EpisodeApiService {
    // Создать новый сервис
    pub fn new(db: Surreal<Client>) -> Self {
        Self { db }
    }
}

#[tonic::async_trait]
impl EpisodeApi for EpisodeApiService {
    // Получить эпизод по ID (со сценами, выборами, действиями)
    async fn get_episode(
        &self,
        request: Request<GetEpisodeRequest>,
    ) -> Result<Response<Episode>, Status> {
        let id = request.into_inner().id;

        println!("[GET_EPISODE] Запрос на эпизод ID: {}", id);

        // 1. Загружаю эпизод
        let episode_record: Option<EpisodeRecord> = self
            .db
            .select(("episode", i64::from(id)))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let episode_record = match episode_record {
            Some(r) => r,
            None => return Err(Status::not_found("Эпизод не найден")),
        };

        // 2. Загружаю сцены эпизода
        let scene_records: Vec<SceneRecord> = self
            .db
            .query("SELECT * FROM scene WHERE episode_id = type::record('episode', $id) ORDER BY order_index")
            .bind(("id", id))
            .await
            .map_err(|e| Status::internal(e.to_string()))?
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        println!("[GET_EPISODE] Найдено сцен: {}", scene_records.len());

        // 3. Собираю сцены с выборами и действиями
        let mut scenes: Vec<Scene> = Vec::new();

        for scene_rec in scene_records.iter() {
            // 3.1. Загружаю выборы сцены
            let choice_records: Vec<ChoiceRecord> = self
                .db
                .query("SELECT * FROM choice WHERE scene_id = type::record('scene', $scene_id) ORDER BY order_index")
                .bind(("scene_id", scene_rec.order_index + 1))
                .await
                .map_err(|e| Status::internal(e.to_string()))?
                .take(0)
                .map_err(|e| Status::internal(e.to_string()))?;

            // 3.2. Собираю выборы с действиями
            let mut choices: Vec<Choice> = Vec::new();

            for choice_rec in choice_records.iter() {
                // 3.3. Загружаю действия выбора
                let action_records: Vec<ActionRecord> = self
                    .db
                    .query("SELECT * FROM action WHERE choice_id = type::record('choice', $choice_id)")
                    .bind(("choice_id", choice_rec.order_index + 1))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?
                    .take(0)
                    .map_err(|e| Status::internal(e.to_string()))?;

                // Собираю действия
                let actions = action_records
                    .into_iter()
                    .map(|a| Action {
                        r#type: a.r#type,
                        scene_id: a.scene_id.unwrap_or(0) as i32,
                        flag_name: a.flag_name.unwrap_or_default(),
                        flag_value: a.flag_value.unwrap_or(false),
                        counter_name: a.counter_name.unwrap_or_default(),
                        counter_value: a.counter_value.unwrap_or(0) as i32,
                        sound_path: a.sound_path.unwrap_or_default(),
                        image_path: a.image_path.unwrap_or_default(),
                        title: a.title,
                    })
                    .collect();

                choices.push(Choice {
                    text: choice_rec.text.clone(),
                    title: choice_rec.title.clone(),
                    actions,
                });
            }

            scenes.push(Scene {
                id: scene_rec.order_index + 1,
                title: scene_rec.title.clone(),
                background: scene_rec.background.clone(),
                character: scene_rec.character.clone(),
                texts: scene_rec.texts.clone(),
                choices,
                condition: scene_rec.condition.clone(),
                text_position: scene_rec.text_position.clone(),
                character_position: scene_rec.character_position.clone(),
            });
        }

        // 4. Собираю финальный эпизод
        let episode = Episode {
            id,
            title: episode_record.title,
            version: episode_record.version,
            scenes,
        };

        println!("[GET_EPISODE] Возвращаю эпизод: {} (сцен: {})", episode.title, episode.scenes.len());

        Ok(Response::new(episode))
    }

    // Получить все эпизоды
    async fn get_all_episodes(
        &self,
        _request: Request<GetAllEpisodesRequest>,
    ) -> Result<Response<GetAllEpisodesResponse>, Status> {
        let records: Vec<EpisodeRecord> = self
            .db
            .select("episode")
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let episodes = records
            .into_iter()
            .enumerate()
            .map(|(index, record)| Episode {
                id: (index + 1) as i32,
                title: record.title,
                version: record.version,
                scenes: vec![],
            })
            .collect();

        Ok(Response::new(GetAllEpisodesResponse { episodes }))
    }

    // Сохранить эпизод (с сценами, выборами, действиями)
    async fn save_episode(
        &self,
        request: Request<SaveEpisodeRequest>,
    ) -> Result<Response<SaveEpisodeResponse>, Status> {
        let episode = request
            .into_inner()
            .episode
            .ok_or_else(|| Status::invalid_argument("Эпизод не передан"))?;

        let id = episode.id;
        let title = episode.title.clone();
        let version = episode.version;

        // 1. Сохраняю эпизод
        self.db
            .query("UPSERT type::record('episode', $id) CONTENT { title: $title, version: $version }")
            .bind(("id", id))
            .bind(("title", title))
            .bind(("version", version))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        // 2. Удаляю старые сцены эпизода (чтобы не дублировать)
        self.db
            .query("DELETE scene WHERE episode_id = type::record('episode', $id)")
            .bind(("id", id))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        // 3. Сохраняю сцены
        for (scene_index, scene) in episode.scenes.iter().enumerate() {
            let scene_id = (scene_index + 1) as i32;

            self.db
                .query("UPSERT type::record('scene', $scene_id) CONTENT { episode_id: type::record('episode', $ep_id), title: $title, background: $background, character: $character, texts: $texts, condition: $condition, text_position: $text_pos, character_position: $char_pos, order_index: $order }")
                .bind(("scene_id", scene_id))
                .bind(("ep_id", id))
                .bind(("title", scene.title.clone()))
                .bind(("background", scene.background.clone()))
                .bind(("character", scene.character.clone()))
                .bind(("texts", scene.texts.clone()))
                .bind(("condition", scene.condition.clone()))
                .bind(("text_pos", scene.text_position.clone()))
                .bind(("char_pos", scene.character_position.clone()))
                .bind(("order", scene_index as i32))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            // 4. Сохраняю выборы
            for (choice_index, choice) in scene.choices.iter().enumerate() {
                let choice_id = (scene_index as i32 * 100 + choice_index as i32 + 1) as i32;

                self.db
                    .query("UPSERT type::record('choice', $choice_id) CONTENT { scene_id: type::record('scene', $scene_id), text: $text, title: $title, order_index: $order }")
                    .bind(("choice_id", choice_id))
                    .bind(("scene_id", scene_id))
                    .bind(("text", choice.text.clone()))
                    .bind(("title", choice.title.clone()))
                    .bind(("order", choice_index as i32))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;

                // 5. Сохраняю действия
                for (action_index, action) in choice.actions.iter().enumerate() {
                    let action_id = (choice_id * 100 + action_index as i32 + 1) as i32;

                    self.db
                        .query("UPSERT type::record('action', $action_id) CONTENT { choice_id: type::record('choice', $choice_id), type: $type, scene_id: $scene_id, flag_name: $flag_name, flag_value: $flag_value, counter_name: $counter_name, counter_value: $counter_value, sound_path: $sound, image_path: $image, title: $title }")
                        .bind(("action_id", action_id))
                        .bind(("choice_id", choice_id))
                        .bind(("type", action.r#type.clone()))
                        .bind(("scene_id", action.scene_id))
                        .bind(("flag_name", action.flag_name.clone()))
                        .bind(("flag_value", action.flag_value))
                        .bind(("counter_name", action.counter_name.clone()))
                        .bind(("counter_value", action.counter_value))
                        .bind(("sound", action.sound_path.clone()))
                        .bind(("image", action.image_path.clone()))
                        .bind(("title", action.title.clone()))
                        .await
                        .map_err(|e| Status::internal(e.to_string()))?;
                }
            }
        }

        Ok(Response::new(SaveEpisodeResponse {
            success: true,
            message: "Эпизод сохранён".to_string(),
        }))
    }
}

// Применение миграций из папки migrations/
async fn apply_migrations(db: &Surreal<Client>) -> Result<(), Box<dyn std::error::Error>> {
    let migrations_dir = std::path::Path::new("migrations");

    if !migrations_dir.exists() {
        println!("Папка migrations/ не найдена, пропускаю");
        return Ok(());
    }

    let mut entries: Vec<_> = std::fs::read_dir(migrations_dir)?
        .filter_map(|e| e.ok())
        .filter(|e| {
            e.path().extension().map(|ext| ext == "surql").unwrap_or(false)
        })
        .collect();

    entries.sort_by_key(|e| e.path());

    for entry in entries {
        let path = entry.path();
        let sql = std::fs::read_to_string(&path)?;

        println!("Применяю миграцию: {:?}", path);
        db.query(&sql).await?;
    }

    println!("Все миграции применены");
    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Подключаюсь к SurrealDB
    let db = Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;

    // Авторизуюсь
    db.signin(Root {
        username: "root".to_string(),
        password: "root".to_string(),
    })
    .await?;

    // Использую namespace и database
    db.use_ns("romance_club").use_db("main").await?;

    println!("Подключение к SurrealDB установлено");

    // Применяю миграции
    apply_migrations(&db).await?;

    let service = EpisodeApiService::new(db);
    let addr = "0.0.0.0:50051".parse()?;

    println!("Сервер запущен на {}", addr);

    Server::builder()
        .add_service(EpisodeApiServer::new(service))
        .serve(addr)
        .await?;

    Ok(())
}