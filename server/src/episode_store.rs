use std::collections::{HashMap, HashSet}; // Подключаю стандартные классы Rust
use serde_json::{json, Value}; // Подключаю работу с JSON
use surrealdb::{engine::remote::ws::Client, Surreal}; // Подключаю работу с SurrealDB
use tonic::Status; // Подключаю запросы, ответы и ошибки gRPC
use uuid::Uuid; // Подключаю создание уникальных ID
use crate::romance_club::Episode; // Подключаю модули сервера

// Читаю старые числовые переходы, если строкового ключа ещё нет
pub fn target_key(key: Option<&str>, id: i32) -> String {
    key.map(str::to_owned).unwrap_or_else(|| if id > 0 { format!("scene:{id}") } else { String::new() })
}

pub async fn save(db: &Surreal<Client>, episode: &Episode) -> Result<(), Status> {
    if episode.id <= 0 {
        return Err(Status::invalid_argument("Неверный ID эпизода"));
    }
    // Читаю настоящие ID, чтобы сохранить ссылки на существующие сцены
    let mut response = db.query("SELECT id, episode_id FROM scene")
        .await.map_err(|e| Status::internal(e.to_string()))?;
    let records: Vec<Value> = response.take(0)
        .map_err(|e| Status::internal(e.to_string()))?;
    let scenes = prepare_scenes(episode, &records)?;
    let keys: Vec<String> = scenes.iter().filter_map(|s| s["key"].as_str().map(str::to_owned)).collect();
    // Все изменения выполняю вместе. При ошибке база откатывает транзакцию
    let mut response = db.query(include_str!("save_episode.surql"))
        .bind(("episode_id", episode.id))
        .bind(("title", episode.title.clone()))
        .bind(("version", episode.version))
        .bind(("scenes", scenes))
        .bind(("scene_keys", keys))
        .await.map_err(|e| Status::internal(e.to_string()))?;
    // Ищу причину во всех ответах: первый может сообщать только об откате
    let errors = response.take_errors();
    if errors.values().any(|error| error.to_string().contains("SCENE_HAS_PROGRESS")) {
        return Err(Status::failed_precondition("Нельзя удалить сцену, на которой есть сохранённый прогресс игроков. Изменения эпизода не сохранены"));
    }
    if let Some((_, error)) = errors.into_iter().min_by_key(|(index, _)| *index) {
        return Err(Status::internal(error.to_string()));
    }
    Ok(())
}

