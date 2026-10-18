use tonic::{Request, Response, Status}; // Импорт tonic
use surrealdb::engine::remote::ws::Client; // Импорт клиента SurrealDB
use surrealdb::Surreal; // Импорт Surreal
use serde_json::Value; // Импорт Value
use argon2::{
    password_hash::{
        rand_core::OsRng, // Генератор случайных чисел для соли
        PasswordHash, // Для чтения хэша из строки
        PasswordHasher, // Для хэширования пароля
        PasswordVerifier, // Для проверки пароля
        SaltString, // Соль для хэша
    },
    Argon2, // Алгоритм хэширования
};
use crate::romance_club::auth_api_server::AuthApi; // Импорт трейта
use crate::romance_club::{
    AuthResponse, RegisterRequest, LoginRequest, GetPlayerRequest, Player,
}; // Импорт структур
use crate::jwt::JwtKeys; // Ключ JWT

// Сервис для работы с авторизацией
pub struct AuthApiService {
    pub db: Surreal<Client>, // Подключение к SurrealDB
    jwt: JwtKeys, // Проверенный ключ
}

impl AuthApiService {
    // Одинаковый ответ для занятого логина при проверке и при гонке запросов
    fn login_taken() -> Response<AuthResponse> {
        Response::new(AuthResponse {
            success: false,
            message: "Игрок с таким логином уже существует".to_string(),
            player: None,
            token: String::new(),
            is_admin: false,
        })
    }

    // Уникальность окончательно проверяет индекс базы, а не предварительный SELECT
    async fn create_player(&self, login: &str, email: &str, password_hash: &str) -> Result<Option<Value>, Status> {
        for attempt in 0..4 {
            let mut response = self.db
                .query("CREATE player CONTENT { login: $login, email: $email, password_hash: $password_hash, is_admin: false, created_at: time::now() } RETURN id, login, email, created_at, is_admin")
                .bind(("login", login.to_owned()))
                .bind(("email", email.to_owned()))
                .bind(("password_hash", password_hash.to_owned()))
                .await.map_err(|e| Status::internal(e.to_string()))?;
            match response.take::<Option<Value>>(0) {
                Ok(Some(player)) => return Ok(Some(player)),
                Ok(None) => return Err(Status::internal("База не вернула созданного игрока")),
                Err(error) => {
                    // SDK передаёт нарушение индекса текстом; другие ошибки не выдаю за занятый логин
                    let message = error.to_string();
                    if message.contains("player_login_unique") && message.contains("already contains") {
                        return Ok(None);
                    }
                    if matches!(error.query_details(), Some(surrealdb::types::QueryError::TransactionConflict)) {
                        if attempt < 3 { continue; }
                        return Err(Status::aborted("Регистрация занята другим запросом. Повторите попытку"));
                    }
                    return Err(Status::internal(message));
                }
            }
        }
        Err(Status::aborted("Повторите регистрацию"))
    }

    // Создать новый сервис
    pub fn new(db: Surreal<Client>, jwt: JwtKeys) -> Self {
        Self { db, jwt }
    }

    // Хэшировать пароль через Argon2
    fn hash_password(password: &str) -> Result<String, String> {
        let salt = SaltString::generate(&mut OsRng);
        let argon2 = Argon2::default();
        argon2
            .hash_password(password.as_bytes(), &salt)
            .map(|hash| hash.to_string())
            .map_err(|e| format!("Ошибка хэширования: {}", e))
    }

    // Проверить пароль против хэша
    fn verify_password(password: &str, hash: &str) -> bool {
        let parsed_hash = match PasswordHash::new(hash) {
            Ok(h) => h,
            Err(_) => return false,
        };
        Argon2::default()
            .verify_password(password.as_bytes(), &parsed_hash)
            .is_ok()
    }

    // Проверка логина
    fn validate_login(login: &str) -> Option<String> {
        if login.is_empty() {
            return Some("Введите логин".to_string());
        }
        if login.len() < 3 {
            return Some("Логин должен быть не менее 3 символов".to_string());
        }
        if !login.chars().all(|c| c.is_ascii_alphanumeric() || c == '_') {
            return Some("Логин: только английские буквы, цифры и _".to_string());
        }
        None
    }

