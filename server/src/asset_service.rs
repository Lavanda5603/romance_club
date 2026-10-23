use tonic::{Request, Response, Status}; // Подключаю запросы, ответы и ошибки gRPC
use surrealdb::{engine::remote::ws::Client, Surreal}; // Подключаю работу с SurrealDB
use serde_json::Value; // Подключаю работу с JSON
use surrealdb::types::{Bytes, RecordId, SurrealValue, ToSql}; // Подключаю работу с SurrealDB
use crate::{asset_preview, romance_club::{asset_api_server::AssetApi, *}}; // Подключаю модули сервера

pub const MAX_UPLOAD_BYTES: usize = 5 * 1024 * 1024;
// Оставляю место для полей Protobuf и превью в ответе
const MAX_MESSAGE_BYTES: usize = MAX_UPLOAD_BYTES + 1024 * 1024;

pub struct AssetApiService { db: Surreal<Client>, delete_db: Surreal<Client> }
const CATALOG_FIELDS: &str = "id, type, name, emotion, url, display_name, episode_id, preview_data, version, preview_status, preview_source_version";
fn text(row: &Value, field: &str) -> String { row[field].as_str().unwrap_or_default().to_owned() }
fn internal(error: impl std::fmt::Display) -> Status { Status::internal(error.to_string()) }

// Читаю байты напрямую, без преобразования через JSON или base64
#[derive(Debug, SurrealValue)]
struct AssetRow {
    id: RecordId,
    r#type: String,
    name: String,
    emotion: Option<String>,
    url: String,
    display_name: String,
    episode_id: Option<RecordId>,
    version: Option<String>,
    file_data: Option<Bytes>,
    preview_data: Option<Bytes>,
    variants: Option<Vec<asset_preview::Variant>>,
    preview_status: Option<String>,
    preview_source_version: Option<String>,
}

fn asset(row: &AssetRow, original: bool) -> Result<Asset, Status> {
    Ok(Asset {
        id: row.id.to_sql(), r#type: row.r#type.clone(), name: row.name.clone(),
        emotion: row.emotion.clone().unwrap_or_default(), url: row.url.clone(), display_name: row.display_name.clone(),
        episode_id: row.episode_id.as_ref().map(ToSql::to_sql).unwrap_or_default(),
        version: row.version.clone().unwrap_or_default(), preview_data: row.preview_data.as_ref().map(|b| b.to_vec()).unwrap_or_default(),
        file_data: if original { row.file_data.as_ref().map(|b| b.to_vec()).unwrap_or_default() } else { Vec::new() },
        variant: if original { "original".into() } else { String::new() },
        width: 0, height: 0, mime: String::new(), byte_length: 0,
    })
}

impl AssetApiService {
    pub fn new(db: Surreal<Client>) -> Self { Self { delete_db:db.clone(), db } }
    // Передаю отдельное подключение для удаления
    pub fn with_delete_db(mut self, db: Surreal<Client>) -> Self { self.delete_db=db; self }

    // До запуска каталога обрабатываю старые записи порциями, оригиналы не меняю
    pub async fn backfill_previews(&self) -> Result<(), Status> {
        let mut cursor = String::new();
        loop {
            let mut response = self.db.query(format!("SELECT {CATALOG_FIELDS} FROM asset WHERE type IN ['background','character'] AND (preview_data=NONE OR bytes::len(preview_data)=0 OR (type='character' AND (preview_status ?? '') != 'ready')) AND (preview_status ?? '') NOT IN ['invalid','missing'] AND ($cursor='' OR id > type::record($cursor)) ORDER BY id LIMIT 24"))
                .bind(("cursor",cursor.clone())).await.map_err(internal)?.check().map_err(internal)?;
            let rows: Vec<AssetRow> = response.take(0).map_err(internal)?;
            if rows.is_empty() { break; }
            for row in rows {
                cursor = row.id.to_sql();
                self.preview(row).await?;
            }
        }
        Ok(())
    }

