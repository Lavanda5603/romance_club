-- Добавляю пропущенные ответы и показываю героев по одному.
IF !record::exists(scene:ep5_adrian_mysterious) AND record::exists(scene:336) {
UPDATE scene SET order_index += 2 WHERE episode_id=episode:5 AND order_index >= 85;
LET $base = SELECT * OMIT id FROM ONLY scene:336;
CREATE scene:ep5_adrian_mysterious CONTENT object::extend($base,{title:'Загадочно',character_emotion:'sly',order_index:85,texts:['Леди Баг: «Знаю это и не могу не ответить взаимностью».']});
CREATE scene:ep5_adrian_reserved CONTENT object::extend($base,{title:'Сдержанно',character_emotion:'reserved',order_index:86,texts:['Леди Баг молчит. Но смотрит ему в глаза.']});
UPDATE action SET scene_key='scene:ep5_adrian_mysterious',scene_id=0 WHERE choice_id.scene_id=scene:335 AND choice_id.title='Загадочно' AND type='nextScene';
UPDATE action SET scene_key='scene:ep5_adrian_reserved',scene_id=0 WHERE choice_id.scene_id=scene:335 AND choice_id.title='Сдержанно' AND type='nextScene';
};
IF !record::exists(scene:ep4_assemble_carapace) AND record::exists(scene:207) {
LET $base = SELECT * OMIT id FROM ONLY scene:207;
UPDATE scene SET order_index += 4 WHERE episode_id=episode:4 AND order_index > $base.order_index;
UPDATE scene:207 SET next_scene_key='scene:ep4_assemble_carapace',next_scene_id=0,texts=["Вспышки света. Передо мной пять новых героев.","Рена Руж."];
CREATE scene:ep4_assemble_carapace CONTENT object::extend($base,{title:'Карапас',character:'carapace',character_emotion:'normal',order_index:$base.order_index+1,next_scene_key:'scene:ep4_assemble_ryuko',next_scene_id:0,texts:["Карапас."]});
CREATE scene:ep4_assemble_ryuko CONTENT object::extend($base,{title:'Рюко',character:'ryuko',character_emotion:'normal',order_index:$base.order_index+2,next_scene_key:'scene:ep4_assemble_viperion',next_scene_id:0,texts:["Рюко."]});
CREATE scene:ep4_assemble_viperion CONTENT object::extend($base,{title:'Виперион',character:'viperion',character_emotion:'normal',order_index:$base.order_index+3,next_scene_key:'scene:ep4_assemble_queenbee',next_scene_id:0,texts:["Виперион."]});
CREATE scene:ep4_assemble_queenbee CONTENT object::extend($base,{title:'Квин Би',character:'queenbee',character_emotion:'normal',order_index:$base.order_index+4,next_scene_key:'scene:208',next_scene_id:208,texts:["Квин Би. Команда собрана."]});
};
IF !record::exists(scene:ep5_attack_carapace) AND record::exists(scene:270) {
LET $base = SELECT * OMIT id FROM ONLY scene:270;
UPDATE scene SET order_index += 4 WHERE episode_id=episode:5 AND order_index > $base.order_index;
UPDATE scene:270 SET next_scene_key='scene:ep5_attack_carapace',next_scene_id=0,texts=["Рена Руж кричит: «Леди Баг! Мы прикроем!»"];
CREATE scene:ep5_attack_carapace CONTENT object::extend($base,{title:'Карапас',character:'carapace',character_emotion:'shield',order_index:$base.order_index+1,next_scene_key:'scene:ep5_attack_ryuko',next_scene_id:0,texts:["Карапас создаёт щит. Все прячутся за ним."]});
CREATE scene:ep5_attack_ryuko CONTENT object::extend($base,{title:'Рюко',character:'ryuko',character_emotion:'attack',order_index:$base.order_index+2,next_scene_key:'scene:ep5_attack_viperion',next_scene_id:0,texts:["Рюко атакует с фланга. Золотая отвлекается."]});
CREATE scene:ep5_attack_viperion CONTENT object::extend($base,{title:'Виперион',character:'viperion',character_emotion:'play',order_index:$base.order_index+3,next_scene_key:'scene:ep5_attack_queenbee',next_scene_id:0,texts:["Виперион возвращает время. Золотая сбита с толку."]});
CREATE scene:ep5_attack_queenbee CONTENT object::extend($base,{title:'Квин Би',character:'queenbee',character_emotion:'attack',order_index:$base.order_index+4,next_scene_key:'scene:271',next_scene_id:271,texts:["Квин Би парализует её на секунду."]});
};