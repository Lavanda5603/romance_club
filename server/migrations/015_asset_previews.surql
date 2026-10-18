-- Превью старых изображений заполняю при первом запросе страницы
DEFINE FIELD IF NOT EXISTS preview_data ON asset TYPE option<string>;
DEFINE FIELD IF NOT EXISTS version ON asset TYPE option<string>;
DEFINE INDEX IF NOT EXISTS asset_catalog_type ON asset FIELDS type;
DEFINE INDEX IF NOT EXISTS asset_lookup_name ON asset FIELDS type, name, emotion;
