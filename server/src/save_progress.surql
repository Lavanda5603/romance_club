BEGIN TRANSACTION;
LET $key = type::record('progress', [type::record($player_id), type::record('episode', $episode_id)]);
LET $saved = (SELECT * FROM ONLY $key);
IF ($saved.revision ?? 0) != $expected_revision { THROW 'PROGRESS_CONFLICT'; };
IF !record::exists(type::record($scene_id)) OR (SELECT VALUE episode_id FROM ONLY type::record($scene_id)) != type::record('episode', $episode_id) {
    THROW 'PROGRESS_SCENE_INVALID';
};
UPSERT $key CONTENT {
    player_id: type::record($player_id),
    episode_id: type::record('episode', $episode_id),
    scene_id: type::record($scene_id),
    completed: $completed,
    flags: $flags,
    counters: $counters,
    revision: $expected_revision + 1,
    updated_at: time::now()
};
COMMIT TRANSACTION;
