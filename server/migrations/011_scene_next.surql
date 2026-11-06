-- Добавляю поле next_scene_id в таблицу scene
DEFINE FIELD IF NOT EXISTS next_scene_id ON TABLE scene TYPE int DEFAULT 0
    MIGRATE EXISTING ROWS AS add_scene_next USING 0;
