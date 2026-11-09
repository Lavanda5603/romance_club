-- Переношу встречу с Фу после выхода Маринетт в Париж.
IF record::exists(scene:hidden_ep3_fu) AND record::exists(scene:121) AND record::exists(scene:122) {
    UPDATE scene:116 SET next_scene_key = 'scene:117', next_scene_id = 117 WHERE episode_id = episode:3 AND next_scene_key = 'scene:hidden_ep3_fu';
    UPDATE scene:121 SET next_scene_key = 'scene:hidden_ep3_fu', next_scene_id = 0 WHERE episode_id = episode:3 AND next_scene_key = 'scene:122';
    UPDATE scene:hidden_ep3_fu SET next_scene_key = 'scene:122', next_scene_id = 122 WHERE episode_id = episode:3 AND next_scene_key = 'scene:117';
    UPDATE action SET scene_key = 'scene:122' WHERE choice_id IN (SELECT VALUE id FROM choice WHERE scene_id = scene:hidden_ep3_fu) AND type = 'nextScene' AND scene_key = 'scene:117';
};