    // Для старых ассетов создаю варианты один раз, новый upload готовит их до записи
    async fn prepare_variants(&self, id: &str) -> Result<(), Status> {
        let mut response = self.db.query("SELECT id,type,name,emotion,url,display_name,episode_id,version,file_data FROM type::record($id)")
            .bind(("id", id.to_owned())).await.map_err(internal)?.check().map_err(internal)?;
        let row: Option<AssetRow> = response.take(0).map_err(internal)?;
        let row = row.ok_or_else(|| Status::not_found("Ассет не найден"))?;
        let source = row.file_data.ok_or_else(|| Status::not_found("Нет изображения"))?;
        let prepared = asset_preview::make_variants(source.to_vec(), &row.r#type).await?;
        self.db.query("UPDATE type::record($id) SET variants=$variants, preview_data=$preview, version=$version, preview_status='ready', preview_source_version=$version WHERE file_data=$source AND (variants=NONE OR array::len(variants)=0)")
            .bind(("id", id.to_owned())).bind(("source", source)).bind(("variants", prepared.variants))
            .bind(("preview", Bytes::from(prepared.preview))).bind(("version", prepared.version))
            .await.map_err(internal)?.check().map_err(internal)?;
        Ok(())
    }

    pub fn into_server(self) -> asset_api_server::AssetApiServer<Self> {
        asset_api_server::AssetApiServer::new(self)
            .max_decoding_message_size(MAX_MESSAGE_BYTES)
            .max_encoding_message_size(MAX_MESSAGE_BYTES)
    }

    // Старый оригинал читаю только тогда, когда записи нужно превью
    async fn preview(&self, mut row: AssetRow) -> Result<AssetRow, Status> {
        // Исправляю также JPEG-превью персонажей, созданные старой версией сервера
        let old_jpeg = row.r#type == "character" && row.preview_data.as_ref()
            .is_some_and(|bytes| image::guess_format(bytes).ok() == Some(image::ImageFormat::Jpeg));
        if row.preview_data.as_ref().is_some_and(|bytes| !bytes.is_empty()) && !old_jpeg { return Ok(row); }
        if !matches!(row.r#type.as_str(), "background" | "character") { return Ok(row); }
        if matches!(row.preview_status.as_deref(),Some("invalid" | "missing")) && row.preview_source_version == row.version { return Ok(row); }
        let id = row.id.to_sql();
        let mut response = self.db.query("SELECT * FROM type::record($id)")
            .bind(("id", id.clone())).await.map_err(internal)?.check().map_err(internal)?;
        let full: Option<AssetRow> = response.take(0).map_err(internal)?;
        let Some(full) = full else { return Ok(row); };
        let source = full.file_data;
        let data = source.as_ref().map(|bytes|bytes.to_vec()).unwrap_or_default();
        use sha2::{Digest, Sha256}; // Подключаю версию исходных байтов
        let source_version = format!("{:x}",Sha256::digest(&data));
        let prepared = if data.is_empty() { None } else { Some(asset_preview::make(data).await) };
        let (preview, version, status) = match prepared {
            Some(Ok((preview,version))) => (Some(Bytes::from(preview)),version,"ready"),
            Some(Err(error)) if error.code() != tonic::Code::InvalidArgument => return Err(error),
            Some(Err(_)) => (None,source_version,"invalid"),
            None => (None,source_version,"missing"),
        };
        // Не затираю картинку, которую успели заменить во время обработки
        self.db.query("UPDATE type::record($id) SET preview_data=$preview, version=$version, preview_status=$status, preview_source_version=$version WHERE file_data=$source AND preview_data=$previous")
            .bind(("id", id.clone())).bind(("preview", preview)).bind(("status",status))
            .bind(("version", version)).bind(("source", source)).bind(("previous", full.preview_data))
            .await.map_err(internal)?.check().map_err(internal)?;
        let mut response = self.db.query(format!("SELECT {CATALOG_FIELDS} FROM type::record($id)"))
            .bind(("id", id)).await.map_err(internal)?.check().map_err(internal)?;
        if let Some(current) = response.take::<Option<AssetRow>>(0).map_err(internal)? { row = current; }
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
        let mut rows: Vec<AssetRow> = response.take(0).map_err(internal)?;
        let more = rows.len() > limit;
        rows.truncate(limit);
        let next_cursor = if more { rows.last().map(|row| row.id.to_sql()).unwrap_or_default() } else { String::new() };
        // Обрабатываю не больше четырёх старых картинок одновременно
        let mut pending = rows.into_iter().enumerate();
        let mut jobs = tokio::task::JoinSet::new();
        let launch = |jobs: &mut tokio::task::JoinSet<Result<(usize, AssetRow), Status>>, index, row| {
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
        if !matches!(req.variant.as_str(), "" | "original" | "screen") || req.target_width < 0 || req.target_height < 0 {
            return Err(Status::invalid_argument("Неверный вариант или размер изображения"));
        }
        if req.id.is_empty() && (req.name.is_empty() || req.r#type.is_empty()) {
            return Err(Status::invalid_argument("Нужен ID или имя ассета с типом"));
        }
        if !req.id.is_empty() && !req.id.starts_with("asset:") { return Err(Status::invalid_argument("Неверный ID ассета")); }
        let screen = req.variant == "screen" && !req.metadata_only;
        let metadata = "id,type,name,emotion,url,display_name,episode_id,version";
        let fields = if req.metadata_only { metadata.to_owned() } else if screen {
            format!("{metadata},array::map(variants ?? [], |$v| {{name:$v.name,width:$v.width,height:$v.height,mime:$v.mime,byte_length:$v.byte_length,hash:$v.hash}}) AS variants")
        } else { format!("{metadata},file_data,preview_data") };
        let mut response = self.db.query(format!("SELECT {fields} FROM asset WHERE ($id != '' AND id = type::record($id)) OR ($id = '' AND type = $type AND name = $name AND (emotion ?? '') = $emotion AND ($ep = '' OR episode_id = type::record($ep) OR episode_id = NONE)) ORDER BY episode_id DESC, id LIMIT 1"))
            .bind(("id", req.id)).bind(("type", req.r#type)).bind(("name", req.name))
            .bind(("emotion", req.emotion)).bind(("ep", req.episode_id))
            .await.map_err(internal)?.check().map_err(internal)?;
        let mut rows: Vec<AssetRow> = response.take(0).map_err(internal)?;
        let row = rows.first_mut().ok_or_else(|| Status::not_found("Ассет не найден"))?;
        if screen {
            let id = row.id.to_sql();
            if row.variants.as_ref().is_none_or(|items| items.is_empty()) {
                self.prepare_variants(&id).await?;
                let mut result = self.db.query("SELECT VALUE array::map(variants ?? [], |$v| {name:$v.name,width:$v.width,height:$v.height,mime:$v.mime,byte_length:$v.byte_length,hash:$v.hash}) FROM ONLY type::record($id)")
                    .bind(("id", id.clone())).await.map_err(internal)?.check().map_err(internal)?;
                row.variants = Some(result.take(0).map_err(internal)?);
                let mut result = self.db.query("SELECT VALUE version FROM ONLY type::record($id)").bind(("id", id.clone()))
                    .await.map_err(internal)?.check().map_err(internal)?;
                row.version = result.take(0).map_err(internal)?;
            }
            let variants = row.variants.as_ref().unwrap();
            let target_width = req.target_width.max(1);
            let target_height = req.target_height.max(1);
            let enough = |v: &&asset_preview::Variant| if row.r#type == "background" {
                v.width >= target_width && v.height >= target_height
            } else { v.width.max(v.height) >= target_width.max(target_height) };
            let selected = variants.iter().filter(enough).min_by_key(|v| i64::from(v.width)*i64::from(v.height))
                .or_else(|| variants.iter().max_by_key(|v| i64::from(v.width)*i64::from(v.height)))
                .ok_or_else(|| Status::not_found("Нет размера для экрана"))?;
            let mut result = self.db.query("SELECT VALUE variants[WHERE name=$name][0] FROM ONLY type::record($id) WHERE version=$version")
                .bind(("id", id)).bind(("name", selected.name.clone())).bind(("version", row.version.clone()))
                .await.map_err(internal)?.check().map_err(internal)?;
            let variant: Option<asset_preview::Variant> = result.take(0).map_err(internal)?;
            let variant = variant.ok_or_else(|| Status::aborted("Картинка изменилась, повторите загрузку"))?;
            let mut response = asset(row, false)?;
            response.file_data = variant.data.ok_or_else(|| Status::internal("Нет данных варианта"))?.to_vec();
            response.variant = variant.name;
            response.width = variant.width; response.height = variant.height;
            response.mime = variant.mime; response.byte_length = variant.byte_length;
            return Ok(Response::new(response));
        }
        Ok(Response::new(asset(row, !req.metadata_only)?))
    }

    async fn upload_asset(&self, request: Request<UploadAssetRequest>) -> Result<Response<UploadAssetResponse>, Status> {
        crate::request_auth::check_current_admin(&request, &self.db).await?;
        let req = request.into_inner();
        if !matches!(req.r#type.as_str(), "background" | "character") || req.name.is_empty() || req.file_data.is_empty() {
            return Err(Status::invalid_argument("Нужны тип, имя и изображение"));
        }
        if req.file_data.len() > MAX_UPLOAD_BYTES { return Err(Status::invalid_argument("Файл больше 5 MiB (5 242 880 байт)")); }
        // Проверяю метаданные до обработки изображения и записи в БД.
        if req.name.len() > 256 || req.emotion.len() > 128 || req.display_name.len() > 512 || req.episode_id.len() > 128
            || (!req.episode_id.is_empty() && !req.episode_id.starts_with("episode:")) {
            return Err(Status::invalid_argument("Неверные или слишком длинные данные ассета"));
        }
        let prepared = asset_preview::make_variants(req.file_data.clone(), &req.r#type).await?;
        let mut response = self.db.query("SELECT id FROM asset WHERE type = $type AND name = $name AND (emotion ?? '') = $emotion AND episode_id = (IF $ep = '' { NONE } ELSE { type::record($ep) }) LIMIT 1")
            .bind(("type", req.r#type.clone())).bind(("name", req.name.clone()))
            .bind(("emotion", req.emotion.clone())).bind(("ep", req.episode_id.clone()))
            .await.map_err(internal)?.check().map_err(internal)?;
        let rows: Vec<Value> = response.take(0).map_err(internal)?;
        let id = rows.first().map(|row| text(row, "id")).unwrap_or_else(|| format!("asset:{}", uuid::Uuid::new_v4().simple()));
        let display = if req.display_name.is_empty() { req.name.clone() } else { req.display_name };
        let url = format!("assets/{}/{}", req.r#type, req.name);
        // Оригинал и превью заменяю одной записью
        let mut response = self.db.query("UPSERT type::record($id) MERGE {type:$type, name:$name, emotion:(IF $emotion='' { NONE } ELSE { $emotion }), episode_id:(IF $ep='' { NONE } ELSE { type::record($ep) }), url:$url, display_name:$display, file_data:$file, preview_data:$preview, version:$version, variants:$variants, preview_status:'ready', preview_source_version:$version} RETURN AFTER")
            .bind(("id", id)).bind(("type", req.r#type)).bind(("name", req.name)).bind(("emotion", req.emotion))
            .bind(("ep", req.episode_id)).bind(("url", url)).bind(("display", display))
            .bind(("file", Bytes::from(req.file_data))).bind(("preview", Bytes::from(prepared.preview))).bind(("version", prepared.version))
            .bind(("variants", prepared.variants))
            .await.map_err(internal)?.check().map_err(internal)?;
        let rows: Vec<AssetRow> = response.take(0).map_err(internal)?;
        let row = rows.first().ok_or_else(|| Status::internal("Ассет не сохранён"))?;
        Ok(Response::new(UploadAssetResponse { success: true, message: "Ассет сохранён".into(), asset: Some(asset(row, false)?) }))
    }

    async fn delete_asset(&self, request: Request<DeleteAssetRequest>) -> Result<Response<DeleteAssetResponse>, Status> {
        crate::request_auth::check_admin(&request)?;
        crate::asset_delete::asset_id(&request.get_ref().id)?;
        crate::request_auth::check_current_admin(&request, &self.db).await?;
        let id = request.into_inner().id;
        crate::asset_delete::delete(&self.delete_db, &id).await?;
        Ok(Response::new(DeleteAssetResponse { success: true, message: "Ассет удалён".into() }))
    }
}

#[cfg(test)]
#[path = "asset_tests.rs"]
mod tests;