-- Сохраняю существующую историю как первую новеллу, не меняя ID глав и прогресс.
DEFINE TABLE IF NOT EXISTS novel SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD IF NOT EXISTS title ON novel TYPE string;
DEFINE FIELD IF NOT EXISTS cover_id ON novel TYPE string DEFAULT '';
DEFINE FIELD IF NOT EXISTS background_id ON novel TYPE string DEFAULT '';
DEFINE FIELD IF NOT EXISTS music_id ON novel TYPE string DEFAULT '';
DEFINE FIELD IF NOT EXISTS click_id ON novel TYPE string DEFAULT '';
DEFINE FIELD IF NOT EXISTS config ON novel TYPE object FLEXIBLE DEFAULT {};
DEFINE FIELD IF NOT EXISTS revision ON novel TYPE int DEFAULT 1;
IF !record::exists(novel:ladybug) {
    CREATE novel:ladybug CONTENT {title:'Леди Баг и Супер-Кот',cover_id:'',background_id:'',music_id:'',click_id:'',config:{},revision:1};
};
DEFINE FIELD IF NOT EXISTS novel_id ON episode TYPE record<novel> DEFAULT novel:ladybug;
UPDATE episode SET novel_id = novel_id ?? novel:ladybug;
DEFINE TABLE IF NOT EXISTS novel_audio SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD IF NOT EXISTS novel_id ON novel_audio TYPE record<novel>;
DEFINE FIELD IF NOT EXISTS kind ON novel_audio TYPE string;
DEFINE FIELD IF NOT EXISTS data ON novel_audio TYPE bytes;
DEFINE FIELD IF NOT EXISTS hash ON novel_audio TYPE string;
DEFINE TABLE IF NOT EXISTS story_sequence SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD IF NOT EXISTS value ON story_sequence TYPE int DEFAULT 0;