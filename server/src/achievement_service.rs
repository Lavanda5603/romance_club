use tonic::{Request, Response, Status}; // Импорт tonic
use surrealdb::engine::remote::ws::Client; // Импорт клиента SurrealDB
use surrealdb::Surreal; // Импорт Surreal
use serde_json::Value; // Импорт Value
use crate::romance_club::achievement_api_server::AchievementApi; // Импорт трейта
use crate::romance_club::{
    Achievement, GetAchievementsRequest, GetAchievementsResponse,
    UnlockAchievementRequest, UnlockAchievementResponse,
}; // Импорт структур

// Сервис для работы с достижениями
pub struct AchievementApiService {
    pub db: Surreal<Client>, // Подключение к SurrealDB
}

impl AchievementApiService {
    // Создать новый сервис
    pub fn new(db: Surreal<Client>) -> Self {
        Self { db }
    }
}

#[tonic::async_trait]
impl AchievementApi for AchievementApiService {
    // Получить все достижения игрока (открытые)
    async fn get_achievements(
        &self,
        request: Request<GetAchievementsRequest>,
    ) -> Result<Response<GetAchievementsResponse>, Status> {
        let player_id = crate::request_auth::player_id(&request, &request.get_ref().player_id)?;

        println!("[GET_ACHIEVEMENTS] player={}", player_id);

        // Запрашиваю достижения игрока
        let mut response = self
            .db
            .query("SELECT * FROM achievement WHERE player_id = type::record($player_id) AND (name NOT IN ['all_episodes', 'all_endings'] OR fn::can_unlock_all(type::record($player_id), name))")
            .bind(("player_id", player_id.clone()))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let values: Vec<Value> = response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        // Собираю достижения
        let achievements = values
            .into_iter()
            .map(|v| {
                let name = v.get("name").and_then(|s| s.as_str()).unwrap_or("").to_string();
                let unlocked_at = v
                    .get("unlocked_at")
                    .and_then(|s| s.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_default();

                Achievement { name, unlocked_at }
            })
            .collect();

        Ok(Response::new(GetAchievementsResponse { achievements }))
    }

    // Открыть достижение
    async fn unlock_achievement(
        &self,
        request: Request<UnlockAchievementRequest>,
    ) -> Result<Response<UnlockAchievementResponse>, Status> {
        let player_id = crate::request_auth::player_id(&request, &request.get_ref().player_id)?;
        let req = request.into_inner();
        let name = req.name;
        // Разрешаю только достижения, которые существуют в приложении.
        if !matches!(name.as_str(), "all_episodes" | "all_endings" | "max_points" | "secret_scene" | "all_friends") {
            return Err(Status::invalid_argument("Неизвестное достижение"));
        }

        println!("[UNLOCK_ACHIEVEMENT] player={}, name={}", player_id, name);

        // Для достижений «все» проверяю всю историю игрока
        if matches!(name.as_str(), "all_episodes" | "all_endings") {
            let mut response = self.db.query("RETURN fn::can_unlock_all(type::record($player_id), $name);")
                .bind(("player_id", player_id.clone())).bind(("name", name.clone()))
                .await.map_err(|e| Status::internal(e.to_string()))?
                .check().map_err(|e| Status::internal(e.to_string()))?;
            let allowed: Option<bool> = response.take(0).map_err(|e| Status::internal(e.to_string()))?;
            if allowed != Some(true) { return Err(Status::failed_precondition("Условия достижения ещё не выполнены")); }
        }

        // Проверяю, есть ли уже такое достижение
        let mut check_response = self
            .db
            .query("SELECT * FROM achievement WHERE player_id = type::record($player_id) AND name = $name LIMIT 1")
            .bind(("player_id", player_id.clone()))
            .bind(("name", name.clone()))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let existing: Option<Value> = check_response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        // Если достижение уже открыто - возвращаю успех
        if existing.is_some() {
            return Ok(Response::new(UnlockAchievementResponse {
                success: true,
                message: "Достижение уже открыто".to_string(),
            }));
        }

        // Создаю достижение
        let mut result = self
            .db
            .query("CREATE achievement CONTENT { player_id: type::record($player_id), name: $name, unlocked_at: time::now() } RETURN AFTER")
            .bind(("player_id", player_id.clone()))
            .bind(("name", name.clone()))
            .await.map_err(|e| Status::internal(e.to_string()))?
            .check().map_err(|e| Status::internal(e.to_string()))?;
        let saved: Vec<Value> = result.take(0).map_err(|e| Status::internal(e.to_string()))?;
        if saved.len() != 1 {
            return Err(Status::internal("Достижение не сохранено"));
        }
        println!("[UNLOCK_ACHIEVEMENT] Открыто: {}", name);

        Ok(Response::new(UnlockAchievementResponse {
            success: true,
            message: "Достижение открыто".to_string(),
        }))
    }
}
#[cfg(test)]
#[path = "achievement_tests.rs"]
mod tests;