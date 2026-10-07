use tonic::{Request, Response, Status}; // Импорт tonic
use surrealdb::engine::remote::ws::Client; // Импорт клиента SurrealDB
use surrealdb::Surreal; // Импорт Surreal
use serde_json::Value; // Импорт Value
use base64::{Engine as _, engine::general_purpose}; // Для base64
use crate::romance_club::asset_api_server::AssetApi; // Импорт трейта
use crate::romance_club::{
    Asset, GetAssetsRequest, GetAssetsResponse,
    UploadAssetRequest, UploadAssetResponse,
}; // Импорт структур

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
            "SELECT * FROM asset WHERE type = $type ORDER BY display_name".to_string()
        } else {
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
                let id = v.get("id").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let r#type = v.get("type").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let name = v.get("name").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let emotion = v.get("emotion").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let url = v.get("url").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let display_name = v.get("display_name").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let episode_id = v.get("episode_id").and_then(|s| s.as_str()).unwrap_or("").to_string();

                // Читаю байты файла (если есть)
                let file_data = v
                    .get("file_data")
                    .and_then(|s| s.as_str())
                    .map(|s| general_purpose::STANDARD.decode(s).unwrap_or_default())
                    .unwrap_or_default();

                Asset {
                    id,
                    r#type,
                    name,
                    emotion,
                    url,
                    display_name,
                    episode_id,
                    file_data,
                }
            })
            .collect();

        println!("[GET_ASSETS] Найдено ассетов: {}", assets.len());

        Ok(Response::new(GetAssetsResponse { assets }))
    }

    // Загрузить новый ассет
    async fn upload_asset(
        &self,
        request: Request<UploadAssetRequest>,
    ) -> Result<Response<UploadAssetResponse>, Status> {
        let req = request.into_inner();

        println!("[UPLOAD_ASSET] Загрузка: type={}, name={}, emotion={}",
            req.r#type, req.name, req.emotion);

        // Проверяю обязательные поля
        if req.r#type.is_empty() || req.name.is_empty() {
            return Err(Status::invalid_argument("Тип и имя обязательны"));
        }
        if req.file_data.is_empty() {
            return Err(Status::invalid_argument("Файл пустой"));
        }

        // Проверяю размер (не больше 5 МБ)
        if req.file_data.len() > 5 * 1024 * 1024 {
            return Err(Status::invalid_argument("Файл больше 5 МБ"));
        }

        // Кодирую байты в base64
        let file_base64 = general_purpose::STANDARD.encode(&req.file_data);

        // Собираю url
        let url = if req.emotion.is_empty() {
            format!("assets/{}/{}", req.r#type, req.name)
        } else {
            format!("assets/{}/{}_{}", req.r#type, req.name, req.emotion)
        };

        // Эмоция: пустая строка - NONE
        let emotion_value: Option<String> = if req.emotion.is_empty() {
            None
        } else {
            Some(req.emotion.clone())
        };

        // Создаю запись в БД
        let mut response = self
            .db
            .query("CREATE asset CONTENT { type: $type, name: $name, emotion: $emotion, url: $url, display_name: $display_name, file_data: $file_data, created_at: time::now() }")
            .bind(("type", req.r#type.clone()))
            .bind(("name", req.name.clone()))
            .bind(("emotion", emotion_value))
            .bind(("url", url.clone()))
            .bind(("display_name", if req.display_name.is_empty() { req.name.clone() } else { req.display_name.clone() }))
            .bind(("file_data", file_base64))
            .await
            .map_err(|e| {
                println!("[UPLOAD_ASSET] ОШИБКА БД: {}", e);
                Status::internal(format!("Ошибка БД: {}", e))
            })?;

        // Читаю созданную запись
        let created: Option<Value> = response
            .take(0)
            .map_err(|e| {
                println!("[UPLOAD_ASSET] ОШИБКА ЧТЕНИЯ: {}", e);
                Status::internal(format!("Ошибка чтения: {}", e))
            })?;

        let asset = match created {
            Some(v) => {
                let id = v.get("id").and_then(|s| s.as_str()).unwrap_or("").to_string();
                Asset {
                    id,
                    r#type: req.r#type.clone(),
                    name: req.name.clone(),
                    emotion: req.emotion.clone(),
                    url,
                    display_name: if req.display_name.is_empty() { req.name } else { req.display_name },
                    episode_id: String::new(),
                    file_data: req.file_data,
                }
            }
            None => return Err(Status::internal("Не удалось создать ассет")),
        };

        println!("[UPLOAD_ASSET] Ассет загружен: {}", asset.id);

        Ok(Response::new(UploadAssetResponse {
            success: true,
            message: "Ассет загружен".to_string(),
            asset: Some(asset),
        }))
    }
}