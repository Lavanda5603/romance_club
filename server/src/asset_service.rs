use tonic::{Request, Response, Status};
use surrealdb::{engine::remote::ws::Client, Surreal};
use serde_json::Value;
use base64::{Engine as _, engine::general_purpose::STANDARD};
use crate::{asset_preview, romance_club::{asset_api_server::AssetApi, *}};

pub const MAX_UPLOAD_BYTES: usize = 5 * 1024 * 1024;
// Оставляю место для полей Protobuf и превью в ответе
const MAX_MESSAGE_BYTES: usize = MAX_UPLOAD_BYTES + 1024 * 1024;

pub struct AssetApiService { db: Surreal<Client> }
const CATALOG_FIELDS: &str = "id, type, name, emotion, url, display_name, episode_id, preview_data, version";
fn text(row: &Value, field: &str) -> String { row[field].as_str().unwrap_or_default().to_owned() }
fn internal(error: impl std::fmt::Display) -> Status { Status::internal(error.to_string()) }

fn asset(row: &Value, original: bool) -> Result<Asset, Status> {
    let decode = |field| STANDARD.decode(text(row, field)).map_err(|_| Status::internal("Повреждены данные изображения"));
    Ok(Asset {
        id: text(row, "id"), r#type: text(row, "type"), name: text(row, "name"),
        emotion: text(row, "emotion"), url: text(row, "url"), display_name: text(row, "display_name"),
        episode_id: text(row, "episode_id"), version: text(row, "version"), preview_data: decode("preview_data")?,
        file_data: if original { decode("file_data")? } else { Vec::new() },
    })
}

impl AssetApiService {
    pub fn new(db: Surreal<Client>) -> Self { Self { db } }

    pub fn into_server(self) -> asset_api_server::AssetApiServer<Self> {
        asset_api_server::AssetApiServer::new(self)
            .max_decoding_message_size(MAX_MESSAGE_BYTES)
            .max_encoding_message_size(MAX_MESSAGE_BYTES)
    }

    // Старый оригинал читаю только тогда, когда записи нужно превью
    async fn preview(&self, mut row: Value) -> Result<Value, Status> {
        if !text(&row, "preview_data").is_empty() { return Ok(row); }
        if !matches!(text(&row, "type").as_str(), "background" | "character") { return Ok(row); }
        let id = text(&row, "id");
        let mut response = self.db.query("SELECT * FROM type::record($id)")
            .bind(("id", id.clone())).await.map_err(internal)?.check().map_err(internal)?;
        let full: Option<Value> = response.take(0).map_err(internal)?;
        let Some(full) = full else { return Ok(row); };
        let source = text(&full, "file_data");
        if source.is_empty() { return Ok(row); }
        let bytes = STANDARD.decode(&source).map_err(|_| Status::internal("Повреждён оригинал изображения"))?;
        let (preview, version) = asset_preview::make(bytes).await?;
        // Не затираю картинку, которую успели заменить во время обработки
        self.db.query("UPDATE type::record($id) SET preview_data = $preview, version = $version WHERE file_data = $source AND (preview_data = NONE OR preview_data = '')")
            .bind(("id", id.clone())).bind(("preview", STANDARD.encode(&preview)))
            .bind(("version", version)).bind(("source", source))
            .await.map_err(internal)?.check().map_err(internal)?;
        let mut response = self.db.query(format!("SELECT {CATALOG_FIELDS} FROM type::record($id)"))
            .bind(("id", id)).await.map_err(internal)?.check().map_err(internal)?;
        if let Some(current) = response.take::<Option<Value>>(0).map_err(internal)? { row = current; }
        Ok(row)
    }
}