    // Проверка email
    fn validate_email(email: &str) -> Option<String> {
        if email.is_empty() {
            return Some("Введите email".to_string());
        }
        if !email.contains('@') {
            return Some("Email должен содержать @".to_string());
        }
        let parts: Vec<&str> = email.split('@').collect();
        if parts.len() != 2 {
            return Some("Email должен содержать один @".to_string());
        }
        if !parts[1].contains('.') {
            return Some("Email должен содержать точку после @".to_string());
        }
        None
    }

    // Проверка пароля
    fn validate_password(password: &str) -> Option<String> {
        if password.is_empty() {
            return Some("Введите пароль".to_string());
        }
        if password.len() < 5 {
            return Some("Пароль должен быть не менее 5 символов".to_string());
        }
        if !password.chars().any(|c| c.is_ascii_alphabetic()) {
            return Some("Пароль должен содержать английскую букву".to_string());
        }
        if !password.chars().any(|c| c.is_ascii_digit()) {
            return Some("Пароль должен содержать цифру".to_string());
        }
        let specials = "!@#$%^&*(),.?\":{}|<>_-+=[]\\;/~`";
        if !password.chars().any(|c| specials.contains(c)) {
            return Some("Пароль должен содержать спецсимвол".to_string());
        }
        None
    }
}

