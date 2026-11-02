use serde::{Deserialize, Serialize}; // Подключаю формат настроек
use tonic::Status; // Подключаю ошибки проверки

#[derive(Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Tier {
    pub points: i32,
    pub title: String,
}

#[derive(Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Rules {
    pub romance: Vec<Tier>,
    pub friendship: Vec<Tier>,
}

// Проверяю настройки на сервере, даже если запрос пришёл без редактора.
pub fn validate(json: &str) -> Result<String, Status> {
    if json.len() > 8192 { return Err(Status::invalid_argument("Настройки слишком большие")); }
    let rules: Rules = serde_json::from_str(json).map_err(|_| Status::invalid_argument("Неверный формат уровней"))?;
    for levels in [&rules.romance, &rules.friendship] {
        if levels.len() != 3 || levels[0].points != 0 ||
            levels.windows(2).any(|w| w[0].points >= w[1].points) ||
            levels.iter().any(|l| l.points > 100000 || l.title.trim().is_empty() || l.title.chars().count() > 60) {
            return Err(Status::invalid_argument("Нужны три уровня: первый с 0 баллов, остальные по возрастанию; название от 1 до 60 символов"));
        }
    }
    serde_json::to_string(&rules).map_err(|_| Status::internal("Не удалось сохранить уровни"))
}

pub fn defaults() -> String {
    serde_json::json!({"romance":[{"points":0,"title":"Знакомство"},{"points":3,"title":"Симпатия"},{"points":7,"title":"Близкие отношения"}],
        "friendship":[{"points":0,"title":"Знакомство"},{"points":2,"title":"Приятельство"},{"points":5,"title":"Крепкая дружба"}]}).to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn defaults_valid() { assert!(validate(&defaults()).is_ok()); }
    #[test]
    fn rejects_invalid_rules() {
        assert!(validate("{}").is_err());
        assert!(validate(&defaults().replace("\"points\":7", "\"points\":3")).is_err());
        assert!(validate(&defaults().replace("Знакомство", "")).is_err());
        assert!(validate(&"x".repeat(8193)).is_err());
    }

    #[tokio::test]
    async fn anonymous_editor_is_rejected() {
        use crate::romance_club::{RelationshipRules, episode_api_server::EpisodeApi};
        let api = crate::EpisodeApiService::new(surrealdb::Surreal::init());
        let result = api.save_relationship_rules(tonic::Request::new(RelationshipRules {json:defaults(),revision:0})).await;
        assert_eq!(result.unwrap_err().code(), tonic::Code::Unauthenticated);
    }

    #[tokio::test]
    #[ignore = "Проверяю права и сохранение только в отдельной БД"]
    async fn persistence_and_conflict() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        use crate::romance_club::{RelationshipRules, GetAllEpisodesRequest, episode_api_server::EpisodeApi};
        use surrealdb::{engine::remote::ws::Ws, opt::auth::Root};
        let db = surrealdb::Surreal::new::<Ws>("127.0.0.1:8000/rpc").await?;
        db.signin(Root {username:std::env::var("SURREAL_USER")?,password:std::env::var("SURREAL_PASS")?}).await?;
        let name = format!("relations_{}",uuid::Uuid::new_v4().simple());
        db.use_ns("romance_club_test").use_db(&name).await?;
        let result = async {
            crate::apply_migrations(&db).await.map_err(|e| e.to_string())?;
            crate::request_auth::seed_test_admin(&db,"player:editor").await?;
            let api = crate::EpisodeApiService::new(db.clone());
            let initial = api.get_relationship_rules(tonic::Request::new(GetAllEpisodesRequest {})).await?.into_inner();
            assert_eq!(initial.revision,0);
            let admin = |rules| {
                let mut request = tonic::Request::new(rules);
                request.extensions_mut().insert(crate::jwt::Claims {sub:"player:editor".into(),login:"editor".into(),is_admin:true,exp:usize::MAX});
                request
            };
            let edited = RelationshipRules {json:defaults().replace("Симпатия","Взаимный интерес"),revision:0};
            let saved = api.save_relationship_rules(admin(edited.clone())).await?.into_inner();
            assert_eq!(saved.revision,1);
            assert!(saved.json.contains("Взаимный интерес"));
            assert_eq!(api.save_relationship_rules(admin(edited)).await.unwrap_err().code(),tonic::Code::Aborted);
            let loaded = api.get_relationship_rules(tonic::Request::new(GetAllEpisodesRequest {})).await?.into_inner();
            assert_eq!(saved,loaded);
            db.query("UPDATE player:editor SET is_admin=false").await?.check()?;
            assert_eq!(api.save_relationship_rules(admin(saved)).await.unwrap_err().code(),tonic::Code::PermissionDenied);
            Ok::<(),Box<dyn std::error::Error + Send + Sync>>(())
        }.await;
        db.query(format!("REMOVE DATABASE {name}")).await?.check()?;
        result
    }
}