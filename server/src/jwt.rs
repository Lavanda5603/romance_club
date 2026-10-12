use jsonwebtoken::{encode, decode, Header, Validation, EncodingKey, DecodingKey};
use serde::{Deserialize, Serialize};
use chrono::{Utc, Duration};

// Секретный ключ (в продакшене — в .env!)
const SECRET_KEY: &[u8] = b"romance_club_secret_key_2026_super_secret_do_not_share";

// Время жизни токена — 7 дней
const TOKEN_LIFETIME_HOURS: i64 = 24 * 7;

// Claims (данные внутри токена)
#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String, // ID игрока
    pub login: String, // Логин
    pub exp: usize, // Время истечения (Unix timestamp)
}

// Создать JWT для игрока
pub fn create_token(player_id: &str, login: &str) -> Result<String, String> {
    let expiration = Utc::now()
        .checked_add_signed(Duration::hours(TOKEN_LIFETIME_HOURS))
        .expect("Неверное время")
        .timestamp() as usize;

    let claims = Claims {
        sub: player_id.to_string(),
        login: login.to_string(),
        exp: expiration,
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(SECRET_KEY),
    )
    .map_err(|e| format!("Ошибка создания токена: {}", e))
}

// Проверить JWT и вернуть Claims
pub fn verify_token(token: &str) -> Result<Claims, String> {
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(SECRET_KEY),
        &Validation::default(),
    )
    .map(|data| data.claims)
    .map_err(|e| format!("Неверный токен: {}", e))
}