use std::collections::{HashMap, HashSet};
use serde_json::{json, Value};
use surrealdb::{engine::remote::ws::Client, Surreal};
use tonic::Status;
use crate::romance_club::Episode;

pub async fn save(db: &Surreal<Client>, episode: &Episode) -> Result<(), Status> {
    if episode.id <= 0 {
        return Err(Status::invalid_argument("Неверный ID эпизода"));
    }

    // Читаю настоящие ID, чтобы сохранить ссылки на существующие сцены
    let mut response = db.query("SELECT id, episode_id FROM scene")
        .await.map_err(|e| Status::internal(e.to_string()))?;
    let records: Vec<Value> = response.take(0)
        .map_err(|e| Status::internal(e.to_string()))?;
    let episode_key = format!("episode:{}", episode.id);
    let existing: HashSet<String> = records.iter()
        .filter(|r| r["episode_id"].as_str() == Some(episode_key.as_str()))
        .filter_map(|r| r["id"].as_str().map(str::to_owned)).collect();
    let mut next_id = records.iter().filter_map(|r| r["id"].as_str())
        .filter_map(|id| id.strip_prefix("scene:"))
        .filter_map(|id| id.parse::<i32>().ok()).max().unwrap_or(0);
    let mut keys = Vec::new();
    let mut seen = HashSet::new();
    let mut new_ids = HashMap::new();
    for scene in &episode.scenes {
        let key = if scene.scene_key.is_empty() {
            next_id = next_id.checked_add(1)
                .ok_or_else(|| Status::invalid_argument("Закончились ID сцен"))?;
            if new_ids.insert(scene.id, next_id).is_some() {
                return Err(Status::invalid_argument("Повторяется ID новой сцены"));
            }
            format!("scene:{}", next_id)
        } else {
            if !existing.contains(&scene.scene_key) {
                return Err(Status::invalid_argument("Сцена не найдена в этом эпизоде"));
            }
            scene.scene_key.clone()
        };
        if !seen.insert(key.clone()) {
            return Err(Status::invalid_argument("Сцена передана дважды"));
        }
        keys.push(key);
    }
    let target = |id: i32| *new_ids.get(&id).unwrap_or(&id);
    let scenes: Vec<Value> = episode.scenes.iter().enumerate().map(|(order, scene)| {
        let choices: Vec<Value> = scene.choices.iter().enumerate().map(|(index, choice)| {
            let actions: Vec<Value> = choice.actions.iter().map(|action| json!({
                "type": action.r#type, "scene_id": target(action.scene_id),
                "flag_name": action.flag_name, "flag_value": action.flag_value,
                "counter_name": action.counter_name, "counter_value": action.counter_value,
                "sound_path": action.sound_path, "image_path": action.image_path,
                "title": action.title
            })).collect();
            json!({"text":choice.text,"title":choice.title,"order_index":index,"actions":actions})
        }).collect();
        json!({
            "key":keys[order],"is_new":scene.scene_key.is_empty(),
            "title":scene.title,"background":scene.background,"character":scene.character,
            "character_emotion":scene.character_emotion,"texts":scene.texts,
            "condition":scene.condition,"text_position":scene.text_position,
            "character_position":scene.character_position,"order_index":order,
            "next_scene_id":target(scene.next_scene_id),"choices":choices
        })
    }).collect();

    // Все изменения выполняю вместе. При ошибке база откатывает транзакцию
    db.query(include_str!("save_episode.surql"))
        .bind(("episode_id", episode.id))
        .bind(("title", episode.title.clone()))
        .bind(("version", episode.version))
        .bind(("scenes", scenes))
        .bind(("scene_keys", keys))
        .await.map_err(|e| Status::internal(e.to_string()))?
        .check().map_err(|e| Status::internal(e.to_string()))?;
    Ok(())
}