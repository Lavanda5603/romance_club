use tonic::{Request, Response, Status};
use surrealdb::engine::remote::ws::Client;
use surrealdb::Surreal;
use serde_json::Value;
use crate::romance_club::progress_api_server::ProgressApi;
use crate::romance_club::{
    Progress, GetProgressRequest, SaveProgressRequest, SaveProgressResponse,
};

// Сервис для работы с прогрессом
pub struct ProgressApiService {
    pub db: Surreal<Client>, // Подключение к SurrealDB
}

impl ProgressApiService {
    // Создать новый сервис
    pub fn new(db: Surreal<Client>) -> Self {
        Self { db }
    }
}

#[tonic::async_trait]
impl ProgressApi for ProgressApiService {
    // Получить прогресс игрока по эпизоду
    async fn get_progress(
        &self,
        request: Request<GetProgressRequest>,
    ) -> Result<Response<Progress>, Status> {
        let req = request.into_inner();
        let player_id = req.player_id;
        let episode_id = req.episode_id;

        println!("[GET_PROGRESS] player={}, episode={}", player_id, episode_id);

        // Запрашиваю прогресс через query
        let mut response = self
            .db
            .query("SELECT * FROM progress WHERE player_id = type::record('player', $player_id) AND episode_id = type::record('episode', $episode_id) LIMIT 1")
            .bind(("player_id", player_id))
            .bind(("episode_id", episode_id))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        // Парсю ответ как Value
        let result: Option<Value> = response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        // Если прогресса нет - возвращаю пустой
        let progress = match result {
            Some(v) => {
                // Извлекаю scene_id как строку
                let scene_id = v
                    .get("scene_id")
                    .and_then(|s| s.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_default();
                let flags = v.get("flags").cloned().unwrap_or(serde_json::json!({}));
                let counters = v.get("counters").cloned().unwrap_or(serde_json::json!({}));

                // Преобразую flags
                let mut flags_map = std::collections::HashMap::new();
                if let Some(obj) = flags.as_object() {
                    for (k, val) in obj {
                        if let Some(b) = val.as_bool() {
                            flags_map.insert(k.clone(), b);
                        }
                    }
                }

                // Преобразую counters
                let mut counters_map = std::collections::HashMap::new();
                if let Some(obj) = counters.as_object() {
                    for (k, val) in obj {
                        if let Some(n) = val.as_i64() {
                            counters_map.insert(k.clone(), n as i32);
                        }
                    }
                }

                Progress {
                    id: 0,
                    player_id,
                    episode_id,
                    scene_id,
                    flags: flags_map,
                    counters: counters_map,
                    updated_at: String::new(),
                }
            }
            None => Progress {
                id: 0,
                player_id,
                episode_id,
                scene_id: String::new(),
                flags: std::collections::HashMap::new(),
                counters: std::collections::HashMap::new(),
                updated_at: String::new(),
            },
        };

        Ok(Response::new(progress))
    }

    // Сохранить прогресс
    async fn save_progress(
        &self,
        request: Request<SaveProgressRequest>,
    ) -> Result<Response<SaveProgressResponse>, Status> {
        let req = request.into_inner();
        let player_id = req.player_id;
        let episode_id = req.episode_id;
        let scene_id = req.scene_id;
        let flags = req.flags;
        let counters = req.counters;

        println!("[SAVE_PROGRESS] player={}, episode={}, scene={}", player_id, episode_id, scene_id);

        // Преобразую flags и counters в JSON
        let flags_json: serde_json::Value = serde_json::to_value(&flags)
            .unwrap_or(serde_json::json!({}));
        let counters_json: serde_json::Value = serde_json::to_value(&counters)
            .unwrap_or(serde_json::json!({}));

        // Удаляю старый прогресс
        self.db
            .query("DELETE progress WHERE player_id = type::record('player', $player_id) AND episode_id = type::record('episode', $episode_id)")
            .bind(("player_id", player_id))
            .bind(("episode_id", episode_id))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        // Создаю новый прогресс (scene_id - RecordId через type::record)
        let result = self.db
            .query("CREATE progress CONTENT { player_id: type::record('player', $player_id), episode_id: type::record('episode', $episode_id), scene_id: type::record($scene_id), flags: $flags, counters: $counters, updated_at: time::now() }")
            .bind(("player_id", player_id))
            .bind(("episode_id", episode_id))
            .bind(("scene_id", scene_id))
            .bind(("flags", flags_json))
            .bind(("counters", counters_json))
            .await;

        // Отладка: показываю результат
        match result {
            Ok(_) => println!("[SAVE_PROGRESS] Прогресс создан"),
            Err(e) => println!("[SAVE_PROGRESS] ОШИБКА: {}", e),
        }

        Ok(Response::new(SaveProgressResponse {
            success: true,
            message: "Прогресс сохранён".to_string(),
        }))
    }
}