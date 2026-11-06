use surrealdb::{Surreal, engine::remote::ws::Client}; // Подключаю работу с SurrealDB
use tonic::Status; // Подключаю ошибки gRPC

// Оставляю списки record ID внутри БД и удаляю дерево одной транзакцией
pub async fn delete(db: &Surreal<Client>, id: i32) -> Result<(), Status> {
    if id <= 0 { return Err(Status::invalid_argument("Неверный ID эпизода")); }
    db.query("BEGIN TRANSACTION;
        LET $episode = type::record('episode',$id);
        LET $scenes = SELECT VALUE id FROM scene WHERE episode_id=$episode;
        LET $choices = SELECT VALUE id FROM choice WHERE scene_id IN $scenes;
        LET $actions = SELECT VALUE id FROM action WHERE choice_id IN $choices;
        DELETE $actions;
        DELETE $choices;
        DELETE $scenes;
        DELETE $episode;
        COMMIT TRANSACTION;")
        .bind(("id",i64::from(id))).await
        .map_err(|error|Status::internal(error.to_string()))?
        .check().map_err(|error|Status::internal(error.to_string()))?;
    Ok(())
}

#[cfg(test)]
#[path = "episode_delete_tests.rs"]
mod tests;
