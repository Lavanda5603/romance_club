-- Таблица покупок
DEFINE TABLE IF NOT EXISTS purchase SCHEMAFULL;

-- Поля покупки
DEFINE FIELD IF NOT EXISTS player_id ON TABLE purchase TYPE record<player>;
DEFINE FIELD IF NOT EXISTS item_id ON TABLE purchase TYPE string;
DEFINE FIELD IF NOT EXISTS item_type ON TABLE purchase TYPE string;
DEFINE FIELD IF NOT EXISTS purchased_at ON TABLE purchase TYPE datetime DEFAULT time::now();

-- Таблица валюты игрока (алмазы)
DEFINE TABLE IF NOT EXISTS player_currency SCHEMAFULL;

-- Поля валюты
DEFINE FIELD IF NOT EXISTS player_id ON TABLE player_currency TYPE record<player>;
DEFINE FIELD IF NOT EXISTS diamonds ON TABLE player_currency TYPE int DEFAULT 0;
DEFINE FIELD IF NOT EXISTS updated_at ON TABLE player_currency TYPE datetime DEFAULT time::now();