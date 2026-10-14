use jsonwebtoken::{encode, decode, Header, Validation, EncodingKey, DecodingKey}; // Импорт JWT-функций
use serde::{Deserialize, Serialize}; // Импорт сериализации
use chrono::{Utc, Duration}; // Импорт работы со временем

// Время жизни токена - 7 дней
const TOKEN_LIFETIME_HOURS: i64 = 24 * 7;

// Получить секретный ключ из переменной окружения
fn get_secret() -> Vec<u8> {
    std::env::var("JWT_SECRET")
        .expect("JWT_SECRET не задан в переменных окружения")
        .into_bytes()
}

// Claims (данные внутри токена)
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: String, // ID игрока
    pub login: String, // Логин
    pub is_admin: bool, // Админ ли
    pub exp: usize, // Время истечения
}

// Создать JWT для игрока
pub fn create_token(player_id: &str, login: &str, is_admin: bool) -> Result<String, String> {
    let expiration = Utc::now()
        .checked_add_signed(Duration::hours(TOKEN_LIFETIME_HOURS))
        .expect("Неверное время")
        .timestamp() as usize;

    let claims = Claims {
        sub: player_id.to_string(),
        login: login.to_string(),
        is_admin,
        exp: expiration,
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(&get_secret()), // читаю ключ из env
    )
    .map_err(|e| format!("Ошибка создания токена: {}", e))
}

// Проверить JWT и вернуть Claims
pub fn verify_token(token: &str) -> Result<Claims, String> {
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(&get_secret()), // читаю ключ из env
        &Validation::default(),
    )
    .map(|data| data.claims)
    .map_err(|e| format!("Неверный токен: {}", e))
}