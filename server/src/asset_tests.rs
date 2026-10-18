use super::*;
use base64::{Engine as _, engine::general_purpose::STANDARD};
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

fn png_chunk(kind: &[u8; 4], data: &[u8]) -> Vec<u8> {
    let mut result = (data.len() as u32).to_be_bytes().to_vec();
    result.extend_from_slice(kind);
    result.extend_from_slice(data);
    let mut crc = u32::MAX;
    for &byte in &result[4..] {
        crc ^= u32::from(byte);
        for _ in 0..8 { crc = (crc >> 1) ^ (0xedb88320u32.wrapping_mul(crc & 1)); }
    }
    result.extend_from_slice(&(!crc).to_be_bytes());
    result
}

fn animated_png() -> Vec<u8> {
    let png = picture(10);
    let mut result = png[..33].to_vec();
    result.extend_from_slice(&png_chunk(b"acTL", &[0,0,0,2,0,0,0,0]));
    result.extend_from_slice(&png[33..]);
    result
}

fn too_many_pixels() -> Vec<u8> {
    let image = image::GrayImage::new(4001, 4000);
    let mut output = Cursor::new(Vec::new());
    DynamicImage::ImageLuma8(image).write_to(&mut output, ImageFormat::Png).unwrap();
    output.into_inner()
}

