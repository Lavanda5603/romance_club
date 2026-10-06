-- Добавляю поле file_data (байты картинки в base64)
DEFINE FIELD IF NOT EXISTS file_data ON TABLE asset TYPE option<string>;