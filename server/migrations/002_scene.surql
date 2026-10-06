-- Таблица сцен
DEFINE TABLE IF NOT EXISTS scene SCHEMAFULL;

-- Поля сцены
DEFINE FIELD IF NOT EXISTS episode_id ON TABLE scene TYPE record<episode>;
DEFINE FIELD IF NOT EXISTS title ON TABLE scene TYPE string;
DEFINE FIELD IF NOT EXISTS background ON TABLE scene TYPE string;
DEFINE FIELD IF NOT EXISTS character ON TABLE scene TYPE string;
DEFINE FIELD IF NOT EXISTS character_emotion ON TABLE scene TYPE string;
DEFINE FIELD IF NOT EXISTS texts ON TABLE scene TYPE array<string>;
DEFINE FIELD IF NOT EXISTS condition ON TABLE scene TYPE string;
DEFINE FIELD IF NOT EXISTS text_position ON TABLE scene TYPE string;
DEFINE FIELD IF NOT EXISTS character_position ON TABLE scene TYPE string;
DEFINE FIELD IF NOT EXISTS order_index ON TABLE scene TYPE int;