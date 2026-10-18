BEGIN TRANSACTION;
LET $progress_guard_key = type::record('progress_session', [type::record($player_id)]);
LET $progress_guard = SELECT * FROM ONLY $progress_guard_key;
IF ($progress_guard.generation ?? 0) != $expected_generation { THROW 'PROGRESS_GENERATION_CONFLICT'; };
-- Общая запись связывает сохранения разных эпизодов со сбросом
UPSERT $progress_guard_key CONTENT {
    player_id: type::record($player_id), generation: $expected_generation,
    write_revision: ($progress_guard.write_revision ?? 0) + 1
};
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
    ending: IF $completed { $ending } ELSE { '' },
    flags: $flags,
    counters: $counters,
    revision: $expected_revision + 1,
    updated_at: time::now()
};
IF $completed {
    LET $history = type::record('episode_completion', [type::record($player_id), type::record('episode', $episode_id)]);
    UPSERT $history SET player_id = type::record($player_id), episode_id = type::record('episode', $episode_id),
        endings = array::union(endings ?? [], IF $ending = '' { [] } ELSE { [$ending] }), completed_at = time::now();
    FOR $name IN ['all_episodes', 'all_endings'] {
        IF fn::can_unlock_all(type::record($player_id), $name) {
            LET $achievement = type::record('achievement', [type::record($player_id), $name]);
            IF !record::exists($achievement) {
                CREATE $achievement CONTENT {player_id:type::record($player_id), name:$name, unlocked_at:time::now()};
            };
        };
    };
};
COMMIT TRANSACTION;
