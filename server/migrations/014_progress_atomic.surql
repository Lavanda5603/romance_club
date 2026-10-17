BEGIN TRANSACTION;
DEFINE FIELD IF NOT EXISTS revision ON progress TYPE int DEFAULT 0;
DEFINE FIELD OVERWRITE scene_id ON progress TYPE option<record<scene>>;
DEFINE TABLE IF NOT EXISTS progress_archive SCHEMALESS PERMISSIONS NONE;

-- Оставляю последнее сохранение, исходные записи сохраняю в архиве
LET $pairs = SELECT player_id, episode_id FROM progress GROUP BY player_id, episode_id;
FOR $pair IN $pairs {
    LET $rows = SELECT * FROM progress WHERE player_id = $pair.player_id AND episode_id = $pair.episode_id ORDER BY updated_at DESC, id DESC;
    LET $key = type::record('progress', [$pair.player_id, $pair.episode_id]);
    IF array::len($rows) > 1 OR $rows[0].id != $key {
        FOR $row IN $rows {
            CREATE progress_archive CONTENT { original: $row, archived_at: time::now() };
        };
        LET $last = $rows[0];
        DELETE progress WHERE player_id = $pair.player_id AND episode_id = $pair.episode_id;
        CREATE $key CONTENT {
            player_id: $last.player_id, episode_id: $last.episode_id,
            scene_id: $last.scene_id, flags: $last.flags, counters: $last.counters,
            updated_at: $last.updated_at, revision: $last.revision ?? 0
        };
    };
};
COMMIT TRANSACTION;

-- Строю индекс после фиксации переноса, до запуска API
DEFINE INDEX IF NOT EXISTS progress_owner_episode ON progress FIELDS player_id, episode_id UNIQUE;
