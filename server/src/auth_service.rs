use tonic::{Request, Response, Status};
use surrealdb::engine::remote::ws::Client;
use surrealdb::Surreal;
use serde_json::Value;
use crate::romance_club::auth_api_server::AuthApi;
use crate::romance_club::{
    AuthResponse, RegisterRequest, LoginRequest, Player,
};

// Сервис для работы с авторизацией
pub struct AuthApiService {
    pub db: Surreal<Client>, // Подключение к SurrealDB
}

impl AuthApiService {
    // Создать новый сервис
    pub fn new(db: Surreal<Client>) -> Self {
        Self { db }
    }

    // Проверка логина
    fn validate_login(login: &str) -> Option<String> {
        if login.is_empty() {
            return Some("Введите логин".to_string());
        }
        if login.len() < 3 {
            return Some("Логин должен быть не менее 3 символов".to_string());
        }
        // Только английские буквы, цифры, _
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
        // Должен содержать @ и точку после @
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
        // Английская буква
        if !password.chars().any(|c| c.is_ascii_alphabetic()) {
            return Some("Пароль должен содержать английскую букву".to_string());
        }
        // Цифра
        if !password.chars().any(|c| c.is_ascii_digit()) {
            return Some("Пароль должен содержать цифру".to_string());
        }
        // Спецсимвол
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

        // Валидация логина
        if let Some(err) = Self::validate_login(&login) {
            return Ok(Response::new(AuthResponse {
                success: false,
                message: err,
                player: None,
            }));
        }

        // Валидация email
        if let Some(err) = Self::validate_email(&email) {
            return Ok(Response::new(AuthResponse {
                success: false,
                message: err,
                player: None,
            }));
        }

        // Валидация пароля
        if let Some(err) = Self::validate_password(&password) {
            return Ok(Response::new(AuthResponse {
                success: false,
                message: err,
                player: None,
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

        // Если игрок есть - ошибка
        if existing.is_some() {
            return Ok(Response::new(AuthResponse {
                success: false,
                message: "Игрок с таким логином уже существует".to_string(),
                player: None,
            }));
        }

        // Создаю игрока
        let mut create_response = self
            .db
            .query("CREATE player CONTENT { login: $login, email: $email, password_hash: $password, created_at: time::now() } RETURN id, login, email")
            .bind(("login", login.clone()))
            .bind(("email", email.clone()))
            .bind(("password", password))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let result: Option<Value> = create_response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        match result {
            Some(v) => {
                // Извлекаю ID игрока как строку
                let id = v
                    .get("id")
                    .and_then(|s| s.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_default();

                let player = Player {
                    id,
                    login: login.clone(),
                    email: email.clone(),
                    created_at: String::new(),
                };

                println!("[REGISTER] Игрок создан: {}", login);

                Ok(Response::new(AuthResponse {
                    success: true,
                    message: "Регистрация успешна".to_string(),
                    player: Some(player),
                }))
            }
            None => Ok(Response::new(AuthResponse {
                success: false,
                message: "Ошибка создания игрока".to_string(),
                player: None,
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

        // Валидация логина
        if let Some(err) = Self::validate_login(&login) {
            return Ok(Response::new(AuthResponse {
                success: false,
                message: err,
                player: None,
            }));
        }

        // Валидация пароля
        if let Some(err) = Self::validate_password(&password) {
            return Ok(Response::new(AuthResponse {
                success: false,
                message: err,
                player: None,
            }));
        }

        // Ищу игрока с таким логином и паролем
        let mut response = self
            .db
            .query("SELECT * FROM player WHERE login = $login AND password_hash = $password LIMIT 1")
            .bind(("login", login.clone()))
            .bind(("password", password))
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

                let player = Player {
                    id,
                    login: login.clone(),
                    email,
                    created_at: String::new(),
                };

                println!("[LOGIN] Игрок найден: {}", login);

                Ok(Response::new(AuthResponse {
                    success: true,
                    message: "Вход успешен".to_string(),
                    player: Some(player),
                }))
            }
            None => Ok(Response::new(AuthResponse {
                success: false,
                message: "Неверный логин или пароль".to_string(),
                player: None,
            })),
        }
    }
}