fn prepare_scenes(episode: &Episode, records: &[Value]) -> Result<Vec<Value>, Status> {
    let episode_key = format!("episode:{}", episode.id);
    let existing: HashSet<String> = records.iter()
        .filter(|r| r["episode_id"].as_str() == Some(episode_key.as_str()))
        .filter_map(|r| r["id"].as_str().map(str::to_owned)).collect();
    let mut keys = Vec::new();
    let mut seen = HashSet::new();
    let mut drafts = HashMap::new();
    let mut legacy_ids = HashMap::new();
    for scene in &episode.scenes {
        let is_new = scene.scene_key.is_empty() || scene.scene_key.starts_with("draft:");
        let key = if is_new {
            // Новый ключ не должен повторять ID удалённой сцены
            let key = format!("scene:s_{}", Uuid::new_v4().simple());
            if !scene.scene_key.is_empty() && drafts.insert(scene.scene_key.clone(), key.clone()).is_some() {
                return Err(Status::invalid_argument("Повторяется ключ новой сцены"));
            }
            key
        } else {
            if !existing.contains(&scene.scene_key) {
                return Err(Status::invalid_argument("Сцена не найдена в этом эпизоде"));
            }
            scene.scene_key.clone()
        };
        // Старые клиенты ещё могут передавать переходы числом
        if scene.id > 0 && legacy_ids.insert(scene.id, key.clone()).is_some() {
            return Err(Status::invalid_argument("Повторяется числовой ID сцены"));
        }
        if !seen.insert(key.clone()) {
            return Err(Status::invalid_argument("Сцена передана дважды"));
        }
        keys.push(key);
    }
    let resolve = |key: &str, id: i32| -> Result<String, Status> {
        let target = if !key.is_empty() {
            drafts.get(key).cloned().unwrap_or_else(|| key.to_owned())
        } else if id > 0 {
            legacy_ids.get(&id).cloned().unwrap_or_else(|| format!("scene:{id}"))
        } else { String::new() };
        if !target.is_empty() && !seen.contains(&target) {
            return Err(Status::invalid_argument("Переход ведёт на отсутствующую сцену или в другой эпизод"));
        }
        Ok(target)
    };
    let numeric_id = |key: &str| key.strip_prefix("scene:").and_then(|id| id.parse::<i32>().ok()).unwrap_or(0);
    let mut scenes = Vec::new();
    for (order, scene) in episode.scenes.iter().enumerate() {
        let next_key = resolve(&scene.next_scene_key, scene.next_scene_id)?;
        let routes = scene.routes.iter().map(|route| {
            if route.scene_key.is_empty() { return Err(Status::invalid_argument("Выберите сцену условного перехода")); }
            Ok(json!({"condition":route.condition,"scene_key":resolve(&route.scene_key,0)?}))
        }).collect::<Result<Vec<Value>,Status>>()?;
        let mut choices = Vec::new();
        for (index, choice) in scene.choices.iter().enumerate() {
            let mut actions = Vec::new();
            for action in &choice.actions {
                let key = if action.r#type == "nextScene" { resolve(&action.scene_key, action.scene_id)? } else { String::new() };
                actions.push(json!({
                    "type": action.r#type, "scene_id": numeric_id(&key), "scene_key": key,
                    "flag_name": action.flag_name, "flag_value": action.flag_value,
                    "counter_name": action.counter_name, "counter_value": action.counter_value,
                    "sound_path": action.sound_path, "image_path": action.image_path,
                    "title": action.title
                }));
            }
            choices.push(json!({"text":choice.text,"title":choice.title,"order_index":index,"actions":actions}));
        }
        scenes.push(json!({
            "key":keys[order],"is_new":scene.scene_key.is_empty() || scene.scene_key.starts_with("draft:"),
            "title":scene.title,"background":scene.background,"character":scene.character,
            "character_emotion":scene.character_emotion,"texts":scene.texts,
            "condition":scene.condition,"routes":routes,"text_position":scene.text_position,
            "character_position":scene.character_position,"order_index":order,
            "next_scene_id":numeric_id(&next_key),"next_scene_key":next_key,"choices":choices
        }));
    }
    Ok(scenes)
}

#[cfg(test)]
#[path = "episode_transaction_tests.rs"]
mod transaction_tests;

#[cfg(test)]
mod tests {
    use super::*;
    use crate::romance_club::{Scene, Choice, Action};

    fn record(key: &str, episode: i32) -> Value {
        json!({"id":key, "episode_id":format!("episode:{episode}")})
    }

