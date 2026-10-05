-- Таблица достижений
DEFINE TABLE IF NOT EXISTS achievement SCHEMAFULL;

-- Поля достижения
DEFINE FIELD IF NOT EXISTS player_id ON TABLE achievement TYPE record<player>;
DEFINE FIELD IF NOT EXISTS name ON TABLE achievement TYPE string;
DEFINE FIELD IF NOT EXISTS unlocked_at ON TABLE achievement TYPE datetime DEFAULT time::now();