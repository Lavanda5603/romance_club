use tonic::{Request, Response, Status};
use surrealdb::engine::remote::ws::Client;
use surrealdb::Surreal;
use serde_json::Value;
use crate::romance_club::achievement_api_server::AchievementApi;
use crate::romance_club::{
    Achievement, GetAchievementsRequest, GetAchievementsResponse,
    UnlockAchievementRequest, UnlockAchievementResponse,
};

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
        let req = request.into_inner();
        let player_id = req.player_id;

        println!("[GET_ACHIEVEMENTS] player={}", player_id);

        // Запрашиваю достижения игрока
        let mut response = self
            .db
            .query("SELECT * FROM achievement WHERE player_id = type::record($player_id)")
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
        let req = request.into_inner();
        let player_id = req.player_id;
        let name = req.name;

        println!("[UNLOCK_ACHIEVEMENT] player={}, name={}", player_id, name);

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
        let result = self
            .db
            .query("CREATE achievement CONTENT { player_id: type::record($player_id), name: $name, unlocked_at: time::now() }")
            .bind(("player_id", player_id.clone()))
            .bind(("name", name.clone()))
            .await;

        match result {
            Ok(_) => println!("[UNLOCK_ACHIEVEMENT] Открыто: {}", name),
            Err(e) => println!("[UNLOCK_ACHIEVEMENT] ОШИБКА: {}", e),
        }

        Ok(Response::new(UnlockAchievementResponse {
            success: true,
            message: "Достижение открыто".to_string(),
        }))
    }
}