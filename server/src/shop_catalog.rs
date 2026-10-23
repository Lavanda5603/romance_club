use tonic::Status; // Подключаю ошибку неизвестного товара

// Цену, тип и эффект покупки определяю по серверному SKU
pub struct Product {
    pub kind: &'static str,
    pub price: i32,
    pub amount: i32,
    pub episode_id: i32,
}

impl Product {
    pub fn find(sku: &str) -> Result<Self, Status> {
        let (kind, price, amount, episode_id) = match sku {
            "subscription" => ("subscription", 500, 0, 0),
            // Бесплатные пакеты для учебного демо, реальные платежи здесь не обрабатываю
            "diamonds_100" => ("currency", 0, 100, 0),
            "diamonds_250" => ("currency", 0, 250, 0),
            "diamonds_500" => ("currency", 0, 500, 0),
            _ => {
                let id = sku.strip_prefix("episode:").and_then(|id| id.parse::<i32>().ok())
                    .filter(|id| *id > 0 && format!("episode:{id}") == sku)
                    .ok_or_else(|| Status::invalid_argument("Неизвестный товар"))?;
                ("episode", 100, 0, id)
            }
        };
        Ok(Self { kind, price, amount, episode_id })
    }
}