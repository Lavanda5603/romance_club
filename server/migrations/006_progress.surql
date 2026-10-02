-- Таблица прогресса
DEFINE TABLE IF NOT EXISTS progress SCHEMAFULL;

-- Поля прогресса
DEFINE FIELD IF NOT EXISTS player_id ON TABLE progress TYPE record<player>;
DEFINE FIELD IF NOT EXISTS episode_id ON TABLE progress TYPE record<episode>;
DEFINE FIELD IF NOT EXISTS scene_id ON TABLE progress TYPE record<scene>;
DEFINE FIELD IF NOT EXISTS flags ON TABLE progress TYPE object;
DEFINE FIELD IF NOT EXISTS counters ON TABLE progress TYPE object;
DEFINE FIELD IF NOT EXISTS updated_at ON TABLE progress TYPE datetime DEFAULT time::now();