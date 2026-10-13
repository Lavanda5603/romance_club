use tonic::{Request, Response, Status}; // Импорт tonic
use surrealdb::engine::remote::ws::Client; // Импорт клиента SurrealDB
use surrealdb::Surreal; // Импорт Surreal
use serde_json::Value; // Импорт Value
use crate::jwt; // Модуль JWT
use crate::romance_club::admin_api_server::AdminApi; // Импорт трейта AdminApi
use crate::romance_club::{
    AdminDeleteAssetRequest, AdminDeleteEpisodeRequest, AdminResponse,
}; // Импорт структур

// Сервис для админ-операций
pub struct AdminApiService {
    db: Surreal<Client>, // Подключение к SurrealDB
}

impl AdminApiService {
    // Создать новый сервис
    pub fn new(db: Surreal<Client>) -> Self {
        Self { db }
    }

    // Проверить, что запрос от админа
    fn check_admin<T>(request: &Request<T>) -> Result<(), Status> {
        // Достаю токен из метаданных
        let token = request
            .metadata()
            .get("authorization")
            .and_then(|v| v.to_str().ok())
            .map(|s| s.trim_start_matches("Bearer ").to_string());

        let token = match token {
            Some(t) => t,
            None => {
                return Err(Status::unauthenticated("Требуется авторизация"));
            }
        };

        // Проверяю токен
        let claims = jwt::verify_token(&token)
            .map_err(|e| Status::unauthenticated(format!("Неверный токен: {}", e)))?;

        // Проверяю is_admin
        if !claims.is_admin {
            println!("[ADMIN] Отказ: {} не админ", claims.login);
            return Err(Status::permission_denied("Только админ может выполнить это действие"));
        }

        println!("[ADMIN] Проверка пройдена: {} (админ)", claims.login);
        Ok(())
    }
}

#[tonic::async_trait]
impl AdminApi for AdminApiService {
    // Удалить ассет
    async fn delete_asset(
        &self,
        request: Request<AdminDeleteAssetRequest>,
    ) -> Result<Response<AdminResponse>, Status> {
        // Проверяю админа
        Self::check_admin(&request)?;

        let id = request.into_inner().asset_id;

        println!("[ADMIN_DELETE_ASSET] Удаляю ассет: {}", id);

        if id.is_empty() {
            return Err(Status::invalid_argument("ID обязателен"));
        }

        // Удаляю (DELETE $id - принимает строку напрямую)
        self.db
            .query("DELETE $id")
            .bind(("id", id.clone()))
            .await
            .map_err(|e| {
                println!("[ADMIN_DELETE_ASSET] ОШИБКА: {}", e);
                Status::internal(format!("Ошибка удаления: {}", e))
            })?;

        println!("[ADMIN_DELETE_ASSET] Ассет удалён: {}", id);

        Ok(Response::new(AdminResponse {
            success: true,
            message: "Ассет удалён".to_string(),
        }))
    }

    // Удалить эпизод
    async fn delete_episode(
        &self,
        request: Request<AdminDeleteEpisodeRequest>,
    ) -> Result<Response<AdminResponse>, Status> {
        // Проверяю админа
        Self::check_admin(&request)?;

        let id = request.into_inner().episode_id;
        let id_i64 = id as i64;

        println!("[ADMIN_DELETE_EPISODE] Удаляю эпизод ID: {}", id);

        // 1. Удаляю действия (в два шага)
        {
            let mut ids_response = self
                .db
                .query("SELECT VALUE id FROM action WHERE choice_id IN (SELECT VALUE id FROM choice WHERE scene_id IN (SELECT VALUE id FROM scene WHERE episode_id = type::record('episode', $id)))")
                .bind(("id", id_i64))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            let ids: Vec<Value> = ids_response.take(0).map_err(|e| Status::internal(e.to_string()))?;

            if !ids.is_empty() {
                self.db
                    .query("DELETE $ids")
                    .bind(("ids", ids))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;
            }
        }

        // 2. Удаляю выборы (в два шага)
        {
            let mut ids_response = self
                .db
                .query("SELECT VALUE id FROM choice WHERE scene_id IN (SELECT VALUE id FROM scene WHERE episode_id = type::record('episode', $id))")
                .bind(("id", id_i64))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            let ids: Vec<Value> = ids_response.take(0).map_err(|e| Status::internal(e.to_string()))?;

            if !ids.is_empty() {
                self.db
                    .query("DELETE $ids")
                    .bind(("ids", ids))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;
            }
        }

        // 3. Удаляю сцены (в два шага)
        {
            let mut ids_response = self
                .db
                .query("SELECT VALUE id FROM scene WHERE episode_id = type::record('episode', $id)")
                .bind(("id", id_i64))
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            let ids: Vec<Value> = ids_response.take(0).map_err(|e| Status::internal(e.to_string()))?;

            if !ids.is_empty() {
                self.db
                    .query("DELETE $ids")
                    .bind(("ids", ids))
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;
            }
        }

        // 4. Удаляю эпизод
        self.db
            .query("DELETE type::record('episode', $id)")
            .bind(("id", id_i64))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        println!("[ADMIN_DELETE_EPISODE] Эпизод удалён");

        Ok(Response::new(AdminResponse {
            success: true,
            message: "Эпизод удалён".to_string(),
        }))
    }
}