    #[test]
    fn keep_numeric_and_string_keys_when_order_changes() {
        let episode = Episode { id:1, scenes:vec![
            Scene { scene_key:"scene:branch".into(), next_scene_key:"scene:200".into(), ..Default::default() },
            Scene { id:200, scene_key:"scene:200".into(), next_scene_key:"scene:branch".into(), choices:vec![Choice {
                actions:vec![Action { r#type:"nextScene".into(), scene_key:"scene:branch".into(), ..Default::default() }], ..Default::default()
            }], ..Default::default() },
        ], ..Default::default() };
        let prepared = prepare_scenes(&episode, &[record("scene:200",1),record("scene:branch",1)]).unwrap();
        assert_eq!(prepared[0]["key"],"scene:branch");
        assert_eq!(prepared[0]["order_index"],0);
        assert_eq!(prepared[0]["next_scene_key"],"scene:200");
        assert_eq!(prepared[1]["next_scene_key"],"scene:branch");
        assert_eq!(prepared[1]["choices"][0]["actions"][0]["scene_key"],"scene:branch");
    }

    #[test]
    fn remap_new_scene_keys_in_both_kinds_of_transition() {
        let episode = Episode { id:1, scenes:vec![
            Scene { scene_key:"draft:first".into(), next_scene_key:"draft:second".into(), choices:vec![Choice {
                actions:vec![Action { r#type:"nextScene".into(), scene_key:"draft:second".into(), ..Default::default() }], ..Default::default()
            }], ..Default::default() },
            Scene { scene_key:"draft:second".into(), next_scene_key:"draft:first".into(), ..Default::default() },
        ], ..Default::default() };
        let prepared = prepare_scenes(&episode, &[record("scene:900",2)]).unwrap();
        assert_ne!(prepared[0]["key"], prepared[1]["key"]);
        assert_eq!(prepared[0]["next_scene_key"],prepared[1]["key"]);
        assert_eq!(prepared[1]["next_scene_key"],prepared[0]["key"]);
        assert_eq!(prepared[0]["choices"][0]["actions"][0]["scene_key"],prepared[1]["key"]);
    }

    #[test]
    fn reject_missing_deleted_foreign_and_duplicate_scene_targets() {
        let records = [record("scene:200",1),record("scene:branch",1),record("scene:900",2)];
        for key in ["scene:missing","scene:branch","scene:900","draft:missing"] {
            let episode = Episode {id:1, scenes:vec![Scene {id:200,scene_key:"scene:200".into(),next_scene_key:key.into(),..Default::default()}],..Default::default()};
            assert_eq!(prepare_scenes(&episode,&records).unwrap_err().code(),tonic::Code::InvalidArgument);
            let mut episode = episode;
            episode.scenes[0].next_scene_key.clear();
            episode.scenes[0].choices.push(Choice { actions:vec![Action {r#type:"nextScene".into(),scene_key:key.into(),..Default::default()}],..Default::default() });
            assert!(prepare_scenes(&episode,&records).is_err());
        }
        let foreign = Episode {id:1, scenes:vec![Scene {scene_key:"scene:900".into(),..Default::default()}],..Default::default()};
        assert!(prepare_scenes(&foreign,&records).is_err());
        let duplicate = Episode {id:1, scenes:vec![Scene {scene_key:"draft:same".into(),..Default::default()};2],..Default::default()};
        assert!(prepare_scenes(&duplicate,&records).is_err());
    }

    #[test]
    fn keep_legacy_numeric_links_and_explicit_episode_end() {
        assert_eq!(target_key(None,200),"scene:200");
        assert_eq!(target_key(Some("scene:branch"),200),"scene:branch");
        assert_eq!(target_key(Some(""),200),"");
        let episode = Episode {id:1,scenes:vec![
            Scene {id:1,next_scene_id:2,..Default::default()},
            Scene {id:2,..Default::default()},
        ],..Default::default()};
        let prepared=prepare_scenes(&episode,&[record("scene:200",2)]).unwrap();
        assert_eq!(prepared[0]["next_scene_key"],prepared[1]["key"]);
        assert_eq!(prepared[1]["next_scene_key"],"");
    }
    #[test]
    fn title_and_text_edits_keep_existing_keys_including_story_branches() {
        let keys = ["scene:220", "scene:307", "scene:original_hash"];
        let records: Vec<Value> = keys.iter().map(|key| record(key,1)).collect();
        let mut episode = Episode {id:1,title:"Before".into(),scenes:keys.iter().map(|key| Scene {
            scene_key:key.to_string(),title:"Old scene".into(),texts:vec!["Old text".into()],..Default::default()
        }).collect(),..Default::default()};
        episode.title = "After".into();
        episode.scenes.reverse();
        episode.scenes[0].title = "Changed title".into();
        episode.scenes[0].texts = vec!["Changed text".into()];
        for _ in 0..3 {
            let prepared = prepare_scenes(&episode,&records).unwrap();
            assert_eq!(prepared.iter().map(|s|s["key"].as_str().unwrap()).collect::<Vec<_>>(),vec!["scene:original_hash","scene:307","scene:220"]);
            assert!(prepared.iter().all(|s|s["is_new"]==false));
        }
    }

    #[test]
    fn new_keys_do_not_depend_on_maximum_existing_id() {
        let episode = Episode {id:1,scenes:vec![Scene {scene_key:"draft:new".into(),..Default::default()}],..Default::default()};
        let first = prepare_scenes(&episode,&[]).unwrap();
        let second = prepare_scenes(&episode,&[]).unwrap();
        assert_ne!(first[0]["key"],second[0]["key"]);
        assert!(first[0]["key"].as_str().unwrap().starts_with("scene:s_"));
    }

}