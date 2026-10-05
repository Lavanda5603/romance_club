use tonic::{Request, Response, Status};
use surrealdb::engine::remote::ws::Client;
use surrealdb::Surreal;
use serde_json::Value;
use crate::romance_club::shop_api_server::ShopApi;
use crate::romance_club::{
    Purchase, Currency, GetPurchasesRequest, GetPurchasesResponse,
    PurchaseRequest, PurchaseResponse, GetCurrencyRequest,
};

// Цены (в алмазах)
const EPISODE_PRICE: i32 = 100; // Эпизод
const SUBSCRIPTION_PRICE: i32 = 500; // Подписка

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
            .map_err(|e| e.to_string())?;

        let result: Option<Value> = response.take(0).map_err(|e| e.to_string())?;

        Ok(match result {
            Some(v) => v.get("diamonds").and_then(|d| d.as_i64()).unwrap_or(0) as i32,
            None => 0,
        })
    }

    // Установить баланс игрока
    async fn set_diamonds_internal(
        &self,
        player_id: &str,
        diamonds: i32,
    ) -> Result<(), String> {
        // Проверяю, есть ли запись
        let mut check = self
            .db
            .query("SELECT * FROM player_currency WHERE player_id = type::record($player_id) LIMIT 1")
            .bind(("player_id", player_id.to_string()))
            .await
            .map_err(|e| e.to_string())?;

        let existing: Option<Value> = check.take(0).map_err(|e| e.to_string())?;

        if existing.is_some() {
            // Обновляю
            self.db
                .query("UPDATE player_currency SET diamonds = $diamonds, updated_at = time::now() WHERE player_id = type::record($player_id)")
                .bind(("player_id", player_id.to_string()))
                .bind(("diamonds", diamonds))
                .await
                .map_err(|e| e.to_string())?;
        } else {
            // Создаю
            self.db
                .query("CREATE player_currency CONTENT { player_id: type::record($player_id), diamonds: $diamonds, updated_at: time::now() }")
                .bind(("player_id", player_id.to_string()))
                .bind(("diamonds", diamonds))
                .await
                .map_err(|e| e.to_string())?;
        }

        Ok(())
    }
}

#[tonic::async_trait]
impl ShopApi for ShopApiService {
    // Получить все покупки игрока
    async fn get_purchases(
        &self,
        request: Request<GetPurchasesRequest>,
    ) -> Result<Response<GetPurchasesResponse>, Status> {
        let req = request.into_inner();
        let player_id = req.player_id;

        println!("[GET_PURCHASES] player={}", player_id);

        let mut response = self
            .db
            .query("SELECT * FROM purchase WHERE player_id = type::record($player_id)")
            .bind(("player_id", player_id.clone()))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let values: Vec<Value> = response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

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

                Purchase {
                    item_id,
                    item_type,
                    purchased_at,
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
        let req = request.into_inner();
        let player_id = req.player_id;
        let item_id = req.item_id;
        let item_type = req.item_type;

        println!("[PURCHASE] player={}, item={}, type={}", player_id, item_id, item_type);

        // Получаю баланс
        let mut balance = self
            .get_diamonds_internal(&player_id)
            .await
            .map_err(|e| Status::internal(e))?;

        // Определяю цену
        let price = match item_type.as_str() {
            "episode" => EPISODE_PRICE,
            "subscription" => SUBSCRIPTION_PRICE,
            "currency" => 0, // Покупка валюты - бесплатно
            _ => 0,
        };

        // Если валюта - начисляю алмазы
        if item_type == "currency" {
            // Парсю количество из item_id (diamonds_100 - 100)
            let amount: i32 = item_id
                .strip_prefix("diamonds_")
                .and_then(|s| s.parse().ok())
                .unwrap_or(0);

            balance += amount;
            self.set_diamonds_internal(&player_id, balance)
                .await
                .map_err(|e| Status::internal(e))?;

            // Создаю запись о покупке
            self.db
                .query("CREATE purchase CONTENT { player_id: type::record($player_id), item_id: $item_id, item_type: $item_type, purchased_at: time::now() }")
                .bind(("player_id", player_id.clone()))
                .bind(("item_id", item_id.clone()))
                .bind(("item_type", item_type.clone()))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            let currency = Currency {
                player_id: player_id.clone(),
                diamonds: balance,
            };

            return Ok(Response::new(PurchaseResponse {
                success: true,
                message: format!("Начислено {} алмазов", amount),
                currency: Some(currency),
            }));
        }

        // Проверяю, хватает ли алмазов
        if balance < price {
            let currency = Currency {
                player_id: player_id.clone(),
                diamonds: balance,
            };

            return Ok(Response::new(PurchaseResponse {
                success: false,
                message: format!("Не хватает алмазов. Нужно {}, у вас {}", price, balance),
                currency: Some(currency),
            }));
        }

        // Проверяю, не куплено ли уже
        let mut check = self
            .db
            .query("SELECT * FROM purchase WHERE player_id = type::record($player_id) AND item_id = $item_id LIMIT 1")
            .bind(("player_id", player_id.clone()))
            .bind(("item_id", item_id.clone()))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let existing: Option<Value> = check
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        if existing.is_some() {
            return Ok(Response::new(PurchaseResponse {
                success: false,
                message: "Уже куплено".to_string(),
                currency: Some(Currency {
                    player_id: player_id.clone(),
                    diamonds: balance,
                }),
            }));
        }

        // Списание алмазов
        balance -= price;
        self.set_diamonds_internal(&player_id, balance)
            .await
            .map_err(|e| Status::internal(e))?;

        // Создаю запись о покупке
        self.db
            .query("CREATE purchase CONTENT { player_id: type::record($player_id), item_id: $item_id, item_type: $item_type, purchased_at: time::now() }")
            .bind(("player_id", player_id.clone()))
            .bind(("item_id", item_id.clone()))
            .bind(("item_type", item_type.clone()))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let currency = Currency {
            player_id: player_id.clone(),
            diamonds: balance,
        };

        Ok(Response::new(PurchaseResponse {
            success: true,
            message: "Покупка успешна".to_string(),
            currency: Some(currency),
        }))
    }

    // Получить баланс игрока
    async fn get_currency(
        &self,
        request: Request<GetCurrencyRequest>,
    ) -> Result<Response<Currency>, Status> {
        let req = request.into_inner();
        let player_id = req.player_id;

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