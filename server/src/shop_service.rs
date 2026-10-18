use tonic::{Request, Response, Status}; // Импорт tonic
use surrealdb::engine::remote::ws::Client; // Импорт клиента SurrealDB
use surrealdb::Surreal; // Импорт Surreal
use serde_json::Value; // Импорт Value
use crate::romance_club::shop_api_server::ShopApi; // Импорт трейта
use crate::romance_club::{
    Purchase, Currency, GetPurchasesRequest, GetPurchasesResponse,
    PurchaseRequest, PurchaseResponse, GetCurrencyRequest,
}; // Импорт структур

use crate::shop_catalog::Product; // Подключаю серверный каталог товаров
use surrealdb::types::{RecordId, ToSql}; // Подключаю ключи эпизодов

// Сервис для работы с магазином
pub struct ShopApiService {
    pub db: Surreal<Client>, // Подключение к SurrealDB
}

impl ShopApiService {
    // Создать новый сервис
    pub fn new(db: Surreal<Client>) -> Self {
        Self { db }
    }

    // Получить баланс игрока
    async fn get_diamonds_internal(&self, player_id: &str) -> Result<i32, String> {
        let mut response = self
            .db
            .query("SELECT * FROM player_currency WHERE player_id = type::record($player_id) LIMIT 1")
            .bind(("player_id", player_id.to_string()))
            .await
            .map_err(|e| e.to_string())?
            .check().map_err(|e| e.to_string())?;

        let result: Option<Value> = response.take(0).map_err(|e| e.to_string())?;

        Ok(match result {
            Some(v) => v.get("diamonds").and_then(|d| d.as_i64()).unwrap_or(0) as i32,
            None => 0,
        })
    }


}

#[tonic::async_trait]
impl ShopApi for ShopApiService {
    // Получить все покупки игрока
    async fn get_purchases(
        &self,
        request: Request<GetPurchasesRequest>,
    ) -> Result<Response<GetPurchasesResponse>, Status> {
        let player_id = crate::request_auth::player_id(&request, &request.get_ref().player_id)?;

        println!("[GET_PURCHASES] player={}", player_id);

        let mut response = self
            .db
            .query("SELECT * FROM purchase WHERE player_id = type::record($player_id); SELECT VALUE id FROM episode;")
            .bind(("player_id", player_id.clone()))
            .await
            .map_err(|e| Status::internal(e.to_string()))?
            .check().map_err(|e| Status::internal(e.to_string()))?;

        let values: Vec<Value> = response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;
        let episodes: Vec<RecordId> = response.take(1).map_err(|e| Status::internal(e.to_string()))?;

        let purchases = values
            .into_iter()
            .map(|v| {
                let item_id = v.get("item_id").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let item_type = v.get("item_type").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let purchased_at = v
                    .get("purchased_at")
                    .and_then(|s| s.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_default();

                // Старые записи с неправильным SKU или типом не выдают право
                let entitlement_active = Product::find(&item_id).is_ok_and(|product|
                    product.kind == item_type && (product.kind == "subscription" ||
                        (product.kind == "episode" && episodes.iter().any(|id| id.to_sql() == item_id))));
                Purchase {
                    item_id,
                    item_type,
                    purchased_at,
                    entitlement_active,
                }
            })
            .collect();

        Ok(Response::new(GetPurchasesResponse { purchases }))
    }

    // Купить предмет
    async fn purchase(
        &self,
        request: Request<PurchaseRequest>,
    ) -> Result<Response<PurchaseResponse>, Status> {
        let player_id = crate::request_auth::player_id(&request, &request.get_ref().player_id)?;
        let req = request.into_inner();
        let item_id = req.item_id;
        let product = Product::find(&item_id)?;
        if req.item_type != product.kind {
            return Err(Status::invalid_argument("Тип покупки не соответствует товару"));
        }
        let item_type = product.kind.to_owned();

        println!("[PURCHASE] player={}, item={}, type={}", player_id, item_id, item_type);

        if product.kind == "currency" && req.request_id.is_empty() {
            return Err(Status::invalid_argument("Нужен ключ запроса покупки"));
        }

        // Баланс и покупку меняю вместе. Повтор не списывает алмазы ещё раз
        for attempt in 0..8 {
            let mut result = self.db.query(include_str!("purchase.surql"))
                .bind(("player_id", player_id.clone()))
                .bind(("item_id", item_id.clone()))
                .bind(("item_type", item_type.clone()))
                .bind(("request_id", req.request_id.clone()))
                .bind(("price", product.price))
                .bind(("amount", product.amount))
                .bind(("episode_id", product.episode_id))
                .await.map_err(|e| Status::internal(e.to_string()))?;
            let errors = result.take_errors();
            if !errors.is_empty() {
                let messages = errors.values().map(ToString::to_string).collect::<Vec<_>>().join("; ");
                let conflict = messages.contains("SHOP_BALANCE_CONFLICT") || errors.values().any(|e|
                    matches!(e.query_details(), Some(surrealdb::types::QueryError::TransactionConflict)));
                if conflict {
                    if attempt < 7 { continue; }
                    return Err(Status::aborted("Баланс изменился. Повторите покупку"));
                }
                if messages.contains("SHOP_UNKNOWN_SKU") { return Err(Status::invalid_argument("Эпизод не существует")); }
                if messages.contains("SHOP_REQUEST_REUSED") || messages.contains("SHOP_BALANCE_OVERFLOW") {
                    return Err(Status::invalid_argument("Неверный запрос покупки"));
                }
                return Err(Status::internal(messages));
            }
            let mut output = None;
            for index in 0..result.num_statements() {
                if let Ok(value) = result.take::<Option<Value>>(index) {
                    if value.as_ref().is_some_and(|v| v.get("success").is_some()) { output = value; }
                }
            }
            let value = output.ok_or_else(|| Status::internal("База не вернула результат покупки"))?;
            return Ok(Response::new(PurchaseResponse {
                success: value["success"].as_bool().unwrap_or(false),
                message: value["message"].as_str().unwrap_or_default().into(),
                currency: Some(Currency { player_id, diamonds: value["diamonds"].as_i64()
                    .and_then(|n| i32::try_from(n).ok()).ok_or_else(|| Status::internal("Неверный баланс"))? }),
            }));
        }
        Err(Status::aborted("Не удалось завершить покупку"))
    }

    // Получить баланс игрока
    async fn get_currency(
        &self,
        request: Request<GetCurrencyRequest>,
    ) -> Result<Response<Currency>, Status> {
        let player_id = crate::request_auth::player_id(&request, &request.get_ref().player_id)?;

        println!("[GET_CURRENCY] player={}", player_id);

        let diamonds = self
            .get_diamonds_internal(&player_id)
            .await
            .map_err(|e| Status::internal(e))?;

        Ok(Response::new(Currency {
            player_id,
            diamonds,
        }))
    }
}
