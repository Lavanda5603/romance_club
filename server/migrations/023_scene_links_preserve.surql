BEGIN TRANSACTION;
-- Старую схему сначала расширяю, чтобы не потерять строковые и числовые значения
DEFINE FIELD OVERWRITE next_scene_id ON scene TYPE option<int | string> DEFAULT 0;
DEFINE FIELD OVERWRITE scene_id ON action TYPE option<int | string>;
DEFINE FIELD IF NOT EXISTS next_scene_key ON scene TYPE option<string>;
DEFINE FIELD IF NOT EXISTS scene_key ON action TYPE option<string>;
-- Уже сохранённые постоянные ключи оставляю на месте
UPDATE scene SET next_scene_key = IF type::is_string(next_scene_id) { next_scene_id }
    ELSE IF next_scene_id != NONE AND next_scene_id != 0 { <string>type::record('scene', next_scene_id) } ELSE { '' }
    WHERE next_scene_key = NONE OR next_scene_key = '';
UPDATE action SET scene_key = IF type::is_string(scene_id) { scene_id }
    ELSE IF scene_id != NONE AND scene_id != 0 { <string>type::record('scene', scene_id) } ELSE { '' }
    WHERE type = 'nextScene' AND (scene_key = NONE OR scene_key = '');
COMMIT TRANSACTION;
