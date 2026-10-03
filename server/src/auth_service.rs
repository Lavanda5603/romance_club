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