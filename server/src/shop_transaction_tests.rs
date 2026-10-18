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
    assert!(shop.purchase(buy("diamonds_200","currency","topup")).await.is_err());
    assert_eq!(balance(&shop).await, 150);
    db.query("DEFINE EVENT fail_purchase ON purchase WHEN $event='CREATE' THEN { THROW 'test_refusal'; };").await?.check()?;
    assert!(shop.purchase(buy("episode:rollback","episode","fail")).await.is_err());
    assert_eq!(balance(&shop).await, 150);
    let mut rows = db.query("SELECT * FROM purchase WHERE item_id='episode:rollback';").await?.check()?;
    assert!(rows.take::<Vec<Value>>(0)?.is_empty());
    db.query("REMOVE EVENT fail_purchase ON purchase;").await?.check()?;
    // Сохраняю старые покупки с обычными ключами
    db.query("CREATE purchase:old CONTENT {player_id:player:test,item_id:'episode:legacy',item_type:'episode'};").await?.check()?;
    assert!(shop.purchase(buy("episode:legacy","episode","old")).await?.into_inner().success);
    assert_eq!(balance(&shop).await, 150);
    // Первый кошелёк создаётся вместе с пополнением
    db.query("DELETE player_currency;").await?.check()?;
    assert!(shop.purchase(buy("diamonds_100","currency","new-wallet")).await?.into_inner().success);
    assert_eq!(balance(&shop).await, 100);
    Ok(())
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
