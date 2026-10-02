-- Таблица действий
DEFINE TABLE IF NOT EXISTS action SCHEMAFULL;

-- Поля действия
DEFINE FIELD IF NOT EXISTS choice_id ON TABLE action TYPE record<choice>;
DEFINE FIELD IF NOT EXISTS type ON TABLE action TYPE string;
DEFINE FIELD IF NOT EXISTS scene_id ON TABLE action TYPE option<int>;
DEFINE FIELD IF NOT EXISTS flag_name ON TABLE action TYPE option<string>;
DEFINE FIELD IF NOT EXISTS flag_value ON TABLE action TYPE option<bool>;
DEFINE FIELD IF NOT EXISTS counter_name ON TABLE action TYPE option<string>;
DEFINE FIELD IF NOT EXISTS counter_value ON TABLE action TYPE option<int>;
DEFINE FIELD IF NOT EXISTS sound_path ON TABLE action TYPE option<string>;
DEFINE FIELD IF NOT EXISTS image_path ON TABLE action TYPE option<string>;
DEFINE FIELD IF NOT EXISTS title ON TABLE action TYPE string;