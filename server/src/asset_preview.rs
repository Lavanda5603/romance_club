use std::io::Cursor; // Подключаю стандартные классы Rust
use image::{ImageReader, ImageFormat, ImageDecoder, DynamicImage, Limits, metadata::Orientation}; // Подключаю чтение и обработку картинок
use sha2::{Sha256, Digest}; // Подключаю подсчёт SHA256
use surrealdb::types::{Bytes, SurrealValue}; // Подключаю работу с SurrealDB
use tonic::Status; // Подключаю запросы, ответы и ошибки gRPC

pub const MAX_PREVIEW_BYTES: usize = 24 * 1024;
pub const MAX_SIDE: u32 = 8192;
pub const MAX_PIXELS: u64 = 16_000_000;
pub const MAX_DECODED_BYTES: u64 = 64 * 1024 * 1024;
static WORKERS: tokio::sync::Semaphore = tokio::sync::Semaphore::const_new(2);
// Ограничиваю и работающие задачи, и ожидающие картинки в памяти.
static ADMISSION: tokio::sync::Semaphore = tokio::sync::Semaphore::const_new(8);

// Отказываю сразу, когда все места очереди заняты.
fn reserve_image_slot(queue: &tokio::sync::Semaphore) -> Result<tokio::sync::SemaphorePermit<'_>, Status> {
    queue.try_acquire().map_err(|_| Status::resource_exhausted("Очередь обработки картинок заполнена"))
}

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
    process_limited(bytes, kind, screens, &WORKERS, std::time::Duration::from_secs(5), std::time::Duration::from_secs(20)).await
}

async fn process_limited(bytes: Vec<u8>, kind: &str, screens: bool,
    workers: &'static tokio::sync::Semaphore, queue_wait: std::time::Duration, budget: std::time::Duration,
) -> Result<Prepared, Status> {
    let admission = reserve_image_slot(&ADMISSION)?;
    let permit = tokio::time::timeout(queue_wait, workers.acquire()).await
        .map_err(|_| Status::resource_exhausted("Сервер обрабатывает другие картинки. Повторите загрузку"))?
        .map_err(|_| Status::unavailable("Обработка изображений остановлена"))?;
    let kind = kind.to_owned();
    let started = std::time::Instant::now();
    let job = tokio::task::spawn_blocking(move || {
        let _admission = admission;
        let _permit = permit;
        let check_time = || if started.elapsed() > budget {
            Err(Status::deadline_exceeded("Обработка картинки заняла больше 20 секунд"))
        } else { Ok(()) };
        check_time()?;
        let version = format!("{:x}", Sha256::digest(&bytes));
        let mut reader = ImageReader::new(Cursor::new(&bytes)).with_guessed_format()
            .map_err(|_| Status::invalid_argument("Не удалось прочитать изображение"))?;
        let format = reader.format();
        if !matches!(format, Some(ImageFormat::Png | ImageFormat::Jpeg)) {
            return Err(Status::invalid_argument("Поддерживаются только статичные PNG и JPEG"));
        }
        let mut limits = Limits::default();
        limits.max_alloc = Some(MAX_DECODED_BYTES);
        reader.limits(limits.clone());
        let mut decoder = reader.into_decoder().map_err(|_| Status::invalid_argument("Нужен корректный PNG или JPEG допустимого размера"))?;
        // Проверяю заголовок до выделения памяти под пиксели
        let (width, height) = decoder.dimensions();
        if width == 0 || height == 0 || width > MAX_SIDE || height > MAX_SIDE {
            return Err(Status::invalid_argument("Ширина и высота картинки должны быть от 1 до 8192 пикселей"));
        }
        if u64::from(width) * u64::from(height) > MAX_PIXELS {
            return Err(Status::invalid_argument("В картинке больше 16 000 000 пикселей"));
        }
        if decoder.total_bytes() > MAX_DECODED_BYTES {
            return Err(Status::invalid_argument("Декодированная картинка занимает больше 64 MiB"));
        }
        if format == Some(ImageFormat::Png) {
            let png = image::codecs::png::PngDecoder::with_limits(Cursor::new(&bytes), limits.clone())
                .map_err(|_| Status::invalid_argument("Повреждён PNG"))?;
            if png.is_apng().map_err(|_| Status::invalid_argument("Повреждены сведения о кадрах PNG"))? {
                return Err(Status::invalid_argument("Нужна статичная картинка с одним кадром. APNG не поддерживается"));
            }
        }
        limits.max_image_width = Some(MAX_SIDE);
        limits.max_image_height = Some(MAX_SIDE);
        decoder.set_limits(limits).map_err(|_| Status::invalid_argument("Картинка превышает бюджет декодирования"))?;
        let orientation = decoder.orientation().map_err(|_| Status::invalid_argument("Не удалось прочитать ориентацию изображения"))?;
        let mut image = DynamicImage::from_decoder(decoder).map_err(|_| Status::invalid_argument("Нужен корректный PNG или JPEG допустимого размера"))?;
        check_time()?;
        image.apply_orientation(orientation);
        let mut preview = Vec::new();
        for side in [160, 120, 90, 64, 48, 32] {
            check_time()?;
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
                check_time()?;
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
        check_time()?;
        Ok(Prepared { preview, version, variants })
    });
    // После таймаута задача удерживает слот до выхода и ничего не записывает в БД
    tokio::time::timeout(budget, job).await
        .map_err(|_| Status::deadline_exceeded("Обработка картинки заняла больше 20 секунд"))?
        .map_err(|_| Status::internal("Ошибка обработки изображения"))?
}

#[cfg(test)]
mod budget_tests {
    use super::*;
    use std::time::Duration;
    #[test]
    fn waiting_images_have_a_fixed_capacity() {
        let queue = tokio::sync::Semaphore::new(2);
        let first = reserve_image_slot(&queue).unwrap();
        let _second = reserve_image_slot(&queue).unwrap();
        assert_eq!(reserve_image_slot(&queue).unwrap_err().code(), tonic::Code::ResourceExhausted);
        drop(first);
        assert!(reserve_image_slot(&queue).is_ok());
    }
    #[tokio::test]
    async fn full_queue_returns_error_before_decoding() {
        static BUSY: tokio::sync::Semaphore = tokio::sync::Semaphore::const_new(0);
        let error = process_limited(b"not an image".to_vec(), "background", true,
            &BUSY, Duration::from_millis(1), Duration::from_secs(20)).await.err().unwrap();
        assert_eq!(error.code(), tonic::Code::ResourceExhausted);
    }
    #[tokio::test]
    async fn expired_processing_budget_cannot_return_prepared_image() {
        static WORKER: tokio::sync::Semaphore = tokio::sync::Semaphore::const_new(1);
        let error = process_limited(b"not an image".to_vec(), "background", true,
            &WORKER, Duration::from_secs(5), Duration::ZERO).await.err().unwrap();
        assert_eq!(error.code(), tonic::Code::DeadlineExceeded);
    }
}