#[tonic::async_trait]
impl AuthApi for AuthApiService {
    // Регистрация игрока
    async fn register(
        &self,
        request: Request<RegisterRequest>,
    ) -> Result<Response<AuthResponse>, Status> {
        let req = request.into_inner();
        let login = req.login;
        let email = req.email;
        let password = req.password;

        println!("[REGISTER] login={}, email={}", login, email);

        // Валидация
        if let Some(err) = Self::validate_login(&login) {
            return Ok(Response::new(AuthResponse {
                success: false,
                message: err,
                player: None,
                token: String::new(),
                is_admin: false,
            }));
        }
        if let Some(err) = Self::validate_email(&email) {
            return Ok(Response::new(AuthResponse {
                success: false,
                message: err,
                player: None,
                token: String::new(),
                is_admin: false,
            }));
        }
        if let Some(err) = Self::validate_password(&password) {
            return Ok(Response::new(AuthResponse {
                success: false,
                message: err,
                player: None,
                token: String::new(),
                is_admin: false,
            }));
        }

        // Проверяю, есть ли игрок с таким логином
        let mut check_response = self
            .db
            .query("SELECT * FROM player WHERE login = $login LIMIT 1")
            .bind(("login", login.clone()))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let existing: Option<Value> = check_response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        if existing.is_some() {
            return Ok(Self::login_taken());
        }

        // Хэширую пароль
        let password_hash = match Self::hash_password(&password) {
            Ok(h) => h,
            Err(e) => {
                println!("[REGISTER] Ошибка хэширования: {}", e);
                return Ok(Response::new(AuthResponse {
                    success: false,
                    message: "Ошибка сервера при регистрации".to_string(),
                    player: None,
                    token: String::new(),
                    is_admin: false,
                }));
            }
        };

        // Создаю игрока (с хэшем пароля и is_admin = false)
        let result = self.create_player(&login, &email, &password_hash).await?;
        if result.is_none() { return Ok(Self::login_taken()); }

        match result {
            Some(v) => {
                let id = v
                    .get("id")
                    .and_then(|s| s.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_default();

                let created_at = v
                    .get("created_at")
                    .and_then(|s| s.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_default();

                let is_admin = v
                    .get("is_admin")
                    .and_then(|s| s.as_bool())
                    .unwrap_or(false);

                // Генерирую JWT с is_admin
                let token = match self.jwt.create_token(&id, &login, is_admin) {
                    Ok(t) => t,
                    Err(e) => {
                        println!("[REGISTER] Ошибка создания токена: {}", e);
                        String::new()
                    }
                };

                let player = Player {
                    id,
                    login: login.clone(),
                    email: email.clone(),
                    created_at,
                    is_admin,
                };

                println!("[REGISTER] Игрок создан: {} (токен выдан)", login);

                Ok(Response::new(AuthResponse {
                    success: true,
                    message: "Регистрация успешна".to_string(),
                    player: Some(player),
                    token,
                    is_admin,
                }))
            }
            None => Ok(Response::new(AuthResponse {
                success: false,
                message: "Ошибка создания игрока".to_string(),
                player: None,
                token: String::new(),
                is_admin: false,
            })),
        }
    }

    // Вход игрока
    async fn login(
        &self,
        request: Request<LoginRequest>,
    ) -> Result<Response<AuthResponse>, Status> {
        let req = request.into_inner();
        let login = req.login;
        let password = req.password;

        println!("[LOGIN] login={}", login);

        // Валидация
        if let Some(err) = Self::validate_login(&login) {
            return Ok(Response::new(AuthResponse {
                success: false,
                message: err,
                player: None,
                token: String::new(),
                is_admin: false,
            }));
        }
        if let Some(err) = Self::validate_password(&password) {
            return Ok(Response::new(AuthResponse {
                success: false,
                message: err,
                player: None,
                token: String::new(),
                is_admin: false,
            }));
        }

        // Ищу игрока по логину
        let mut response = self
            .db
            .query("SELECT * FROM player WHERE login = $login LIMIT 1")
            .bind(("login", login.clone()))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let result: Option<Value> = response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        match result {
            Some(v) => {
                let id = v
                    .get("id")
                    .and_then(|s| s.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_default();

                let email = v.get("email").and_then(|s| s.as_str()).unwrap_or("").to_string();

                let password_hash = v
                    .get("password_hash")
                    .and_then(|s| s.as_str())
                    .unwrap_or("")
                    .to_string();

                let created_at = v
                    .get("created_at")
                    .and_then(|s| s.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_default();

                let is_admin = v
                    .get("is_admin")
                    .and_then(|s| s.as_bool())
                    .unwrap_or(false);

                // Проверяю пароль
                if !Self::verify_password(&password, &password_hash) {
                    println!("[LOGIN] Неверный пароль для: {}", login);
                    return Ok(Response::new(AuthResponse {
                        success: false,
                        message: "Неверный логин или пароль".to_string(),
                        player: None,
                        token: String::new(),
                        is_admin: false,
                    }));
                }

                // Генерирую JWT с is_admin
                let token = match self.jwt.create_token(&id, &login, is_admin) {
                    Ok(t) => t,
                    Err(e) => {
                        println!("[LOGIN] Ошибка создания токена: {}", e);
                        String::new()
                    }
                };

                let player = Player {
                    id,
                    login: login.clone(),
                    email,
                    created_at,
                    is_admin,
                };

                println!("[LOGIN] Игрок вошёл: {} (токен выдан, is_admin={})", login, is_admin);

                Ok(Response::new(AuthResponse {
                    success: true,
                    message: "Вход успешен".to_string(),
                    player: Some(player),
                    token,
                    is_admin,
                }))
            }
            None => Ok(Response::new(AuthResponse {
                success: false,
                message: "Неверный логин или пароль".to_string(),
                player: None,
                token: String::new(),
                is_admin: false,
            })),
        }
    }

    // Получить игрока по ID
    async fn get_player(
        &self,
        mut request: Request<GetPlayerRequest>,
    ) -> Result<Response<AuthResponse>, Status> {
        // Здесь нет интерцептора, поэтому проверяю токен сама
        let claims = crate::request_auth::authenticate(&request, &self.jwt)?;
        request.extensions_mut().insert(claims);
        let player_id = crate::request_auth::player_id(&request, &request.get_ref().player_id)?;

        println!("[GET_PLAYER] player={}", player_id);

        // Ищу игрока
        let mut response = self
            .db
            .query("SELECT * FROM type::record($player_id) LIMIT 1")
            .bind(("player_id", player_id.clone()))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let result: Option<Value> = response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        match result {
            Some(v) => {
                let id = v
                    .get("id")
                    .and_then(|s| s.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_default();

                let login = v.get("login").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let email = v.get("email").and_then(|s| s.as_str()).unwrap_or("").to_string();

                let created_at = v
                    .get("created_at")
                    .and_then(|s| s.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_default();

                let is_admin = v
                    .get("is_admin")
                    .and_then(|s| s.as_bool())
                    .unwrap_or(false);

                let player = Player {
                    id,
                    login,
                    email,
                    created_at,
                    is_admin,
                };

                Ok(Response::new(AuthResponse {
                    success: true,
                    message: "Игрок найден".to_string(),
                    player: Some(player),
                    token: String::new(),
                    is_admin,
                }))
            }
            None => Ok(Response::new(AuthResponse {
                success: false,
                message: "Игрок не найден".to_string(),
                player: None,
                token: String::new(),
                is_admin: false,
            })),
        }
    }
}

#[cfg(test)]
#[path = "auth_tests.rs"]
mod tests; // Проверки уникальности регистрации
