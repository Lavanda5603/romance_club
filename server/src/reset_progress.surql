BEGIN TRANSACTION;
LET $player = type::record($player_id);
LET $key = type::record('progress_session', [$player]);
LET $progress_guard = SELECT * FROM ONLY $key;
IF ($progress_guard.generation ?? 0) >= 2147483647 { THROW 'PROGRESS_GENERATION_OVERFLOW'; };
UPSERT $key CONTENT {
    player_id: $player,
    generation: ($progress_guard.generation ?? 0) + 1,
    write_revision: ($progress_guard.write_revision ?? 0) + 1
};
UPDATE progress SET scene_id = NONE, completed = false, ending = '', flags = {}, counters = {},
    revision = (revision ?? 0) + 1, updated_at = time::now() WHERE player_id = $player;
COMMIT TRANSACTION;
