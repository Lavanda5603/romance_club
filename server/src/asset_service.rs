use tonic::{Request, Response, Status}; // Импорт tonic
use surrealdb::engine::remote::ws::Client; // Импорт клиента SurrealDB
use surrealdb::Surreal; // Импорт Surreal
use serde_json::Value; // Импорт Value
use base64::{Engine as _, engine::general_purpose}; // Для base64
use std::io::Cursor; // Для чтения байтов в image
use image::{ImageFormat, GenericImageView}; // Для работы с изображениями
use crate::romance_club::asset_api_server::AssetApi; // Импорт трейта
use crate::romance_club::{
    Asset, GetAssetsRequest, GetAssetsResponse,
    GetAssetFullRequest, GetAssetFullResponse,
    UploadAssetRequest, UploadAssetResponse,
    DeleteAssetRequest, DeleteAssetResponse,
}; // Импорт структур
use crate::admin_service::AdminApiService; // Для проверки админа

// Размер превью (по большей стороне)
const PREVIEW_MAX_SIZE: u32 = 200;

// Сервис для работы с ассетами
pub struct AssetApiService {
    db: Surreal<Client>, // Подключение к SurrealDB
}

impl AssetApiService {
    // Создать новый сервис
    pub fn new(db: Surreal<Client>) -> Self {
        Self { db }
    }

    // Сгенерировать превью из байтов изображения
    fn make_preview(data: &[u8]) -> Result<Vec<u8>, String> {
        // Открываю изображение из байтов
        let img = image::load_from_memory(data)
            .map_err(|e| format!("Ошибка чтения картинки: {}", e))?;

        // Уменьшаю (по большей стороне до PREVIEW_MAX_SIZE)
        let (w, h) = img.dimensions();
        let scale = (PREVIEW_MAX_SIZE as f32 / w.max(h) as f32).min(1.0);
        let nw = (w as f32 * scale) as u32;
        let nh = (h as f32 * scale) as u32;
        let small = img.resize_exact(nw, nh, image::imageops::FilterType::Lanczos3);

        // Кодирую в JPEG (меньше размер, чем PNG)
        let mut buf = Vec::new();
        small.write_to(&mut Cursor::new(&mut buf), ImageFormat::Jpeg)
            .map_err(|e| format!("Ошибка кодирования превью: {}", e))?;

        Ok(buf)
    }
}

