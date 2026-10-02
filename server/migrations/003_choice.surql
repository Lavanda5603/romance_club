-- Таблица выборов
DEFINE TABLE IF NOT EXISTS choice SCHEMAFULL;

-- Поля выбора
DEFINE FIELD IF NOT EXISTS scene_id ON TABLE choice TYPE record<scene>;
DEFINE FIELD IF NOT EXISTS text ON TABLE choice TYPE string;
DEFINE FIELD IF NOT EXISTS title ON TABLE choice TYPE string;
DEFINE FIELD IF NOT EXISTS order_index ON TABLE choice TYPE int;