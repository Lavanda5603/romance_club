DEFINE FIELD IF NOT EXISTS ending ON progress TYPE string DEFAULT '';
-- Историю прохождений сохраняю и при повторном запуске эпизода
DEFINE TABLE IF NOT EXISTS episode_completion SCHEMAFULL;
DEFINE FIELD IF NOT EXISTS player_id ON episode_completion TYPE record<player>;
DEFINE FIELD IF NOT EXISTS episode_id ON episode_completion TYPE record<episode>;
DEFINE FIELD IF NOT EXISTS endings ON episode_completion TYPE array<string> DEFAULT [];
DEFINE FIELD IF NOT EXISTS completed_at ON episode_completion TYPE datetime DEFAULT time::now();
FOR $row IN (SELECT * FROM progress WHERE completed = true) {
    LET $key = type::record('episode_completion', [$row.player_id, $row.episode_id]);
    IF !record::exists($key) {
        CREATE $key CONTENT {player_id:$row.player_id, episode_id:$row.episode_id, endings:[]};
    };
};

DEFINE FUNCTION OVERWRITE fn::can_unlock_all($player: record<player>, $name: string) {
    IF $name = 'all_episodes' {
        LET $required = SELECT VALUE id FROM episode;
        LET $done = SELECT VALUE episode_id FROM episode_completion WHERE player_id = $player;
        RETURN array::len($required) > 0 AND array::len(array::intersect($required, $done)) = array::len($required);
    };
    IF $name = 'all_endings' {
        LET $scenes = SELECT VALUE id FROM scene WHERE record::exists(episode_id);
        LET $choices = SELECT VALUE id FROM choice WHERE scene_id IN $scenes;
        LET $custom = SELECT VALUE title FROM action WHERE choice_id IN $choices AND type = 'ending' AND title != '';
        LET $required = array::union(['МариАдриан', 'МариКот', 'Лука', 'АдриБаг', 'СуперБаг'], $custom);
        LET $seen = array::flatten(SELECT VALUE endings FROM episode_completion WHERE player_id = $player);
        RETURN array::len(array::intersect($required, $seen)) = array::len($required);
    };
    RETURN false;
};
