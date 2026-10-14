-- Обнуляю next_scene_id в scene (старые int несовместимы)
UPDATE scene SET next_scene_id = '';
-- Меняю тип поля на строку
DEFINE FIELD OVERWRITE next_scene_id ON TABLE scene TYPE string DEFAULT '';

-- Обнуляю scene_id в action (старые int несовместимы)
UPDATE action SET scene_id = '';
-- Меняю тип поля на строку
DEFINE FIELD OVERWRITE scene_id ON TABLE action TYPE string DEFAULT '';