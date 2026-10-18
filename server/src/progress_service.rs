use tonic::{Request, Response, Status}; // Импорт tonic
use surrealdb::engine::remote::ws::Client; // Импорт клиента SurrealDB
use surrealdb::Surreal; // Импорт Surreal
use serde_json::Value; // Импорт Value
use crate::romance_club::progress_api_server::ProgressApi; // Импорт трейта
use crate::romance_club::{
    Progress, GetProgressRequest, SaveProgressRequest, SaveProgressResponse,
    ResetProgressRequest, ResetProgressResponse,
    GetProgressSummaryRequest, GetProgressSummaryResponse,
}; // Импорт структур

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
    async fn get_progress_summary(
        &self,
        request: Request<GetProgressSummaryRequest>,
    ) -> Result<Response<GetProgressSummaryResponse>, Status> {
        let player_id = crate::request_auth::player_id(&request, &request.get_ref().player_id)?;
        // Для списка нужны только ID, без флагов и счётчиков каждого эпизода
        let mut response = self.db.query("SELECT VALUE episode_id FROM progress WHERE player_id = type::record($player_id) AND completed = true AND record::exists(episode_id)")
            .bind(("player_id", player_id)).await.map_err(|e| Status::internal(e.to_string()))?
            .check().map_err(|e| Status::internal(e.to_string()))?;
        let records: Vec<Value> = response.take(0).map_err(|e| Status::internal(e.to_string()))?;
        let mut episode_ids: Vec<i32> = records.iter()
            .filter_map(|value| value.as_str()?.strip_prefix("episode:")?.parse::<i32>().ok())
            .filter(|id| *id > 0).collect();
        episode_ids.sort_unstable();
        episode_ids.dedup();
        Ok(Response::new(GetProgressSummaryResponse { episode_ids }))
    }

    // Получить прогресс игрока по эпизоду
    async fn get_progress(
        &self,
        request: Request<GetProgressRequest>,
    ) -> Result<Response<Progress>, Status> {
        let player_id = crate::request_auth::player_id(&request, &request.get_ref().player_id)?;
        let req = request.into_inner();
        let episode_id = req.episode_id;

        println!("[GET_PROGRESS] player={}, episode={}", player_id, episode_id);

        let mut response = self
            .db
            .query("SELECT * FROM type::record('progress', [type::record($player_id), type::record('episode', $episode_id)])")
            .bind(("player_id", player_id.clone()))
            .bind(("episode_id", episode_id))
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let result: Option<Value> = response
            .take(0)
            .map_err(|e| Status::internal(e.to_string()))?;

        let progress = match result {
            Some(v) => {
                let scene_id = v
                    .get("scene_id")
                    .and_then(|s| s.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_default();
                let flags = v.get("flags").cloned().unwrap_or(serde_json::json!({}));
                let counters = v.get("counters").cloned().unwrap_or(serde_json::json!({}));

                let mut flags_map = std::collections::HashMap::new();
                if let Some(obj) = flags.as_object() {
                    for (k, val) in obj {
                        if let Some(b) = val.as_bool() {
                            flags_map.insert(k.clone(), b);
                        }
                    }
                }

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
                    player_id: player_id.clone(),
                    episode_id,
                    scene_id,
                    flags: flags_map,
                    counters: counters_map,
                    updated_at: v.get("updated_at").and_then(Value::as_str).unwrap_or_default().to_owned(),
                    completed: v.get("completed").and_then(Value::as_bool).unwrap_or(false),
                    revision: v.get("revision").and_then(Value::as_i64).unwrap_or(0) as i32,
                }
            }
            None => Progress {
                id: 0,
                player_id: player_id.clone(),
                episode_id,
                scene_id: String::new(),
                flags: std::collections::HashMap::new(),
                counters: std::collections::HashMap::new(),
                updated_at: String::new(),
                revision: 0,
                completed: false,
            },
        };

        Ok(Response::new(progress))
    }

    // Сохранить прогресс
    async fn save_progress(
        &self,
        request: Request<SaveProgressRequest>,
    ) -> Result<Response<SaveProgressResponse>, Status> {
        let player_id = crate::request_auth::player_id(&request, &request.get_ref().player_id)?;
        let req = request.into_inner();
        let episode_id = req.episode_id;
        let scene_id = req.scene_id;
        let flags = req.flags;
        let counters = req.counters;

        println!("[SAVE_PROGRESS] player={}, episode={}, scene={}", player_id, episode_id, scene_id);

        let flags_json: serde_json::Value = serde_json::to_value(&flags)
            .unwrap_or(serde_json::json!({}));
        let counters_json: serde_json::Value = serde_json::to_value(&counters)
            .unwrap_or(serde_json::json!({}));

        let revision = req.expected_revision.checked_add(1)
            .filter(|_| req.expected_revision >= 0)
            .ok_or_else(|| Status::invalid_argument("Неверная версия прогресса"))?;
        if episode_id <= 0 || !scene_id.starts_with("scene:") {
            return Err(Status::invalid_argument("Неверная сцена или эпизод"));
        }

        // Проверяю версию и обновляю постоянную запись в одной транзакции
        let mut result = self.db.query(include_str!("save_progress.surql"))
            .bind(("player_id", player_id))
            .bind(("episode_id", episode_id))
            .bind(("scene_id", scene_id))
            .bind(("completed", req.completed))
            .bind(("flags", flags_json))
            .bind(("counters", counters_json))
            .bind(("expected_revision", req.expected_revision))
            .await.map_err(|e| Status::internal(e.to_string()))?;
        let errors = result.take_errors();
        if !errors.is_empty() {
            let messages = errors.values().map(ToString::to_string).collect::<Vec<_>>().join("; ");
            if messages.contains("PROGRESS_CONFLICT") || errors.values().any(|e| matches!(e.query_details(), Some(surrealdb::types::QueryError::TransactionConflict))) {
                return Err(Status::aborted("Прогресс изменился в другом окне. Загрузите эпизод заново"));
            }
            if messages.contains("PROGRESS_SCENE_INVALID") {
                return Err(Status::invalid_argument("Сцена не принадлежит эпизоду"));
            }
            return Err(Status::internal(messages));
        }
        result.check().map_err(|e| Status::internal(e.to_string()))?;

        Ok(Response::new(SaveProgressResponse {
            success: true,
            message: "Прогресс сохранён".to_string(),
            revision,
        }))
    }

    // Сбросить прогресс игрока
    async fn reset_progress(
        &self,
        request: Request<ResetProgressRequest>,
    ) -> Result<Response<ResetProgressResponse>, Status> {
        let player_id = crate::request_auth::player_id(&request, &request.get_ref().player_id)?;

        println!("[RESET_PROGRESS] player={}", player_id);

        // Оставляю версию сброса, чтобы старый клиент не вернул прежний прогресс
        self.db
            .query("UPDATE progress SET scene_id = NONE, completed = false, flags = {}, counters = {}, revision = (revision ?? 0) + 1, updated_at = time::now() WHERE player_id = type::record($player_id)")
            .bind(("player_id", player_id))
            .await.map_err(|e| Status::internal(e.to_string()))?
            .check().map_err(|e| Status::internal(e.to_string()))?;

        Ok(Response::new(ResetProgressResponse {
            success: true,
            message: "Прогресс сброшен".to_string(),
        }))
    }
}

#[cfg(test)]
#[path = "progress_tests.rs"]
mod tests;
