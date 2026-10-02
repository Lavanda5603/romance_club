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
};

// Внутренняя структура для хранения эпизода в SurrealDB
#[derive(Debug, SurrealValue)]
struct EpisodeRecord {
    title: String, // Название
    version: i32, // Версия
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
    // Получить эпизод по ID
    async fn get_episode(
        &self,
        request: Request<GetEpisodeRequest>,
    ) -> Result<Response<Episode>, Status> {
        let id = request.into_inner().id;

        // Отладка: получили запрос
        println!("[GET_EPISODE] Получен запрос на эпизод с ID: {}", id);

        // Запрашиваю эпизод через query
        let mut response = self
            .db
            .query("SELECT * FROM type::thing('episode', $id)")
            .bind(("id", id))
            .await
            .map_err(|e| {
                println!("[GET_EPISODE] Ошибка запроса к SurrealDB: {}", e);
                Status::internal(e.to_string())
            })?;

        // Отладка: запрос выполнен
        println!("[GET_EPISODE] Запрос к SurrealDB выполнен");

        // Парсю ответ
        let result: Option<EpisodeRecord> = response
            .take(0)
            .map_err(|e| {
                println!("[GET_EPISODE] Ошибка парсинга: {}", e);
                Status::internal(e.to_string())
            })?;

        // Отладка: результат
        println!("[GET_EPISODE] Результат: {:?}", result);

        // Разворачиваю Option
        match result {
            Some(record) => {
                let episode = Episode {
                    id,
                    title: record.title,
                    version: record.version,
                    scenes: vec![],
                };
                println!("[GET_EPISODE] Возвращаю эпизод: {}", episode.title);
                Ok(Response::new(episode))
            }
            None => {
                println!("[GET_EPISODE] Эпизод не найден");
                Err(Status::not_found("Эпизод не найден"))
            }
        }
    }

    // Получить все эпизоды
    async fn get_all_episodes(
        &self,
        _request: Request<GetAllEpisodesRequest>,
    ) -> Result<Response<GetAllEpisodesResponse>, Status> {
        // Запрашиваю все эпизоды
        let mut response = self
            .db
            .query("SELECT * FROM episode")
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        // Парсю ответ
        let records: Vec<EpisodeRecord> = response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        // Преобразую в Protobuf-модели
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

    // Сохранить эпизод
    async fn save_episode(
        &self,
        request: Request<SaveEpisodeRequest>,
    ) -> Result<Response<SaveEpisodeResponse>, Status> {
        let episode = request
            .into_inner()
            .episode
            .ok_or_else(|| Status::invalid_argument("Эпизод не передан"))?;

        // Извлекаю поля
        let id = episode.id;
        let title = episode.title.clone();
        let version = episode.version;

        // Сохраняю через query
        let _ = self
            .db
            .query("UPSERT type::thing('episode', $id) CONTENT { title: $title, version: $version }")
            .bind(("id", id))
            .bind(("title", title))
            .bind(("version", version))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        Ok(Response::new(SaveEpisodeResponse {
            success: true,
            message: "Эпизод сохранён".to_string(),
        }))
    }
}

// Применение миграций из папки migrations/
async fn apply_migrations(db: &Surreal<Client>) -> Result<(), Box<dyn std::error::Error>> {
    // Читаю все файлы из папки migrations/
    let migrations_dir = std::path::Path::new("migrations");

    // Если папки нет - выхожу
    if !migrations_dir.exists() {
        println!("Папка migrations/ не найдена, пропускаю");
        return Ok(());
    }

    // Читаю все файлы
    let mut entries: Vec<_> = std::fs::read_dir(migrations_dir)?
        .filter_map(|e| e.ok())
        .filter(|e| {
            // Только .surql-файлы
            e.path().extension().map(|ext| ext == "surql").unwrap_or(false)
        })
        .collect();

    // Сортирую по имени (чтобы 001 шёл раньше 002)
    entries.sort_by_key(|e| e.path());

    // Применяю каждый файл
    for entry in entries {
        let path = entry.path();
        let sql = std::fs::read_to_string(&path)?;

        println!("Применяю миграцию: {:?}", path);

        // Выполняю SQL
        db.query(&sql).await?;
    }

    println!("Все миграции применены");

    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Подключаюсь к SurrealDB по WebSocket
    let db = Surreal::new::<Ws>("127.0.0.1:8000").await?;

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

    // Создаю сервис
    let service = EpisodeApiService::new(db);

    // Адрес сервера
    let addr = "0.0.0.0:50051".parse()?;

    println!("Сервер запущен на {}", addr);

    // Запускаю gRPC-сервер
    Server::builder()
        .add_service(EpisodeApiServer::new(service))
        .serve(addr)
        .await?;

    Ok(())
}