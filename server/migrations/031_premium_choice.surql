-- Добавляю один редкий платный разговор и оставляю бесплатное продолжение сюжета.
DEFINE FIELD IF NOT EXISTS diamond_price ON choice TYPE int DEFAULT 0;
DEFINE FIELD IF NOT EXISTS premium_key ON choice TYPE string DEFAULT '';
DEFINE FIELD IF NOT EXISTS premium_key ON scene TYPE string DEFAULT '';
-- DEFAULT не заполняет старые строки автоматически: делаю перенос до изменения переходов.
UPDATE scene SET premium_key = premium_key ?? '';
UPDATE choice SET diamond_price = diamond_price ?? 0, premium_key = premium_key ?? '';
IF record::exists(scene:hidden_ep4_mask) AND !record::exists(scene:premium_mask_prompt) {
    CREATE scene:premium_mask_prompt CONTENT {
        episode_id:episode:4,title:'Разговор на крыше',background:'ep1/roof',character:'catnoir',character_emotion:'smile',
        character_position:'center_left',text_position:'center_right',order_index:1010,
        condition:'(romance_ladybug_cat>=5) И flag:seen_hidden_ep4_mask!=true',
        texts:['Супер-Кот задерживается у края крыши. Кажется, он хочет сказать мне что-то очень личное. Я могу остаться с ним или вернуться к нашим делам.'],
        next_scene_id:230,next_scene_key:'scene:230',routes:[]
    };
    CREATE choice:premium_mask_yes CONTENT {scene_id:scene:premium_mask_prompt,text:'Остаться с Супер-Котом',title:'Особый разговор',order_index:0,diamond_price:30,premium_key:'choice:mask_rooftop'};
    CREATE action:premium_mask_yes CONTENT {choice_id:choice:premium_mask_yes,type:'nextScene',title:'Почти снятая маска',scene_key:'scene:hidden_ep4_mask',counter_name:'',counter_value:0,flag_name:'',flag_value:false};
    CREATE choice:premium_mask_no CONTENT {scene_id:scene:premium_mask_prompt,text:'Вернуться к нашим делам',title:'Продолжить бесплатно',order_index:1,diamond_price:0,premium_key:''};
    CREATE action:premium_mask_no CONTENT {choice_id:choice:premium_mask_no,type:'nextScene',title:'Продолжить историю',scene_key:'scene:230',counter_name:'',counter_value:0,flag_name:'',flag_value:false};
    UPDATE scene SET next_scene_key='scene:premium_mask_prompt',next_scene_id=0 WHERE next_scene_key='scene:hidden_ep4_mask';
    UPDATE action SET scene_key='scene:premium_mask_prompt' WHERE type='nextScene' AND scene_key='scene:hidden_ep4_mask' AND id != action:premium_mask_yes;
    UPDATE scene:hidden_ep4_mask SET premium_key='choice:mask_rooftop';
    -- Не заставляю платить заново тех, кто уже прочитал или сейчас читает этот разговор.
    FOR $player IN array::distinct(SELECT VALUE player_id FROM progress WHERE scene_id=scene:hidden_ep4_mask OR flags.seen_hidden_ep4_mask=true) {
        LET $owned = type::record('purchase',[$player,'choice','choice:mask_rooftop']);
        IF !record::exists($owned) {
            CREATE $owned CONTENT {player_id:$player,item_id:'choice:mask_rooftop',item_type:'choice',purchased_at:time::now()};
        };
    };
};