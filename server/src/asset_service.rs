use tonic::{Request, Response, Status}; // Импорт tonic
use surrealdb::engine::remote::ws::Client; // Импорт клиента SurrealDB
use surrealdb::Surreal; // Импорт Surreal
use serde_json::Value; // Импорт Value
use crate::romance_club::asset_api_server::AssetApi; // Импорт трейта
use crate::romance_club::{Asset, GetAssetsRequest, GetAssetsResponse}; // Импорт структур

// Сервис для работы с ассетами
pub struct AssetApiService {
    db: Surreal<Client>, // Подключение к SurrealDB
}

impl AssetApiService {
    // Создать новый сервис
    pub fn new(db: Surreal<Client>) -> Self {
        Self { db }
    }
}

#[tonic::async_trait]
impl AssetApi for AssetApiService {
    // Получить ассеты по типу
    async fn get_assets(
        &self,
        request: Request<GetAssetsRequest>,
    ) -> Result<Response<GetAssetsResponse>, Status> {
        let req = request.into_inner();
        let asset_type = req.r#type;
        let episode_id = req.episode_id;

        println!("[GET_ASSETS] Тип: {}, Эпизод: {}", asset_type, episode_id);

        // Собираю SQL-запрос
        let query = if episode_id.is_empty() {
            // Без фильтра по эпизоду
            "SELECT * FROM asset WHERE type = $type ORDER BY display_name".to_string()
        } else {
            // С фильтром по эпизоду
            "SELECT * FROM asset WHERE type = $type AND (episode_id = type::record($ep_id) OR episode_id = NONE) ORDER BY display_name".to_string()
        };

        let mut response = self
            .db
            .query(query)
            .bind(("type", asset_type))
            .bind(("ep_id", episode_id))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let records: Vec<Value> = response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        // Преобразую записи в Asset
       let assets: Vec<Asset> = records
            .into_iter()
            .map(|v| {
                let id = v
                    .get("id")
                    .and_then(|s| s.as_str())
                    .unwrap_or("")
                    .to_string();
                let r#type = v.get("type").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let name = v.get("name").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let emotion = v.get("emotion").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let url = v.get("url").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let display_name = v.get("display_name").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let episode_id = v.get("episode_id").and_then(|s| s.as_str()).unwrap_or("").to_string();

                Asset {
                    id,
                    r#type,
                    name,
                    emotion,
                    url,
                    display_name,
                    episode_id,
                }
            })
            .collect();

        println!("[GET_ASSETS] Найдено ассетов: {}", assets.len());

        Ok(Response::new(GetAssetsResponse { assets }))
    }
}