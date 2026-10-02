-- Таблица игроков
DEFINE TABLE IF NOT EXISTS player SCHEMAFULL;

-- Поля игрока
DEFINE FIELD IF NOT EXISTS login ON TABLE player TYPE string;
DEFINE FIELD IF NOT EXISTS email ON TABLE player TYPE string;
DEFINE FIELD IF NOT EXISTS password_hash ON TABLE player TYPE string;
DEFINE FIELD IF NOT EXISTS created_at ON TABLE player TYPE datetime DEFAULT time::now();