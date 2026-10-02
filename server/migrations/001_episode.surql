-- Таблица эпизодов
DEFINE TABLE IF NOT EXISTS episode SCHEMAFULL;

-- Поля эпизода
DEFINE FIELD IF NOT EXISTS title ON TABLE episode TYPE string;
DEFINE FIELD IF NOT EXISTS version ON TABLE episode TYPE int;
DEFINE FIELD IF NOT EXISTS created_at ON TABLE episode TYPE datetime DEFAULT time::now();
DEFINE FIELD IF NOT EXISTS updated_at ON TABLE episode TYPE datetime DEFAULT time::now();