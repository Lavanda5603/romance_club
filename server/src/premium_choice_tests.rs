use crate::{jwt::Claims, progress_service::ProgressApiService, shop_service::ShopApiService}; // Подключаю реальные сервисы
use crate::romance_club::{*, progress_api_server::ProgressApi, shop_api_server::ShopApi, episode_api_server::EpisodeApi}; // Подключаю контракты
use surrealdb::{engine::remote::ws::Ws, opt::auth::Root}; // Подключаю отдельную БД
use tonic::{Request, Code}; // Подключаю запрос и отказ в доступе

fn own<T>(body:T) -> Request<T> {
    let mut req = Request::new(body);
    req.extensions_mut().insert(Claims {sub:"player:paid".into(),login:"paid".into(),is_admin:false,exp:usize::MAX});
    req
}
fn buy(price:i32) -> Request<PurchaseRequest> {
    own(PurchaseRequest {player_id:"player:paid".into(),item_id:"choice:mask_rooftop".into(),item_type:"choice".into(),expected_price:price,..Default::default()})
}
fn save() -> Request<SaveProgressRequest> {
    own(SaveProgressRequest {player_id:"player:paid".into(),episode_id:4,scene_id:"scene:hidden_ep4_mask".into(),..Default::default()})
}

#[tokio::test]
#[ignore = "Проверяю покупки только в отдельной случайной БД"]
async fn paid_choice_is_atomic_repeatable_and_optional() -> Result<(),Box<dyn std::error::Error+Send+Sync>> {
    let db = surrealdb::Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
    let name = format!("paid_choice_{}",uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club_test").use_db(&name).await?;
    let result = async {
        crate::apply_migrations(&db).await.map_err(|e|e.to_string())?;
        db.query("CREATE episode:4 CONTENT {title:'Крыша',version:1};").await?.check()?;
        for key in ["228","229","230","hidden_ep4_mask"] {
            let id = match key.parse::<i64>() {
                Ok(number) => surrealdb::types::RecordId::new("scene",number),
                Err(_) => surrealdb::types::RecordId::new("scene",key),
            };
            db.query("CREATE $key CONTENT {episode_id:episode:4,title:'Сцена',background:'ep1/roof',character:'catnoir',character_emotion:'smile',texts:['Реплика'],condition:'',character_position:'center',text_position:'bottom_center',order_index:0,next_scene_key:'scene:hidden_ep4_mask'}")
                .bind(("key",id)).await?.check()?;
        }
        // Проверяю именно обновление существующей БД, а не только чистую схему.
        db.query("REMOVE FIELD diamond_price ON choice; REMOVE FIELD premium_key ON choice; REMOVE FIELD premium_key ON scene; UPDATE scene UNSET premium_key; CREATE choice:legacy CONTENT {scene_id:scene:228,text:'Продолжить',title:'Дальше',order_index:0}; CREATE progress CONTENT {player_id:player:legacy,episode_id:episode:4,scene_id:scene:hidden_ep4_mask,flags:{seen_hidden_ep4_mask:true},counters:{},updated_at:time::now()};").await?.check()?;
        for _ in 0..2 { db.query(include_str!("../migrations/031_premium_choice.surql")).await?.check()?; }
        let mut legacy = db.query("SELECT * FROM purchase WHERE player_id=player:legacy AND item_id='choice:mask_rooftop'").await?.check()?;
        assert_eq!(legacy.take::<Vec<serde_json::Value>>(0)?.len(),1);
        let episode = crate::EpisodeApiService::new(db.clone()).get_episode(own(GetEpisodeRequest {id:4})).await?.into_inner();
        let prompt = episode.scenes.iter().find(|s| s.scene_key == "scene:premium_mask_prompt").unwrap();
        assert_eq!(prompt.choices[0].diamond_price,30);
        assert_eq!(prompt.choices[0].premium_key,"choice:mask_rooftop");
        let mut check = db.query("SELECT diamond_price FROM choice WHERE scene_id=scene:premium_mask_prompt ORDER BY order_index; SELECT VALUE next_scene_key FROM ONLY scene:228;").await?.check()?;
        let choices:Vec<serde_json::Value> = check.take(0)?;
        assert_eq!(choices.len(),2);
        assert_eq!(choices[0]["diamond_price"],30);
        assert_eq!(choices[1]["diamond_price"],0);
        assert_eq!(check.take::<Option<String>>(1)?.as_deref(),Some("scene:premium_mask_prompt"));
        let shop = ShopApiService::new(db.clone());
        let progress = ProgressApiService::new(db.clone());
        assert_eq!(progress.save_progress(save()).await.unwrap_err().code(),Code::PermissionDenied);
        assert!(!shop.purchase(buy(30)).await?.into_inner().success);
        assert_eq!(shop.purchase(buy(15)).await.unwrap_err().code(),Code::FailedPrecondition);
        db.query("CREATE player_currency:test CONTENT {player_id:player:paid,diamonds:100};").await?.check()?;
        let (a,b) = tokio::join!(shop.purchase(buy(30)),shop.purchase(buy(30)));
        assert!(a?.into_inner().success && b?.into_inner().success);
        assert_eq!(shop.get_currency(own(GetCurrencyRequest {player_id:"player:paid".into()})).await?.into_inner().diamonds,70);
        assert!(progress.save_progress(save()).await?.into_inner().success);
        assert!(shop.purchase(buy(30)).await?.into_inner().success);
        assert_eq!(shop.get_currency(own(GetCurrencyRequest {player_id:"player:paid".into()})).await?.into_inner().diamonds,70);
        assert!(shop.get_purchases(own(GetPurchasesRequest {player_id:"player:paid".into()})).await?.into_inner().purchases[0].entitlement_active);
        progress.reset_progress(own(ResetProgressRequest {player_id:"player:paid".into()})).await?;
        assert!(shop.purchase(buy(30)).await?.into_inner().success);
        assert_eq!(shop.get_currency(own(GetCurrencyRequest {player_id:"player:paid".into()})).await?.into_inner().diamonds,70);
        db.query("UPDATE choice:premium_mask_yes SET diamond_price=40").await?.check()?;
        assert_eq!(shop.purchase(buy(30)).await.unwrap_err().code(),Code::FailedPrecondition);
        assert!(shop.purchase(buy(40)).await?.into_inner().success);
        assert_eq!(shop.get_currency(own(GetCurrencyRequest {player_id:"player:paid".into()})).await?.into_inner().diamonds,70);
        Ok::<(),Box<dyn std::error::Error+Send+Sync>>(())
    }.await;
    db.query(format!("REMOVE DATABASE {name}")).await?.check()?;
    result
}