#[tokio::test]
async fn reject_invalid_oversized_and_animated_images_before_variants() {
    for bytes in [b"not an image".to_vec(), b"GIF89a".to_vec(), picture(1)[..40].to_vec()] {
        assert_eq!(asset_preview::make_variants(bytes,"background").await.err().unwrap().code(), tonic::Code::InvalidArgument);
    }
    let pixels = too_many_pixels();
    assert!(pixels.len() < MAX_UPLOAD_BYTES);
    let error = asset_preview::make_variants(pixels,"background").await.err().unwrap();
    assert_eq!(error.code(), tonic::Code::InvalidArgument);
    assert!(error.message().contains("16 000 000"));
    let png = picture(1);
    for (width,height) in [(8193u32,1u32),(1,8193)] {
        let mut data = png[16..29].to_vec();
        data[..4].copy_from_slice(&width.to_be_bytes());
        data[4..8].copy_from_slice(&height.to_be_bytes());
        let mut large = png[..8].to_vec();
        large.extend_from_slice(&png_chunk(b"IHDR",&data));
        large.extend_from_slice(&png[33..]);
        let error = asset_preview::make_variants(large,"background").await.err().unwrap();
        assert_eq!(error.code(), tonic::Code::InvalidArgument);
        assert!(error.message().contains("8192"));
    }
    let error = asset_preview::make_variants(animated_png(),"character").await.err().unwrap();
    assert_eq!(error.code(), tonic::Code::InvalidArgument);
    assert!(error.message().contains("кадром"));
    let mut header = png[16..29].to_vec();
    header[..4].copy_from_slice(&4000u32.to_be_bytes());
    header[4..8].copy_from_slice(&3000u32.to_be_bytes());
    header[8] = 16;
    let mut deep = png[..8].to_vec();
    deep.extend_from_slice(&png_chunk(b"IHDR", &header));
    deep.extend_from_slice(&png[33..]);
    let error = asset_preview::make_variants(deep,"character").await.err().unwrap();
    assert_eq!(error.code(), tonic::Code::InvalidArgument);
    assert!(error.message().contains("64 MiB"));
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

#[tokio::test]
async fn screen_sizes_preserve_alpha_and_do_not_enlarge_images() {
    let source = picture(20);
    let prepared = asset_preview::make_variants(source.clone(), "character").await.unwrap();
    assert_eq!(prepared.variants.len(), 2);
    for variant in &prepared.variants {
        let data = variant.data.as_ref().unwrap();
        let image = image::load_from_memory(data).unwrap().into_rgba8();
        assert_eq!((image.width(), image.height()), (variant.width as u32, variant.height as u32));
        assert_eq!(variant.byte_length as usize, data.len());
        assert_eq!(variant.mime, "image/png");
        assert!(image.pixels().any(|pixel| pixel.0[3] < 255));
        assert!(image.width() <= 640 && image.height() <= 480);
    }
    assert_eq!(prepared.variants[0].width, 512);
    assert_eq!(prepared.variants[1].width, 640);
    let source = std::fs::read(concat!(env!("CARGO_MANIFEST_DIR"), "/../assets/images/ep1/crosswalk.png")).unwrap();
    let prepared = asset_preview::make_variants(source.clone(), "background").await.unwrap();
    assert_eq!(prepared.variants[0].width, 720);
    assert!(prepared.variants.iter().all(|v| v.width <= 915));
    // Если исходник меньше нового размера, не создаю одинаковые копии
    assert_eq!(prepared.variants.len(), 2);
    assert!(prepared.variants[0].data.as_ref().unwrap().len() < source.len());
    assert!(asset_preview::make_variants(b"broken".to_vec(), "background").await.is_err());
}

#[tokio::test]
async fn screen_and_preview_apply_exif_orientation() {
    let image = image::RgbImage::from_pixel(16, 8, image::Rgb([20,40,60]));
    let mut jpeg = Vec::new();
    image::codecs::jpeg::JpegEncoder::new(&mut jpeg).encode_image(&image).unwrap();
    let mut rotated = jpeg[..2].to_vec();
    // EXIF Orientation=6: поворот на 90 градусов
    let exif = [b'E',b'x',b'i',b'f',0,0,b'I',b'I',42,0,8,0,0,0,1,0,0x12,1,3,0,1,0,0,0,6,0,0,0,0,0,0,0];
    rotated.extend_from_slice(&[0xff,0xe1,0,34]);
    rotated.extend_from_slice(&exif);
    rotated.extend_from_slice(&jpeg[2..]);
    let prepared = asset_preview::make_variants(rotated, "character").await.unwrap();
    assert_eq!((prepared.variants[0].width, prepared.variants[0].height), (8,16));
    let preview = image::load_from_memory(&prepared.preview).unwrap();
    assert_eq!((preview.width(),preview.height()),(8,16));
}

async fn scenarios(db: Surreal<Client>) -> TestResult<()> {
    // Старые строки переношу без изменения байтов, ключей и метаданных
    db.query(include_str!("../migrations/009_asset.surql")).await?.check()?;
    db.query(include_str!("../migrations/010_asset_file.surql")).await?.check()?;
    db.query(include_str!("../migrations/015_asset_previews.surql")).await?.check()?;
    let mut legacy = picture(9);
    // Старые строки содержат завершающие знаки =, SurrealDB кодирует без них
    while legacy.len() % 3 != 1 { legacy.push(0); }
    let (thumb, version) = asset_preview::make(legacy.clone()).await?;
    db.query("CREATE asset:migrate CONTENT {type:'background',name:'legacy',url:'old',display_name:'Legacy',file_data:$file,preview_data:$preview,version:$version};")
        .bind(("file", STANDARD.encode(&legacy))).bind(("preview", STANDARD.encode(&thumb)))
        .bind(("version", version.clone())).await?.check()?;
    db.query(include_str!("../migrations/018_asset_bytes.surql")).await?.check()?;
    db.query(include_str!("../migrations/018_asset_bytes.surql")).await?.check()?;
    let mut result = db.query("SELECT * FROM asset:migrate;").await?.check()?;
    let migrated: Option<AssetRow> = result.take(0)?;
    let migrated = migrated.unwrap();
    assert_eq!(migrated.file_data.unwrap().to_vec(), legacy);
    assert_eq!(migrated.preview_data.unwrap().to_vec(), thumb);
    assert_eq!(migrated.version.as_deref(), Some(version.as_str()));
    // Повреждённая строка останавливает перенос целиком
    db.query("DEFINE FIELD OVERWRITE file_data ON asset TYPE option<string | bytes>; CREATE asset:bad CONTENT {type:'background',name:'bad',url:'bad',display_name:'Bad',file_data:'not-base64'};").await?.check()?;
    assert!(db.query(include_str!("../migrations/018_asset_bytes.surql")).await?.check().is_err());
    let mut result = db.query("SELECT VALUE file_data FROM asset:bad;").await?.check()?;
    assert_eq!(result.take::<Vec<String>>(0)?, vec!["not-base64"]);
    db.query("DELETE asset:bad; DELETE asset:migrate;").await?.check()?;
    crate::apply_migrations(&db).await.map_err(|e| e.to_string())?;
    let original = picture(1);
    db.query("FOR $n IN 0..55 { CREATE type::record('asset', 'old_' + <string>$n) CONTENT {type:'background',name:'old_' + <string>$n,url:'test',display_name:'Same name',episode_id:(IF $n=54 {episode:2} ELSE {NONE}),file_data:$file}; };")
        .bind(("file", Bytes::from(original.clone()))).await?.check()?;
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
    let mut stored = db.query("SELECT * FROM type::record($id);").bind(("id", upload.id.clone())).await?.check()?;
    let stored: Option<AssetRow> = stored.take(0)?;
    let stored = stored.unwrap();
    assert_eq!(stored.file_data.unwrap().to_vec(), replaced);
    assert_eq!(stored.preview_data.unwrap().to_vec(), upload.preview_data);
    assert!(!stored.variants.unwrap().is_empty());
    let screen_request = || Request::new(GetAssetRequest { id:upload.id.clone(), variant:"screen".into(), target_width:320, target_height:240, ..Default::default() });
    let screen = api.get_asset(screen_request()).await?.into_inner();
    assert!(screen.width > 0 && screen.width <= 640);
    assert!(screen.height > 0 && screen.height <= 480);
    assert!(!screen.variant.is_empty());
    assert_eq!(screen.byte_length as usize, screen.file_data.len());
    let repeated = api.get_asset(screen_request()).await?.into_inner();
    assert_eq!(screen.file_data, repeated.file_data);
    assert_eq!(screen.version, repeated.version);
    db.query("DEFINE EVENT fail_variant_publish ON asset WHEN $event='UPDATE' THEN { THROW 'publish_refused'; };").await?.check()?;
    assert!(api.upload_asset(admin(UploadAssetRequest { r#type:"background".into(),name:"old_1".into(),file_data:picture(8),..Default::default() })).await.is_err());
    db.query("REMOVE EVENT fail_variant_publish ON asset;").await?.check()?;
    let unchanged = api.get_asset(screen_request()).await?.into_inner();
    assert_eq!(unchanged.file_data, screen.file_data);
    assert_eq!(unchanged.version, screen.version);
    let original = api.get_asset(Request::new(GetAssetRequest {id:upload.id.clone(),..Default::default()})).await?.into_inner();
    assert_eq!(original.file_data, replaced);
    // Старый ассет обрабатываю один раз, затем возвращаю сохранённый размер
    let old = api.get_asset(Request::new(GetAssetRequest { r#type:"background".into(),name:"old_2".into(),variant:"screen".into(),target_width:300,target_height:300,..Default::default() })).await?.into_inner();
    assert!(!old.file_data.is_empty());
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
        // Прямой RPC тоже проверяет содержимое, независимо от расширения файла
        let compressed = too_many_pixels();
        for bytes in [b"not an image".to_vec(), picture(1)[..40].to_vec(), animated_png(), compressed] {
            let mut request = Request::new(UploadAssetRequest {
                r#type:"background".into(), name:"invalid-content".into(), file_name:"image.png".into(),
                file_data:bytes, ..Default::default()
            });
            request.metadata_mut().insert("authorization",format!("Bearer {token}").parse()?);
            assert_eq!(client.upload_asset(request).await.unwrap_err().code(), tonic::Code::InvalidArgument);
        }
        let mut invalid = db.query("SELECT * FROM asset WHERE name='invalid-content';").await?.check()?;
        assert!(invalid.take::<Vec<AssetRow>>(0)?.is_empty());
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