#[tonic::async_trait]
impl AssetApi for AssetApiService {
    // Получить ассеты по типу (с превью, без оригиналов)
    async fn get_assets(
        &self,
        request: Request<GetAssetsRequest>,
    ) -> Result<Response<GetAssetsResponse>, Status> {
        let req = request.into_inner(); // Достаю данные из запроса
        let asset_type = req.r#type; // Тип (background, character)
        let episode_id = req.episode_id; // ID эпизода

        println!("[GET_ASSETS] Тип: {}, Эпизод: {}", asset_type, episode_id);

        // Собираю SQL: с фильтром по эпизоду или без
        let query = if episode_id.is_empty() {
            "SELECT id, type, name, emotion, url, display_name, episode_id, preview_data FROM asset WHERE type = $type ORDER BY display_name".to_string()
        } else {
            "SELECT id, type, name, emotion, url, display_name, episode_id, preview_data FROM asset WHERE type = $type AND (episode_id = type::record($ep_id) OR episode_id = NONE) ORDER BY display_name".to_string()
        };

        // Выполняю запрос
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

        // Преобразую записи в Asset (только превью!)
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

                // Декодирую превью (если есть)
                let preview_data = v
                    .get("preview_data")
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
                    preview_data,
                }
            })
            .collect();

        println!("[GET_ASSETS] Найдено ассетов: {}", assets.len());

        Ok(Response::new(GetAssetsResponse { assets }))
    }

    // Получить оригинал ассета по ID
    async fn get_asset_full(
        &self,
        request: Request<GetAssetFullRequest>,
    ) -> Result<Response<GetAssetFullResponse>, Status> {
        let id = request.into_inner().id;

        println!("[GET_ASSET_FULL] Запрос на оригинал: {}", id);

        if id.is_empty() {
            return Err(Status::invalid_argument("ID обязателен"));
        }

        // Читаю file_data из БД
        let mut response = self
            .db
            .query("SELECT file_data FROM type::record($id)")
            .bind(("id", id.clone()))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let result: Option<Value> = response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        let file_data = match result {
            Some(v) => {
                let file_base64 = v.get("file_data").and_then(|s| s.as_str()).unwrap_or("");
                general_purpose::STANDARD.decode(file_base64).unwrap_or_default()
            }
            None => return Err(Status::not_found("Ассет не найден")),
        };

        println!("[GET_ASSET_FULL] Оригинал отдан: {} байт", file_data.len());

        Ok(Response::new(GetAssetFullResponse { file_data }))
    }

    // Загрузить новый ассет (с генерацией превью)
    async fn upload_asset(
        &self,
        request: Request<UploadAssetRequest>,
    ) -> Result<Response<UploadAssetResponse>, Status> {
        // Проверяю, что запрос от админа
        AdminApiService::check_admin(&request)?;

        let req = request.into_inner(); // Достаю данные из запроса

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

        // Кодирую оригинал в base64
        let file_base64 = general_purpose::STANDARD.encode(&req.file_data);

        // Генерирую превью
        let preview_bytes = match AssetApiService::make_preview(&req.file_data) {
            Ok(p) => p,
            Err(e) => {
                println!("[UPLOAD_ASSET] Ошибка генерации превью: {}", e);
                return Err(Status::invalid_argument(format!("Не удалось создать превью: {}", e)));
            }
        };
        let preview_base64 = general_purpose::STANDARD.encode(&preview_bytes);

        println!("[UPLOAD_ASSET] Оригинал: {} байт, превью: {} байт",
            req.file_data.len(), preview_bytes.len());

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

        let display_name_final = if req.display_name.is_empty() { req.name.clone() } else { req.display_name.clone() };

        // Проверяю - есть ли уже запись
        let mut check_response = self
            .db
            .query("SELECT id FROM asset WHERE type = $type AND name = $name AND emotion = $emotion")
            .bind(("type", req.r#type.clone()))
            .bind(("name", req.name.clone()))
            .bind(("emotion", emotion_value.clone()))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let existing: Vec<Value> = check_response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        // Если запись уже есть - обновляю
        if !existing.is_empty() {
            let existing_id = existing[0]
                .get("id")
                .and_then(|s| s.as_str())
                .unwrap_or("")
                .to_string();

            println!("[UPLOAD_ASSET] Найдена существующая запись: {}", existing_id);

            // Обновляю (url, display_name, file_data, preview_data)
            self.db
                .query("UPDATE type::record($id) SET url = $url, display_name = $display_name, file_data = $file_data, preview_data = $preview_data")
                .bind(("id", existing_id.clone()))
                .bind(("url", url.clone()))
                .bind(("display_name", display_name_final.clone()))
                .bind(("file_data", file_base64.clone()))
                .bind(("preview_data", preview_base64.clone()))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            // Собираю Asset
            let asset = Asset {
                id: existing_id.clone(),
                r#type: req.r#type.clone(),
                name: req.name.clone(),
                emotion: req.emotion.clone(),
                url,
                display_name: display_name_final.clone(),
                episode_id: String::new(),
                preview_data: preview_bytes,
            };

            println!("[UPLOAD_ASSET] Ассет обновлён: {}", asset.id);

            return Ok(Response::new(UploadAssetResponse {
                success: true,
                message: "Ассет обновлён".to_string(),
                asset: Some(asset),
            }));
        }

        // Если записи нет - создаю новую
        println!("[UPLOAD_ASSET] Создаю новую запись");

        let mut response = self
            .db
            .query("CREATE asset CONTENT { type: $type, name: $name, emotion: $emotion, url: $url, display_name: $display_name, file_data: $file_data, preview_data: $preview_data, created_at: time::now() }")
            .bind(("type", req.r#type.clone()))
            .bind(("name", req.name.clone()))
            .bind(("emotion", emotion_value))
            .bind(("url", url.clone()))
            .bind(("display_name", display_name_final.clone()))
            .bind(("file_data", file_base64))
            .bind(("preview_data", preview_base64))
            .await
            .map_err(|e| {
                println!("[UPLOAD_ASSET] ОШИБКА БД: {}", e);
                Status::internal(format!("Ошибка БД: {}", e))
            })?;

        let created: Option<Value> = response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        let asset = match created {
            Some(v) => {
                let id = v.get("id").and_then(|s| s.as_str()).unwrap_or("").to_string();
                Asset {
                    id,
                    r#type: req.r#type.clone(),
                    name: req.name.clone(),
                    emotion: req.emotion.clone(),
                    url,
                    display_name: display_name_final,
                    episode_id: String::new(),
                    preview_data: preview_bytes,
                }
            }
            None => return Err(Status::internal("Не удалось создать ассет")),
        };

        println!("[UPLOAD_ASSET] Ассет создан: {}", asset.id);

        Ok(Response::new(UploadAssetResponse {
            success: true,
            message: "Ассет загружен".to_string(),
            asset: Some(asset),
        }))
    }

    // Удалить ассет по ID
    async fn delete_asset(
        &self,
        request: Request<DeleteAssetRequest>,
    ) -> Result<Response<DeleteAssetResponse>, Status> {
        // Проверяю, что запрос от админа
        AdminApiService::check_admin(&request)?;

        let id = request.into_inner().id;

        println!("[DELETE_ASSET] Удаляю ассет: {}", id);

        if id.is_empty() {
            return Err(Status::invalid_argument("ID обязателен"));
        }

        self.db
            .query("DELETE type::record($id)")
            .bind(("id", id.clone()))
            .await
            .map_err(|e| {
                println!("[DELETE_ASSET] ОШИБКА: {}", e);
                Status::internal(format!("Ошибка удаления: {}", e))
            })?;

        println!("[DELETE_ASSET] Ассет удалён: {}", id);

        Ok(Response::new(DeleteAssetResponse {
            success: true,
            message: "Ассет удалён".to_string(),
        }))
    }
}