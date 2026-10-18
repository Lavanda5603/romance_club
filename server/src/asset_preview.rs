use std::io::Cursor;
use image::{ImageReader, ImageFormat, ImageDecoder, DynamicImage, Limits, metadata::Orientation};
use sha2::{Sha256, Digest};
use surrealdb::types::{Bytes, SurrealValue};
use tonic::Status;

pub const MAX_PREVIEW_BYTES: usize = 24 * 1024;
static WORKERS: tokio::sync::Semaphore = tokio::sync::Semaphore::const_new(2);

#[derive(Clone, Debug, SurrealValue)]
pub struct Variant {
    pub name: String,
    pub width: i32,
    pub height: i32,
    pub mime: String,
    pub byte_length: i32,
    pub hash: String,
    pub data: Option<Bytes>,
}
pub struct Prepared { pub preview: Vec<u8>, pub version: String, pub variants: Vec<Variant> }

pub async fn make(bytes: Vec<u8>) -> Result<(Vec<u8>, String), Status> {
    let result = process(bytes, "", false).await?;
    Ok((result.preview, result.version))
}
pub async fn make_variants(bytes: Vec<u8>, kind: &str) -> Result<Prepared, Status> {
    process(bytes, kind, true).await
}

// Не запускаю больше двух обработок одновременно, включая фоновые задачи
async fn process(bytes: Vec<u8>, kind: &str, screens: bool) -> Result<Prepared, Status> {
    let permit = WORKERS.acquire().await.map_err(|_| Status::unavailable("Обработка изображений остановлена"))?;
    let kind = kind.to_owned();
    tokio::task::spawn_blocking(move || {
        let _permit = permit;
        let version = format!("{:x}", Sha256::digest(&bytes));
        let mut reader = ImageReader::new(Cursor::new(&bytes)).with_guessed_format()
            .map_err(|_| Status::invalid_argument("Не удалось прочитать изображение"))?;
        let format = reader.format();
        let mut limits = Limits::default();
        limits.max_image_width = Some(8192);
        limits.max_image_height = Some(8192);
        limits.max_alloc = Some(64 * 1024 * 1024);
        reader.limits(limits);
        let mut decoder = reader.into_decoder().map_err(|_| Status::invalid_argument("Нужен корректный PNG или JPEG допустимого размера"))?;
        let orientation = decoder.orientation().map_err(|_| Status::invalid_argument("Не удалось прочитать ориентацию изображения"))?;
        let mut image = DynamicImage::from_decoder(decoder).map_err(|_| Status::invalid_argument("Нужен корректный PNG или JPEG допустимого размера"))?;
        image.apply_orientation(orientation);
        let mut preview = Vec::new();
        for side in [160, 120, 90, 64, 48, 32] {
            let mut output = Cursor::new(Vec::new());
            image.thumbnail(side.min(image.width()), side.min(image.height())).write_to(&mut output, ImageFormat::Png)
                .map_err(|_| Status::internal("Не удалось создать превью"))?;
            preview = output.into_inner();
            if preview.len() <= MAX_PREVIEW_BYTES { break; }
        }
        if preview.len() > MAX_PREVIEW_BYTES { return Err(Status::internal("Превью превышает допустимый размер")); }
        let mut variants = Vec::new();
        if screens {
            let transparent = image.color().has_alpha() && image.to_rgba8().pixels().any(|pixel| pixel.0[3] != 255);
            let sizes: &[u32] = if kind == "background" { &[720, 1080, 1440] } else { &[512, 1024] };
            let mut previous = (0, 0);
            for &size in sizes {
                let scale = if kind == "background" { image.width() as f64 } else { image.width().max(image.height()) as f64 };
                let ratio = (size as f64 / scale).min(1.0);
                let width = ((image.width() as f64 * ratio).round() as u32).max(1);
                let height = ((image.height() as f64 * ratio).round() as u32).max(1);
                if previous == (width, height) { continue; }
                previous = (width, height);
                let small = if (width, height) == (image.width(), image.height()) { image.clone() }
                    else { image.resize_exact(width, height, image::imageops::FilterType::Lanczos3) };
                let mut output = Vec::new();
                let mut mime = if kind == "background" && !transparent {
                    image::codecs::jpeg::JpegEncoder::new_with_quality(&mut output, 82).encode_image(&small.to_rgb8())
                        .map_err(|_| Status::internal("Не удалось сжать фон"))?;
                    "image/jpeg"
                } else {
                    let mut buffer = Cursor::new(Vec::new());
                    small.write_to(&mut buffer, ImageFormat::Png).map_err(|_| Status::internal("Не удалось сжать персонажа"))?;
                    output = buffer.into_inner();
                    "image/png"
                };
                // Маленький исходник не увеличиваю и не заменяю более тяжёлым файлом
                if orientation == Orientation::NoTransforms && (width, height) == (image.width(), image.height()) && bytes.len() < output.len() {
                    if let Some(source_format @ (ImageFormat::Png | ImageFormat::Jpeg)) = format {
                        output = bytes.clone();
                        mime = if source_format == ImageFormat::Png { "image/png" } else { "image/jpeg" };
                    }
                }
                variants.push(Variant { name:format!("{kind}-{size}"), width:width as i32, height:height as i32,
                    mime:mime.into(), byte_length:output.len() as i32, hash:format!("{:x}",Sha256::digest(&output)), data:Some(Bytes::from(output)) });
            }
        }
        Ok(Prepared { preview, version, variants })
    }).await.map_err(|_| Status::internal("Ошибка обработки изображения"))?
}
