mod progress_service; // Модуль прогресса
mod auth_service; // Модуль авторизации
mod achievement_service; // Модуль достижений
mod shop_service; // Модуль магазина
mod asset_service; // Модуль ассетов
mod admin_service; // Модуль админа
mod jwt; // Модуль JWT

use tonic::{transport::Server, Request, Response, Status}; // Импорт tonic
use tonic::service::Interceptor; // Импорт интерцептора
use surrealdb::engine::remote::ws::{Client, Ws}; // Импорт клиента SurrealDB
use surrealdb::opt::auth::Root; // Импорт Root-авторизации
use surrealdb::Surreal; // Импорт Surreal
use surrealdb::types::SurrealValue; // Импорт SurrealValue
use serde_json::Value; // Импорт Value
use progress_service::ProgressApiService; // Импорт сервиса прогресса
use romance_club::progress_api_server::ProgressApiServer; // Импорт gRPC-сервера прогресса
use auth_service::AuthApiService; // Импорт сервиса авторизации
use romance_club::auth_api_server::AuthApiServer; // Импорт gRPC-сервера авторизации
use achievement_service::AchievementApiService; // Импорт сервиса достижений
use romance_club::achievement_api_server::AchievementApiServer; // Импорт gRPC-сервера достижений
use shop_service::ShopApiService; // Импорт сервиса магазина
use romance_club::shop_api_server::ShopApiServer; // Импорт gRPC-сервера магазина
use asset_service::AssetApiService; // Импорт сервиса ассетов
use romance_club::asset_api_server::AssetApiServer; // Импорт gRPC-сервера ассетов
use admin_service::AdminApiService; // Импорт сервиса админа
use romance_club::admin_api_server::AdminApiServer; // Импорт gRPC-сервера админа

// Подключаю сгенерированный код
pub mod romance_club {
    tonic::include_proto!("romance_club");
}

use romance_club::episode_api_server::{EpisodeApi, EpisodeApiServer}; // Импорт gRPC-сервера эпизодов
use romance_club::{
    Episode, GetEpisodeRequest, GetAllEpisodesRequest, GetAllEpisodesResponse,
    SaveEpisodeRequest, SaveEpisodeResponse,
    DeleteEpisodeRequest, DeleteEpisodeResponse,
    Scene, Choice, Action,
}; // Импорт структур

// Интерцептор для проверки JWT
#[derive(Clone)]
pub struct AuthInterceptor;

impl Interceptor for AuthInterceptor {
    fn call(&mut self, request: Request<()>) -> Result<Request<()>, Status> {
        // Достаю токен из метаданных
        let token = request
            .metadata()
            .get("authorization")
            .and_then(|v| v.to_str().ok())
            .map(|s| s.trim_start_matches("Bearer ").to_string());

        match token {
            Some(t) => match jwt::verify_token(&t) {
                Ok(claims) => {
                    // Кладу claims в extensions, чтобы обработчики могли их достать
                    let mut request = request;
                    request.extensions_mut().insert(claims);
                    Ok(request)
                }
                Err(e) => {
                    println!("[INTERCEPTOR] Неверный токен: {}", e);
                    Err(Status::unauthenticated("Неверный токен"))
                }
            },
            // Нет токена - отказ (кроме Register/Login, они на AuthApi без интерцептора)
            None => Err(Status::unauthenticated("Требуется токен")),
        }
    }
}

// Структура эпизода (то, что хранится в SurrealDB)
#[derive(Debug, SurrealValue)]
struct EpisodeRecord {
    title: String, // Название
    version: i32, // Версия
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
        let mut sc_response = self
            .db
            .query("SELECT * FROM scene WHERE episode_id = type::record('episode', $id) ORDER BY order_index")
            .bind(("id", i64::from(id)))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let scene_values: Vec<Value> = sc_response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        println!("[GET_EPISODE] Найдено сцен: {}", scene_values.len());

        let mut scenes: Vec<Scene> = Vec::new();

