use super::*;
use crate::jwt::Claims;
use image::{DynamicImage, RgbaImage, Rgba, ImageFormat};
use std::{collections::HashSet, io::Cursor};
use surrealdb::{engine::remote::ws::Ws, opt::auth::Root};
type TestResult<T> = Result<T, Box<dyn std::error::Error + Send + Sync>>;

fn picture(seed: u8) -> Vec<u8> {
    let image = RgbaImage::from_fn(640, 480, |x, y| Rgba([
        (x.wrapping_mul(73) + y.wrapping_mul(19)) as u8 ^ seed,
        (x.wrapping_mul(11) + y.wrapping_mul(47)) as u8, seed, 120,
    ]));
    let mut bytes = Cursor::new(Vec::new());
    DynamicImage::ImageRgba8(image).write_to(&mut bytes, ImageFormat::Png).unwrap();
    bytes.into_inner()
}
fn admin<T>(body: T) -> Request<T> {
    let mut req = Request::new(body);
    req.extensions_mut().insert(Claims { sub: "player:test".into(), login: "test".into(), is_admin: true, exp: usize::MAX });
    req
}
fn page(cursor: String, limit: i32) -> Request<GetAssetsRequest> {
    Request::new(GetAssetsRequest { r#type: "background".into(), episode_id: "episode:1".into(), cursor, limit })
}

#[tokio::test]
async fn preview_is_small_and_keeps_transparency() {
    let bytes = picture(12);
    let (preview, version) = asset_preview::make(bytes.clone()).await.unwrap();
    assert!(preview.len() <= asset_preview::MAX_PREVIEW_BYTES);
    assert!(preview.len() < bytes.len());
    let decoded = image::load_from_memory(&preview).unwrap().into_rgba8();
    assert!(decoded.width() <= 160 && decoded.height() <= 160);
    assert!(decoded.pixels().any(|p| p.0[3] < 255));
    assert_eq!(asset_preview::make(bytes).await.unwrap().1, version);
    assert_ne!(asset_preview::make(picture(13)).await.unwrap().1, version);
    assert!(asset_preview::make(b"invalid image".to_vec()).await.is_err());
}

#[tokio::test]
async fn crosswalk_preview_limits_decoded_pixels() {
    let path = concat!(env!("CARGO_MANIFEST_DIR"), "/../assets/images/ep1/crosswalk.png");
    let original = std::fs::read(path).unwrap();
    let full = image::load_from_memory(&original).unwrap();
    let original_rgba_bytes = u64::from(full.width()) * u64::from(full.height()) * 4;
    assert!(original_rgba_bytes > 4 * 1024 * 1024);
    let (bytes, _) = asset_preview::make(original).await.unwrap();
    let preview = image::load_from_memory(&bytes).unwrap().into_rgba8();
    assert!(preview.width() <= 160 && preview.height() <= 160);
    assert!(preview.as_raw().len() <= 160 * 160 * 4);
    assert!((preview.as_raw().len() as u64) < original_rgba_bytes);
}

async fn scenarios(db: Surreal<Client>) -> TestResult<()> {
    crate::apply_migrations(&db).await.map_err(|e| e.to_string())?;
    let original = picture(1);
    db.query("FOR $n IN 0..55 { CREATE type::record('asset', 'old_' + <string>$n) CONTENT {type:'background',name:'old_' + <string>$n,url:'test',display_name:'Same name',episode_id:(IF $n=54 {episode:2} ELSE {NONE}),file_data:$file}; };")
        .bind(("file", STANDARD.encode(&original))).await?.check()?;
    let api = AssetApiService::new(db.clone());
    let first = api.get_assets(page(String::new(), 5)).await?.into_inner();
    assert_eq!(first.assets.len(), 5);
    assert!(!first.next_cursor.is_empty());
    let mut count = db.query("SELECT count() AS n FROM asset WHERE preview_data != NONE GROUP ALL;").await?.check()?;
    let counts: Vec<Value> = count.take(0)?;
    assert_eq!(counts[0]["n"], 5, "Создаю превью только запрошенной страницы");
    let mut seen = HashSet::new();
    let mut current = first;
    loop {
        assert!(current.assets.len() <= 5);
        for asset in &current.assets {
            assert!(seen.insert(asset.id.clone()), "Страницы не должны повторять ассеты");
            assert!(asset.file_data.is_empty());
            assert!(!asset.preview_data.is_empty());
            assert!(asset.preview_data.len() <= asset_preview::MAX_PREVIEW_BYTES);
            assert!(!asset.version.is_empty());
        }
        if current.next_cursor.is_empty() { break; }
        current = api.get_assets(page(current.next_cursor, 5)).await?.into_inner();
    }
    assert_eq!(seen.len(), 54, "Ассет другого эпизода не попадает в список");
    assert_eq!(api.get_assets(page(String::new(), 1000)).await?.into_inner().assets.len(), 24);
    assert_eq!(api.get_assets(page(String::new(), 0)).await?.into_inner().assets.len(), 24);
    assert_eq!(api.get_assets(page(String::new(), -1)).await.unwrap_err().code(), tonic::Code::InvalidArgument);
    let selected = api.get_asset(Request::new(GetAssetRequest { r#type:"background".into(), name:"old_1".into(), ..Default::default() })).await?.into_inner();
    assert_eq!(selected.file_data, original, "Оригинал сохраняется без изменений");
    let metadata = api.get_asset(Request::new(GetAssetRequest { r#type:"background".into(), name:"old_1".into(), metadata_only:true, ..Default::default() })).await?.into_inner();
    assert_eq!(metadata.id, selected.id);
    assert_eq!(metadata.version, selected.version);
    assert!(metadata.file_data.is_empty() && metadata.preview_data.is_empty());
    let replaced = picture(2);
    let upload = api.upload_asset(admin(UploadAssetRequest {
        r#type:"background".into(),name:"old_1".into(),file_data:replaced.clone(), ..Default::default()
    })).await?.into_inner().asset.unwrap();
    assert_eq!(upload.id, selected.id);
    assert_ne!(upload.version, selected.version);
    assert!(!upload.preview_data.is_empty());
    let full = api.get_asset(Request::new(GetAssetRequest { id: upload.id.clone(), ..Default::default() })).await?.into_inner();
    assert_eq!(full.file_data, replaced);
    assert_eq!(full.version, upload.version);
    let scoped = api.upload_asset(admin(UploadAssetRequest {
        r#type:"background".into(),name:"old_1".into(),episode_id:"episode:3".into(),file_data:picture(3), ..Default::default()
    })).await?.into_inner().asset.unwrap();
    assert_ne!(scoped.id, upload.id);
    assert_eq!(scoped.episode_id, "episode:3");
    let chosen = api.get_asset(Request::new(GetAssetRequest {r#type:"background".into(),name:"old_1".into(),episode_id:"episode:3".into(), ..Default::default()})).await?.into_inner();
    assert_eq!(chosen.id, scoped.id);
    // Одинаковые имена в разных эпизодах и общей библиотеке независимы
    let other = api.upload_asset(admin(UploadAssetRequest {
        r#type:"background".into(),name:"old_1".into(),episode_id:"episode:4".into(),file_data:picture(4), ..Default::default()
    })).await?.into_inner().asset.unwrap();
    assert_ne!(other.id, scoped.id);
    assert_ne!(other.id, upload.id);
    assert_eq!(other.episode_id, "episode:4");
    let updated = api.upload_asset(admin(UploadAssetRequest {
        r#type:"background".into(),name:"old_1".into(),episode_id:"episode:3".into(),file_data:picture(5), ..Default::default()
    })).await?.into_inner().asset.unwrap();
    assert_eq!(updated.id, scoped.id);
    assert_eq!(updated.episode_id, "episode:3");
    assert_ne!(updated.version, scoped.version);
    for (id, episode, bytes) in [
        (upload.id.clone(), "", replaced.clone()),
        (other.id.clone(), "episode:4", picture(4)),
        (updated.id.clone(), "episode:3", picture(5)),
    ] {
        let saved = api.get_asset(Request::new(GetAssetRequest { id, ..Default::default() })).await?.into_inner();
        assert_eq!(saved.episode_id, episode);
        assert_eq!(saved.file_data, bytes);
    }
    let filtered = api.get_assets(Request::new(GetAssetsRequest {
        r#type:"background".into(),episode_id:"episode:4".into(),limit:24, ..Default::default()
    })).await?.into_inner();
    assert!(filtered.assets.iter().all(|a| a.episode_id.is_empty() || a.episode_id == "episode:4"));
    let exact = api.get_asset(Request::new(GetAssetRequest {
        r#type:"background".into(),name:"old_1".into(),episode_id:"episode:4".into(), ..Default::default()
    })).await?.into_inner();
    assert_eq!(exact.id, other.id);
    api.delete_asset(admin(DeleteAssetRequest {id: upload.id.clone()})).await?;
    assert_eq!(api.get_asset(Request::new(GetAssetRequest {id: upload.id, ..Default::default()})).await.unwrap_err().code(), tonic::Code::NotFound);
    grpc_upload_limits(db).await?;
    Ok(())
}

#[tokio::test]
#[ignore = "Нужна локальная SurrealDB; проверяю каталог и оригиналы в отдельной БД"]
async fn paged_previews_and_selected_original() -> TestResult<()> {
    let db = Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
    let name = format!("asset_test_{}",uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club").await?;
    db.query(format!("DEFINE DATABASE {name};")).await?.check()?;
    db.use_db(&name).await?;
    let result = tokio::spawn(scenarios(db.clone())).await;
    db.query(format!("REMOVE DATABASE {name};")).await?.check()?;
    result?
}

// Проверяю размер по настоящему gRPC, с теми же лимитами, что в main
async fn grpc_upload_limits(db: Surreal<Client>) -> TestResult<()> {
    use crate::romance_club::asset_api_client::AssetApiClient;
    use tonic::{transport::Server, service::interceptor::InterceptedService};
    let listener = std::net::TcpListener::bind("127.0.0.1:0")?;
    let addr = listener.local_addr()?;
    drop(listener);
    let jwt = crate::jwt::JwtKeys::from_secret("asset-size-test-key-only-0123456789")?;
    let token = jwt.create_token("player:test", "test", true)?;
    let service = InterceptedService::new(AssetApiService::new(db.clone()).into_server(), crate::AuthInterceptor { jwt });
    let (shutdown, stopped) = tokio::sync::oneshot::channel();
    let server = tokio::spawn(Server::builder().add_service(service).serve_with_shutdown(addr, async { let _ = stopped.await; }));
    let result: TestResult<()> = async {
        let endpoint = format!("http://{addr}");
        let mut client = loop {
            match AssetApiClient::connect(endpoint.clone()).await {
                Ok(client) => break client.max_decoding_message_size(MAX_MESSAGE_BYTES),
                Err(_) if !server.is_finished() => tokio::time::sleep(std::time::Duration::from_millis(10)).await,
                Err(error) => return Err(error.into()),
            }
        };
        for size in [4 * 1024 * 1024 + 512 * 1024, MAX_UPLOAD_BYTES] {
            let mut bytes = picture(7);
            bytes.resize(size, 0);
            let mut request = Request::new(UploadAssetRequest {
                r#type: "background".into(), name: format!("large_{size}"),
                episode_id: "episode:9".into(), file_data: bytes.clone(), ..Default::default()
            });
            request.metadata_mut().insert("authorization", format!("Bearer {token}").parse()?);
            let uploaded = client.upload_asset(request).await?.into_inner().asset.unwrap();
            assert!(uploaded.file_data.is_empty(), "После загрузки возвращаю метаданные без копии оригинала");
            assert_eq!(uploaded.episode_id, "episode:9");
            let mut request = Request::new(GetAssetRequest { id: uploaded.id, ..Default::default() });
            request.metadata_mut().insert("authorization", format!("Bearer {token}").parse()?);
            assert!(client.get_asset(request).await?.into_inner().file_data == bytes, "Оригинал должен вернуться без изменений");
        }
        let mut request = Request::new(UploadAssetRequest {
            r#type: "background".into(), name: "too_large".into(),
            file_data: vec![0; MAX_UPLOAD_BYTES + 1], ..Default::default()
        });
        request.metadata_mut().insert("authorization", format!("Bearer {token}").parse()?);
        let error = client.upload_asset(request).await.unwrap_err();
        assert_eq!(error.code(), tonic::Code::InvalidArgument);
        assert!(error.message().contains("5 MiB"), "Отказ должен прийти из проверки размера файла");
        let mut request = Request::new(UploadAssetRequest {
            r#type: "background".into(), name: "transport_limit".into(),
            file_data: vec![0; MAX_MESSAGE_BYTES + 1], ..Default::default()
        });
        request.metadata_mut().insert("authorization", format!("Bearer {token}").parse()?);
        assert_eq!(client.upload_asset(request).await.unwrap_err().code(), tonic::Code::OutOfRange);
        let mut response = db.query("SELECT * FROM asset WHERE name IN ['too_large', 'transport_limit'];").await?.check()?;
        let rows: Vec<Value> = response.take(0)?;
        assert!(rows.is_empty());
        Ok(())
    }.await;
    let _ = shutdown.send(());
    server.await??;
    result
}