-- Добавляю поле next_scene_id в таблицу scene
DEFINE FIELD IF NOT EXISTS next_scene_id ON TABLE scene TYPE int DEFAULT 0;