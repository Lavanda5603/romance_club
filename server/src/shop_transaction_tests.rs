use crate::{shop_service::ShopApiService, jwt::Claims, romance_club::*}; // Подключаю модули сервера
use crate::romance_club::shop_api_server::ShopApi; // Подключаю модули сервера
use surrealdb::{Surreal, engine::remote::ws::{Client, Ws}, opt::auth::Root}; // Подключаю работу с SurrealDB
use tonic::Request; // Подключаю запросы, ответы и ошибки gRPC
use serde_json::Value; // Подключаю работу с JSON
type TestResult = Result<(), Box<dyn std::error::Error + Send + Sync>>;

fn buy(item: &str, kind: &str, key: &str) -> Request<PurchaseRequest> {
    let mut req = Request::new(PurchaseRequest { player_id: "player:test".into(),
        item_id: item.into(), item_type: kind.into(), request_id: key.into() });
    req.extensions_mut().insert(Claims { sub:"player:test".into(), login:"test".into(), is_admin:false, exp:usize::MAX });
    req
}

async fn balance(shop: &ShopApiService) -> i32 {
    let mut req = Request::new(GetCurrencyRequest { player_id:"player:test".into() });
    req.extensions_mut().insert(Claims { sub:"player:test".into(), login:"test".into(), is_admin:false, exp:usize::MAX });
    shop.get_currency(req).await.unwrap().into_inner().diamonds
}

