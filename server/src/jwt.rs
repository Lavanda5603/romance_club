use jsonwebtoken::{encode, decode, Header, Validation, EncodingKey, DecodingKey}; // Импорт JWT-функций
use serde::{Deserialize, Serialize}; // Импорт сериализации
use chrono::{Utc, Duration}; // Импорт работы со временем
use std::io; // Подключаю стандартные классы Rust

// Время жизни токена - 7 дней
const TOKEN_LIFETIME_HOURS: i64 = 24 * 7;

// Claims (данные внутри токена)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String, // ID игрока
    pub login: String, // Логин
    pub is_admin: bool, // Админ ли
    pub exp: usize, // Время истечения
}

// Храню проверенный ключ в состоянии сервера
#[derive(Clone)]
pub struct JwtKeys {
    encoding: EncodingKey,
    decoding: DecodingKey,
}

impl JwtKeys {
    // Загружаю ключ один раз при запуске
    pub fn from_env() -> Result<Self, io::Error> {
        let secret = std::env::var("JWT_SECRET")
            .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "JWT_SECRET не задан или содержит неверную кодировку"))?;
        Self::from_secret(&secret)
    }

    pub(crate) fn from_secret(secret: &str) -> Result<Self, io::Error> {
        // Для HS256 нужен ключ не короче 32 байт, без пробелов
        if secret.len() < 32 || secret.chars().any(char::is_whitespace) {
            return Err(io::Error::new(io::ErrorKind::InvalidInput,
                "JWT_SECRET должен содержать не менее 32 байт без пробелов; используйте случайный ключ"));
        }
        Ok(Self {
            encoding: EncodingKey::from_secret(secret.as_bytes()),
            decoding: DecodingKey::from_secret(secret.as_bytes()),
        })
    }

    // Создаю JWT для игрока
    pub fn create_token(&self, player_id: &str, login: &str, is_admin: bool) -> Result<String, String> {
        let expiration = Utc::now()
            .checked_add_signed(Duration::hours(TOKEN_LIFETIME_HOURS))
            .ok_or_else(|| "Неверное время".to_string())?
            .timestamp() as usize;
        let claims = Claims {
            sub: player_id.to_string(),
            login: login.to_string(),
            is_admin,
            exp: expiration,
        };
        encode(&Header::default(), &claims, &self.encoding)
            .map_err(|_| "Ошибка создания токена".to_string())
    }

    // Проверяю JWT сохранённым ключом
    pub fn verify_token(&self, token: &str) -> Result<Claims, String> {
        decode::<Claims>(token, &self.decoding, &Validation::default())
            .map(|data| data.claims)
            .map_err(|_| "Неверный токен".to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reject_empty_short_and_whitespace_secrets() {
        for secret in ["", "short", "                                ", " test_key_only_0123456789_ABCDEFGHIJKLMN", "test_key_only_0123456789_ABCDEFGHIJKLMN\n"] {
            assert!(JwtKeys::from_secret(secret).is_err());
        }
    }

    #[test]
    fn rotation_rejects_tokens_signed_with_another_key() {
        let old = JwtKeys::from_secret("test_old_key_0123456789_ABCDEFGHIJKLMN").unwrap();
        let current = JwtKeys::from_secret("test_new_key_9876543210_NMLKJIHGFEDCBA").unwrap();
        let old_admin = old.create_token("player:attacker", "attacker", true).unwrap();
        assert!(current.verify_token(&old_admin).is_err());
        for admin in [false, true] {
            let token = current.create_token("player:owner", "owner", admin).unwrap();
            let claims = current.verify_token(&token).unwrap();
            assert_eq!(claims.sub, "player:owner");
            assert_eq!(claims.is_admin, admin);
        }
    }
}