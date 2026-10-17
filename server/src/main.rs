mod progress_service; // Модуль прогресса
mod auth_service; // Модуль авторизации
mod achievement_service; // Модуль достижений
mod shop_service; // Модуль магазина
mod asset_service; // Модуль ассетов
mod admin_service; // Модуль админа
mod jwt; // Модуль JWT
mod episode_store;
mod request_auth;

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
    fn call(&mut self, mut request: Request<()>) -> Result<Request<()>, Status> {
        // Сохраняю владельца токена для обработчиков
        let claims = request_auth::authenticate(&request)?;
        request.extensions_mut().insert(claims);
        Ok(request)
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
                id: scene_id_str.strip_prefix("scene:")
                    .and_then(|id| id.parse::<i32>().ok()).unwrap_or(order_index + 1),
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
        // Проверяю админа
        crate::request_auth::check_admin(&request)?;

        let episode = request.into_inner().episode
            .ok_or_else(|| Status::invalid_argument("Эпизод не передан"))?;

        // Сохраняю эпизод
        println!("[SAVE_EPISODE] Сохраняю эпизод ID: {}", episode.id);
        println!("[SAVE_EPISODE] Название: {}", episode.title);
        println!("[SAVE_EPISODE] Сцен: {}", episode.scenes.len());

        episode_store::save(&self.db, &episode).await?;
        println!("[SAVE_EPISODE] Эпизод сохранён: {} (сцен: {})", episode.id, episode.scenes.len());

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
        // Проверяю админа
        crate::request_auth::check_admin(&request)?;

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
        db.query(&sql).await?.check()?;
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
    let namespace = std::env::var("SURREAL_NAMESPACE")
        .unwrap_or_else(|_| "romance_club".into());
    let database = std::env::var("SURREAL_DATABASE").unwrap_or_else(|_| "main".into());
    db.use_ns(&namespace).use_db(&database).await?;

    println!("Подключение к SurrealDB установлено: namespace={}, database={}", namespace, database);

    // Применяю миграции
    apply_migrations(&db).await?;

    let episode_service = EpisodeApiService::new(db.clone()); // Сервис эпизодов
    let progress_service = ProgressApiService::new(db.clone()); // Сервис прогресса
    let auth_service = AuthApiService::new(db.clone()); // Сервис авторизации
    let achievement_service = AchievementApiService::new(db.clone()); // Сервис достижений
    let shop_service = ShopApiService::new(db.clone()); // Сервис магазина
    let asset_service = AssetApiService::new(db.clone()); // Сервис ассетов
    let admin_service = AdminApiService::new(db); // Сервис админа
    let addr = std::env::var("GRPC_BIND")
        .unwrap_or_else(|_| "0.0.0.0:50051".into())
        .parse()?;

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