async fn scenarios(db: Surreal<Client>) -> TestResult {
    db.query(include_str!("../migrations/008_purchase.surql")).await?.check()?;
    db.query("CREATE episode:1; CREATE episode:2; CREATE episode:3; CREATE episode:4; CREATE episode:5; CREATE episode:6; CREATE episode:7;").await?.check()?;
    db.query("CREATE player_currency:old CONTENT {player_id:player:test,diamonds:500};").await?.check()?;
    let shop = ShopApiService::new(db.clone());
    let (a,b) = tokio::join!(shop.purchase(buy("episode:1","episode","a")), shop.purchase(buy("episode:2","episode","b")));
    assert!(a?.into_inner().success && b?.into_inner().success);
    assert_eq!(balance(&shop).await, 300);
    assert!(shop.purchase(buy("episode:1","episode","retry")).await?.into_inner().success);
    assert_eq!(balance(&shop).await, 300);
    let (a,b) = tokio::join!(shop.purchase(buy("episode:3","episode","c")), shop.purchase(buy("episode:3","episode","d")));
    assert!(a?.into_inner().success && b?.into_inner().success);
    assert_eq!(balance(&shop).await, 200);
    db.query("UPDATE player_currency:old SET diamonds=150;").await?.check()?;
    let (a,b) = tokio::join!(shop.purchase(buy("episode:4","episode","e")), shop.purchase(buy("episode:5","episode","f")));
    assert_ne!(a?.into_inner().success, b?.into_inner().success);
    assert_eq!(balance(&shop).await, 50);
    let (a,b) = tokio::join!(shop.purchase(buy("diamonds_100","currency","topup")), shop.purchase(buy("diamonds_100","currency","topup")));
    assert!(a?.into_inner().success && b?.into_inner().success);
    assert_eq!(balance(&shop).await, 150);
    assert!(shop.purchase(buy("diamonds_250","currency","topup")).await.is_err());
    assert_eq!(balance(&shop).await, 150);
    db.query("DEFINE EVENT fail_purchase ON purchase WHEN $event='CREATE' THEN { THROW 'test_refusal'; };").await?.check()?;
    assert!(shop.purchase(buy("episode:6","episode","fail")).await.is_err());
    assert_eq!(balance(&shop).await, 150);
    let mut rows = db.query("SELECT * FROM purchase WHERE item_id='episode:6';").await?.check()?;
    assert!(rows.take::<Vec<Value>>(0)?.is_empty());
    db.query("REMOVE EVENT fail_purchase ON purchase;").await?.check()?;
    // Сохраняю старые покупки с обычными ключами
    db.query("CREATE purchase:old CONTENT {player_id:player:test,item_id:'episode:7',item_type:'episode'};").await?.check()?;
    assert!(shop.purchase(buy("episode:7","episode","old")).await?.into_inner().success);
    assert_eq!(balance(&shop).await, 150);
    // Первый кошелёк создаётся вместе с пополнением
    db.query("DELETE player_currency;").await?.check()?;
    assert!(shop.purchase(buy("diamonds_100","currency","new-wallet")).await?.into_inner().success);
    assert_eq!(balance(&shop).await, 100);
    // Неизвестный SKU, тип или отсутствующий эпизод не меняют баланс и покупки
    let mut before = db.query("SELECT * FROM purchase ORDER BY id;").await?.check()?;
    let before: Vec<Value> = before.take(0)?;
    for (sku, kind) in [("subscription","unknown"),("subscription","episode"),("episode:1","subscription"),
        ("fake_subscription","subscription"),("diamonds_999999","currency"),("episode:999","episode"),
        ("episode:01","episode"),("subscription","")] {
        assert_eq!(shop.purchase(buy(sku,kind,"invalid")).await.unwrap_err().code(),tonic::Code::InvalidArgument);
        assert_eq!(balance(&shop).await,100);
    }
    let mut after = db.query("SELECT * FROM purchase ORDER BY id;").await?.check()?;
    assert_eq!(after.take::<Vec<Value>>(0)?,before);
    // Старая поддельная запись остаётся в истории, но подписку не даёт
    db.query("CREATE purchase:fake CONTENT {player_id:player:test,item_id:'subscription',item_type:'unknown'}; CREATE purchase:wrong CONTENT {player_id:player:test,item_id:'subscription',item_type:'episode'};").await?.check()?;
    assert!(!purchases(&shop).await?.iter().any(|p|p.item_id=="subscription" && p.entitlement_active));
    // Не хватает средств: право не появляется
    assert!(!shop.purchase(buy("subscription","subscription","sub")).await?.into_inner().success);
    assert!(!purchases(&shop).await?.iter().any(|p|p.item_id=="subscription" && p.entitlement_active));
    shop.purchase(buy("diamonds_500","currency","for-sub")).await?;
    assert!(shop.purchase(buy("subscription","subscription","sub")).await?.into_inner().success);
    assert_eq!(balance(&shop).await,100);
    let all = purchases(&shop).await?;
    assert_eq!(all.iter().filter(|p|p.item_id=="subscription" && p.entitlement_active).count(),1);
    assert!(all.iter().filter(|p|p.item_type=="currency").all(|p|!p.entitlement_active));
    assert!(shop.purchase(buy("subscription","subscription","retry")).await?.into_inner().success);
    assert_eq!(balance(&shop).await,100);
    Ok(())
}

async fn purchases(shop: &ShopApiService) -> Result<Vec<Purchase>,tonic::Status> {
    let mut req = Request::new(GetPurchasesRequest {player_id:"player:test".into()});
    req.extensions_mut().insert(Claims {sub:"player:test".into(),login:"test".into(),is_admin:false,exp:usize::MAX});
    Ok(shop.get_purchases(req).await?.into_inner().purchases)
}

#[tokio::test]
#[ignore = "Нужна SurrealDB; покупки проверяю только в отдельной БД"]
async fn purchases_are_atomic() -> TestResult {
    let db = Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
    let name = format!("shop_test_{}", uuid::Uuid::new_v4().simple());
    db.use_ns("romance_club").await?;
    db.query(format!("DEFINE DATABASE {name};")).await?.check()?;
    db.use_db(&name).await?;
    let result = tokio::spawn(scenarios(db.clone())).await;
    db.query(format!("REMOVE DATABASE {name};")).await?.check()?;
    result?
}