        // 3. Собираю сцены с выборами и действиями
        for scene_value in scene_values.iter() {
            // Извлекаю поля сцены
            let scene_id_str = scene_value.get("id").and_then(|v| v.as_str()).unwrap_or("scene:0").to_string();
            let title = scene_value.get("title").and_then(|v| v.as_str()).unwrap_or("").to_string();
            let background = scene_value.get("background").and_then(|v| v.as_str()).unwrap_or("").to_string();
            let character = scene_value.get("character").and_then(|v| v.as_str()).unwrap_or("").to_string();
            let character_emotion = scene_value.get("character_emotion").and_then(|v| v.as_str()).unwrap_or("").to_string();
            let condition = scene_value.get("condition").and_then(|v| v.as_str()).unwrap_or("").to_string();
            let text_position = scene_value.get("text_position").and_then(|v| v.as_str()).unwrap_or("").to_string();
            let character_position = scene_value.get("character_position").and_then(|v| v.as_str()).unwrap_or("").to_string();
            let order_index = scene_value.get("order_index").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
            let texts: Vec<String> = scene_value
                .get("texts")
                .and_then(|v| v.as_array())
                .map(|arr| arr.iter().filter_map(|x| x.as_str().map(|s| s.to_string())).collect())
                .unwrap_or_default();

            // Загружаю выборы сцены
            let mut ch_response = self
                .db
                .query("SELECT * FROM choice WHERE scene_id = type::record($scene_id) ORDER BY order_index")
                .bind(("scene_id", scene_id_str.clone()))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            let choice_values: Vec<Value> = ch_response
                .take(0)
                .map_err(|e| Status::internal(e.to_string()))?;

            let mut choices: Vec<Choice> = Vec::new();

            for choice_value in choice_values.iter() {
                let choice_id_str = choice_value.get("id").and_then(|v| v.as_str()).unwrap_or("choice:0").to_string();
                let text = choice_value.get("text").and_then(|v| v.as_str()).unwrap_or("").to_string();
                let choice_title = choice_value.get("title").and_then(|v| v.as_str()).unwrap_or("").to_string();

                // Загружаю действия выбора
                let mut ac_response = self
                    .db
                    .query("SELECT * FROM action WHERE choice_id = type::record($choice_id)")
                    .bind(("choice_id", choice_id_str.clone()))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;

                let action_records: Vec<ActionRecord> = ac_response
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

                choices.push(Choice { text, title: choice_title, actions });
            }

            // Читаю next_scene_id (0 = конец)
            let next_scene_id = scene_value.get("next_scene_id").and_then(|v| v.as_i64()).unwrap_or(0) as i32;

            scenes.push(Scene {
                id: order_index + 1,
                scene_key: scene_id_str.clone(),
                title,
                background,
                character,
                character_emotion,
                texts,
                choices,
                condition,
                text_position,
                character_position,
                next_scene_id,
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
        let mut response = self
            .db
            .query("SELECT * FROM episode ORDER BY created_at ASC")
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let records: Vec<Value> = response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        let episodes = records
            .into_iter()
            .map(|v| {
                let id = v.get("id").and_then(|s| s.as_str())
                    .and_then(|s| s.strip_prefix("episode:"))
                    .and_then(|s| s.parse::<i32>().ok())
                    .unwrap_or(0);
                let title = v.get("title").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let version = v.get("version").and_then(|s| s.as_i64()).unwrap_or(1) as i32;
                Episode { id, title, version, scenes: vec![] }
            })
            .collect();

        Ok(Response::new(GetAllEpisodesResponse { episodes }))
    }

    // Сохранить эпизод (с сценами, выборами, действиями)
    async fn save_episode(
        &self,
        request: Request<SaveEpisodeRequest>,
    ) -> Result<Response<SaveEpisodeResponse>, Status> {
        let episode = request.into_inner().episode
            .ok_or_else(|| Status::invalid_argument("Эпизод не передан"))?;

        // Сохраняю эпизод
        println!("[SAVE_EPISODE] Сохраняю эпизод ID: {}", episode.id);
        println!("[SAVE_EPISODE] Название: {}", episode.title);
        println!("[SAVE_EPISODE] Сцен: {}", episode.scenes.len());

        let id = episode.id;
        let title = episode.title.clone();
        let version = episode.version;
        let id_i64 = i64::from(id);

        // 1. Сохраняю эпизод
        self.db
            .query("UPSERT type::record('episode', $id) CONTENT { title: $title, version: $version, created_at: time::now() }")
            .bind(("id", id_i64))
            .bind(("title", title))
            .bind(("version", version))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        // 2. Удаляю старые action эпизода (в два шага)
        {
            let mut ids_response = self
                .db
                .query("SELECT VALUE id FROM action WHERE choice_id IN (SELECT VALUE id FROM choice WHERE scene_id IN (SELECT VALUE id FROM scene WHERE episode_id = type::record('episode', $id)))")
                .bind(("id", id_i64))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            let ids: Vec<Value> = ids_response.take(0).map_err(|e| Status::internal(e.to_string()))?;

            if !ids.is_empty() {
                self.db
                    .query("DELETE $ids")
                    .bind(("ids", ids))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;
            }
        }

        // 3. Удаляю старые choice эпизода (в два шага)
        {
            let mut ids_response = self
                .db
                .query("SELECT VALUE id FROM choice WHERE scene_id IN (SELECT VALUE id FROM scene WHERE episode_id = type::record('episode', $id))")
                .bind(("id", id_i64))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            let ids: Vec<Value> = ids_response.take(0).map_err(|e| Status::internal(e.to_string()))?;

            if !ids.is_empty() {
                self.db
                    .query("DELETE $ids")
                    .bind(("ids", ids))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;
            }
        }

        // 4. Удаляю старые scene эпизода (в два шага)
        {
            let mut ids_response = self
                .db
                .query("SELECT VALUE id FROM scene WHERE episode_id = type::record('episode', $id)")
                .bind(("id", id_i64))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            let ids: Vec<Value> = ids_response.take(0).map_err(|e| Status::internal(e.to_string()))?;

            if !ids.is_empty() {
                self.db
                    .query("DELETE $ids")
                    .bind(("ids", ids))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;
            }
        }

        // 5. Сохраняю сцены
        for (scene_index, scene) in episode.scenes.iter().enumerate() {
            // Сохраняю сцену
            println!("[SAVE_EPISODE] Сцена {}: {} (фон: {}, персонаж: {})",
                scene_index, scene.title, scene.background, scene.character);

            // Создаю сцену
            let mut sc_response = self
                .db
                .query("CREATE scene CONTENT { episode_id: type::record('episode', $ep_id), title: $title, background: $background, character: $character, character_emotion: $char_emotion, texts: $texts, condition: $condition, text_position: $text_pos, character_position: $char_pos, order_index: $order, next_scene_id: $next_scene } RETURN id")
                .bind(("ep_id", id_i64)) // i64
                .bind(("title", scene.title.clone()))
                .bind(("background", scene.background.clone()))
                .bind(("character", scene.character.clone()))
                .bind(("char_emotion", scene.character_emotion.clone()))
                .bind(("texts", scene.texts.clone()))
                .bind(("condition", scene.condition.clone()))
                .bind(("text_pos", scene.text_position.clone()))
                .bind(("char_pos", scene.character_position.clone()))
                .bind(("order", scene_index as i32))
                .bind(("next_scene", scene.next_scene_id))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            // Извлекаю id созданной сцены (результат - массив с одним элементом)
            let scene_rows: Vec<Value> = sc_response.take(0).map_err(|e| Status::internal(e.to_string()))?;
            let scene_id_str = match scene_rows.first() {
                Some(v) => v.get("id").and_then(|id| id.as_str()).map(|s| s.to_string()),
                None => None,
            };
            let scene_id_str = match scene_id_str {
                Some(s) => {
                    println!("[SAVE_EPISODE] Создана сцена: {}", s);
                    s
                }
                None => {
                    println!("[SAVE_EPISODE] ОШИБКА: сцена не создана (нет id)");
                    continue;
                }
            };

            // 6. Сохраняю выборы
            for (choice_index, choice) in scene.choices.iter().enumerate() {
                let mut ch_response = self
                    .db
                    .query("CREATE choice CONTENT { scene_id: type::record($scene_id), text: $text, title: $title, order_index: $order } RETURN id")
                    .bind(("scene_id", scene_id_str.clone()))
                    .bind(("text", choice.text.clone()))
                    .bind(("title", choice.title.clone()))
                    .bind(("order", choice_index as i32))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;

                // Извлекаю id созданного выбора (результат - массив с одним элементом)
                let choice_rows: Vec<Value> = ch_response.take(0).map_err(|e| Status::internal(e.to_string()))?;
                let choice_id_str = match choice_rows.first() {
                    Some(v) => v.get("id").and_then(|id| id.as_str()).map(|s| s.to_string()),
                    None => None,
                };
                let choice_id_str = match choice_id_str {
                    Some(s) => {
                        println!("[SAVE_EPISODE] Создан выбор: {}", s);
                        s
                    }
                    None => {
                        println!("[SAVE_EPISODE] ОШИБКА: выбор не создан (нет id)");
                        continue;
                    }
                };

                // 7. Сохраняю действия
                for action in choice.actions.iter() {
                    let mut ac_response = self
                        .db
                        .query("CREATE action CONTENT { choice_id: type::record($choice_id), type: $type, scene_id: $scene_id, flag_name: $flag_name, flag_value: $flag_value, counter_name: $counter_name, counter_value: $counter_value, sound_path: $sound, image_path: $image, title: $title } RETURN id")
                        .bind(("choice_id", choice_id_str.clone()))
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

                    let action_rows: Vec<Value> = ac_response.take(0).map_err(|e| Status::internal(e.to_string()))?;
                    if let Some(v) = action_rows.first() {
                        if let Some(id) = v.get("id").and_then(|id| id.as_str()) {
                            println!("[SAVE_EPISODE] Создано действие: {}", id);
                        }
                    }
                }
            }
        }

        println!("[SAVE_EPISODE] Эпизод сохранён: {} (сцен: {})", id, episode.scenes.len());

        Ok(Response::new(SaveEpisodeResponse {
            success: true,
            message: "Эпизод сохранён".to_string(),
        }))
    }

    // Удалить эпизод (со сценами, выборами, действиями)
    async fn delete_episode(
        &self,
        request: Request<DeleteEpisodeRequest>,
    ) -> Result<Response<DeleteEpisodeResponse>, Status> {
        let id = request.into_inner().id;
        println!("[DELETE_EPISODE] Удаляю эпизод ID: {}", id);

        let id_i64 = i64::from(id);

        // 1. Удаляю действия (в два шага)
        {
            let mut ids_response = self
                .db
                .query("SELECT VALUE id FROM action WHERE choice_id IN (SELECT VALUE id FROM choice WHERE scene_id IN (SELECT VALUE id FROM scene WHERE episode_id = type::record('episode', $id)))")
                .bind(("id", id_i64))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            let ids: Vec<Value> = ids_response.take(0).map_err(|e| Status::internal(e.to_string()))?;

            if !ids.is_empty() {
                self.db
                    .query("DELETE $ids")
                    .bind(("ids", ids))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;
            }
        }

        // 2. Удаляю выборы (в два шага)
        {
            let mut ids_response = self
                .db
                .query("SELECT VALUE id FROM choice WHERE scene_id IN (SELECT VALUE id FROM scene WHERE episode_id = type::record('episode', $id))")
                .bind(("id", id_i64))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            let ids: Vec<Value> = ids_response.take(0).map_err(|e| Status::internal(e.to_string()))?;

            if !ids.is_empty() {
                self.db
                    .query("DELETE $ids")
                    .bind(("ids", ids))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;
            }
        }

        // 3. Удаляю сцены (в два шага)
        {
            let mut ids_response = self
                .db
                .query("SELECT VALUE id FROM scene WHERE episode_id = type::record('episode', $id)")
                .bind(("id", id_i64))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            let ids: Vec<Value> = ids_response.take(0).map_err(|e| Status::internal(e.to_string()))?;

            if !ids.is_empty() {
                self.db
                    .query("DELETE $ids")
                    .bind(("ids", ids))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;
            }
        }

        // 4. Удаляю эпизод
        self.db
            .query("DELETE type::record('episode', $id)")
            .bind(("id", id_i64))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        println!("[DELETE_EPISODE] Эпизод удалён");

        Ok(Response::new(DeleteEpisodeResponse {
            success: true,
            message: "Эпизод удалён".to_string(),
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
        .filter(|e| e.path().extension().map(|ext| ext == "surql").unwrap_or(false))
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
    // Загружаю переменные окружения из .env
    dotenvy::dotenv().ok();

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

    let episode_service = EpisodeApiService::new(db.clone()); // Сервис эпизодов
    let progress_service = ProgressApiService::new(db.clone()); // Сервис прогресса
    let auth_service = AuthApiService::new(db.clone()); // Сервис авторизации
    let achievement_service = AchievementApiService::new(db.clone()); // Сервис достижений
    let shop_service = ShopApiService::new(db.clone()); // Сервис магазина
    let asset_service = AssetApiService::new(db.clone()); // Сервис ассетов
    let admin_service = AdminApiService::new(db); // Сервис админа
    let addr = "0.0.0.0:50051".parse()?;

    println!("Сервер запущен на {}", addr);

    // Интерцептор JWT
    let interceptor = AuthInterceptor;

    Server::builder()
        .add_service(EpisodeApiServer::with_interceptor(episode_service, interceptor.clone())) // Сервис эпизодов
        .add_service(ProgressApiServer::with_interceptor(progress_service, interceptor.clone())) // Сервис прогресса
        .add_service(AuthApiServer::new(auth_service)) // Сервис авторизации (без интерцептора)
        .add_service(AchievementApiServer::with_interceptor(achievement_service, interceptor.clone())) // Сервис достижений
        .add_service(ShopApiServer::with_interceptor(shop_service, interceptor.clone())) // Сервис магазина
        .add_service(AssetApiServer::with_interceptor(asset_service, interceptor.clone())) // Сервис ассетов
        .add_service(AdminApiServer::with_interceptor(admin_service, interceptor)) // Сервис админа
        .serve(addr)
        .await?;

    Ok(())
}