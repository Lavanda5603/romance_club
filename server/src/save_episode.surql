BEGIN TRANSACTION;

LET $episode = type::record('episode', $episode_id);

-- Не оставляю сохранённый прогресс со ссылкой на удалённую сцену
LET $removed_scenes = (SELECT VALUE id FROM scene WHERE episode_id = $episode AND <string>id NOT IN $scene_keys);
IF array::len((SELECT VALUE id FROM progress WHERE scene_id IN $removed_scenes LIMIT 1)) > 0 {
    THROW "SCENE_HAS_PROGRESS";
};
UPSERT $episode MERGE { title: $title, version: $version, updated_at: time::now() };

LET $old_scenes = (SELECT VALUE id FROM scene WHERE episode_id = $episode);
LET $old_choices = (SELECT VALUE id FROM choice WHERE scene_id IN $old_scenes);
DELETE action WHERE choice_id IN $old_choices;
DELETE choice WHERE scene_id IN $old_scenes;

FOR $scene IN $scenes {
    LET $scene_id = type::record($scene.key);
    LET $data = {
        episode_id: $episode, title: $scene.title,
        background: $scene.background, character: $scene.character,
        character_emotion: $scene.character_emotion, texts: $scene.texts,
        condition: $scene.condition, text_position: $scene.text_position,
        character_position: $scene.character_position,
        order_index: $scene.order_index, next_scene_id: $scene.next_scene_id,
        next_scene_key: $scene.next_scene_key
    };
    IF $scene.is_new {
        CREATE $scene_id CONTENT $data;
    } ELSE {
        UPDATE $scene_id MERGE $data;
    };
    FOR $choice IN $scene.choices {
        LET $choice_id = type::record('choice', rand::ulid());
        CREATE $choice_id CONTENT {
            scene_id: $scene_id, text: $choice.text,
            title: $choice.title, order_index: $choice.order_index
        };
        FOR $action IN $choice.actions {
            CREATE action CONTENT {
                choice_id: $choice_id, type: $action.type,
                scene_id: $action.scene_id, scene_key: $action.scene_key,
                flag_name: $action.flag_name,
                flag_value: $action.flag_value, counter_name: $action.counter_name,
                counter_value: $action.counter_value, sound_path: $action.sound_path,
                image_path: $action.image_path, title: $action.title
            };
        };
    };
};

DELETE scene WHERE episode_id = $episode AND <string>id NOT IN $scene_keys;
COMMIT TRANSACTION;