#[tonic::async_trait]
impl AssetApi for AssetApiService {
    async fn get_assets(&self, request: Request<GetAssetsRequest>) -> Result<Response<GetAssetsResponse>, Status> {
        let req = request.into_inner();
        if !matches!(req.r#type.as_str(), "background" | "character" | "sound") {
            return Err(Status::invalid_argument("Неизвестный тип ассета"));
        }
        if req.limit < 0 || (!req.cursor.is_empty() && !req.cursor.starts_with("asset:")) {
            return Err(Status::invalid_argument("Неверный размер страницы или курсор"));
        }
        let limit = if req.limit == 0 { 24 } else { req.limit.min(24) } as usize;
        // В каталог не выбираю file_data. Курсор задаёт порядок по ID
        let mut response = self.db.query(format!("SELECT {CATALOG_FIELDS} FROM asset WHERE type = $type AND ($ep = '' OR episode_id = type::record($ep) OR episode_id = NONE) AND ($cursor = '' OR id > type::record($cursor)) ORDER BY id LIMIT $limit"))
            .bind(("type", req.r#type)).bind(("ep", req.episode_id))
            .bind(("cursor", req.cursor)).bind(("limit", limit + 1))
            .await.map_err(internal)?.check().map_err(internal)?;
        let mut rows: Vec<Value> = response.take(0).map_err(internal)?;
        let more = rows.len() > limit;
        rows.truncate(limit);
        let next_cursor = if more { rows.last().map(|row| text(row, "id")).unwrap_or_default() } else { String::new() };
        // Обрабатываю не больше четырёх старых картинок одновременно
        let mut pending = rows.into_iter().enumerate();
        let mut jobs = tokio::task::JoinSet::new();
        let launch = |jobs: &mut tokio::task::JoinSet<Result<(usize, Value), Status>>, index, row| {
            let service = Self::new(self.db.clone());
            jobs.spawn(async move { Ok((index, service.preview(row).await?)) });
        };
        for (index, row) in pending.by_ref().take(4) { launch(&mut jobs, index, row); }
        let mut ordered = Vec::new();
        while let Some(result) = jobs.join_next().await {
            let (index, row) = result.map_err(internal)??;
            ordered.push((index, asset(&row, false)?));
            if let Some((index, row)) = pending.next() { launch(&mut jobs, index, row); }
        }
        ordered.sort_by_key(|(index, _)| *index);
        let assets = ordered.into_iter().map(|(_, asset)| asset).collect();
        Ok(Response::new(GetAssetsResponse { assets, next_cursor }))
    }

    async fn get_asset(&self, request: Request<GetAssetRequest>) -> Result<Response<Asset>, Status> {
        let req = request.into_inner();
        if req.id.is_empty() && (req.name.is_empty() || req.r#type.is_empty()) {
            return Err(Status::invalid_argument("Нужен ID или имя ассета с типом"));
        }
        if !req.id.is_empty() && !req.id.starts_with("asset:") { return Err(Status::invalid_argument("Неверный ID ассета")); }
        let fields = if req.metadata_only { "id, type, name, emotion, url, display_name, episode_id, version" } else { "*" };
        let mut response = self.db.query(format!("SELECT {fields} FROM asset WHERE ($id != '' AND id = type::record($id)) OR ($id = '' AND type = $type AND name = $name AND (emotion ?? '') = $emotion AND ($ep = '' OR episode_id = type::record($ep) OR episode_id = NONE)) ORDER BY episode_id DESC, id LIMIT 1"))
            .bind(("id", req.id)).bind(("type", req.r#type)).bind(("name", req.name))
            .bind(("emotion", req.emotion)).bind(("ep", req.episode_id))
            .await.map_err(internal)?.check().map_err(internal)?;
        let rows: Vec<Value> = response.take(0).map_err(internal)?;
        let row = rows.first().ok_or_else(|| Status::not_found("Ассет не найден"))?;
        Ok(Response::new(asset(row, !req.metadata_only)?))
    }

    async fn upload_asset(&self, request: Request<UploadAssetRequest>) -> Result<Response<UploadAssetResponse>, Status> {
        crate::request_auth::check_admin(&request)?;
        let req = request.into_inner();
        if !matches!(req.r#type.as_str(), "background" | "character") || req.name.is_empty() || req.file_data.is_empty() {
            return Err(Status::invalid_argument("Нужны тип, имя и изображение"));
        }
        if req.file_data.len() > MAX_UPLOAD_BYTES { return Err(Status::invalid_argument("Файл больше 5 MiB (5 242 880 байт)")); }
        let (preview, version) = asset_preview::make(req.file_data.clone()).await?;
        let mut response = self.db.query("SELECT id FROM asset WHERE type = $type AND name = $name AND (emotion ?? '') = $emotion AND episode_id = (IF $ep = '' { NONE } ELSE { type::record($ep) }) LIMIT 1")
            .bind(("type", req.r#type.clone())).bind(("name", req.name.clone()))
            .bind(("emotion", req.emotion.clone())).bind(("ep", req.episode_id.clone()))
            .await.map_err(internal)?.check().map_err(internal)?;
        let rows: Vec<Value> = response.take(0).map_err(internal)?;
        let id = rows.first().map(|row| text(row, "id")).unwrap_or_else(|| format!("asset:{}", uuid::Uuid::new_v4().simple()));
        let display = if req.display_name.is_empty() { req.name.clone() } else { req.display_name };
        let url = format!("assets/{}/{}", req.r#type, req.name);
        // Оригинал и превью заменяю одной записью
        let mut response = self.db.query("UPSERT type::record($id) MERGE {type:$type, name:$name, emotion:(IF $emotion='' { NONE } ELSE { $emotion }), episode_id:(IF $ep='' { NONE } ELSE { type::record($ep) }), url:$url, display_name:$display, file_data:$file, preview_data:$preview, version:$version} RETURN AFTER")
            .bind(("id", id)).bind(("type", req.r#type)).bind(("name", req.name)).bind(("emotion", req.emotion))
            .bind(("ep", req.episode_id)).bind(("url", url)).bind(("display", display))
            .bind(("file", STANDARD.encode(&req.file_data))).bind(("preview", STANDARD.encode(preview))).bind(("version", version))
            .await.map_err(internal)?.check().map_err(internal)?;
        let rows: Vec<Value> = response.take(0).map_err(internal)?;
        let row = rows.first().ok_or_else(|| Status::internal("Ассет не сохранён"))?;
        Ok(Response::new(UploadAssetResponse { success: true, message: "Ассет сохранён".into(), asset: Some(asset(row, false)?) }))
    }

    async fn delete_asset(&self, request: Request<DeleteAssetRequest>) -> Result<Response<DeleteAssetResponse>, Status> {
        crate::request_auth::check_admin(&request)?;
        let id = request.into_inner().id;
        if !id.starts_with("asset:") { return Err(Status::invalid_argument("Неверный ID ассета")); }
        self.db.query("DELETE type::record($id)").bind(("id", id)).await.map_err(internal)?.check().map_err(internal)?;
        Ok(Response::new(DeleteAssetResponse { success: true, message: "Ассет удалён".into() }))
    }
}

#[cfg(test)]
#[path = "asset_tests.rs"]
mod tests;
