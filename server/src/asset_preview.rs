use std::io::Cursor;
use image::{ImageReader, ImageFormat, Limits};
use sha2::{Sha256, Digest};
use tonic::Status;

pub const MAX_PREVIEW_BYTES: usize = 24 * 1024;

// Ограничиваю декодирование и сохраняю прозрачность персонажей
pub async fn make(bytes: Vec<u8>) -> Result<(Vec<u8>, String), Status> {
    tokio::task::spawn_blocking(move || {
        let version = format!("{:x}", Sha256::digest(&bytes));
        let mut reader = ImageReader::new(Cursor::new(bytes)).with_guessed_format()
            .map_err(|_| Status::invalid_argument("Не удалось прочитать изображение"))?;
        let mut limits = Limits::default();
        limits.max_image_width = Some(8192);
        limits.max_image_height = Some(8192);
        limits.max_alloc = Some(64 * 1024 * 1024);
        reader.limits(limits);
        let image = reader.decode().map_err(|_| Status::invalid_argument("Нужен корректный PNG или JPEG допустимого размера"))?;
        let mut thumb = image.thumbnail(160, 160);
        for side in [160, 120, 90, 64, 48, 32] {
            if side < 160 { thumb = thumb.thumbnail(side, side); }
            let mut output = Cursor::new(Vec::new());
            thumb.write_to(&mut output, ImageFormat::Png)
                .map_err(|_| Status::internal("Не удалось создать превью"))?;
            let preview = output.into_inner();
            if preview.len() <= MAX_PREVIEW_BYTES { return Ok((preview, version)); }
        }
        Err(Status::internal("Превью превышает допустимый размер"))
    }).await.map_err(|_| Status::internal("Ошибка обработки изображения"))?
}