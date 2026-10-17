-- Добавляю строковые ключи переходов, старые числовые поля сохраняю
DEFINE FIELD IF NOT EXISTS next_scene_key ON TABLE scene TYPE option<string>;
DEFINE FIELD IF NOT EXISTS scene_key ON TABLE action TYPE option<string>;
