-- Таблица ассетов (картинок, звуков)
DEFINE TABLE IF NOT EXISTS asset SCHEMAFULL;

-- Поля ассета
DEFINE FIELD IF NOT EXISTS type ON TABLE asset TYPE string;
DEFINE FIELD IF NOT EXISTS name ON TABLE asset TYPE string;
DEFINE FIELD IF NOT EXISTS emotion ON TABLE asset TYPE option<string>;
DEFINE FIELD IF NOT EXISTS url ON TABLE asset TYPE string;
DEFINE FIELD IF NOT EXISTS display_name ON TABLE asset TYPE string;
DEFINE FIELD IF NOT EXISTS episode_id ON TABLE asset TYPE option<record<episode>>;
DEFINE FIELD IF NOT EXISTS created_at ON TABLE asset TYPE datetime DEFAULT time::now();