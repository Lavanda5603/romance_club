-- Добавляю поле preview_data (base64 превью) в таблицу asset
DEFINE FIELD IF NOT EXISTS preview_data ON TABLE asset TYPE string;