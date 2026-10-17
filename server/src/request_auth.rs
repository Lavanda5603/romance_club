use tonic::{Request, Status};
use crate::jwt::{self, Claims};

// Проверяю токен и получаю данные игрока
pub fn authenticate<T>(request: &Request<T>) -> Result<Claims, Status> {
    let header = request.metadata().get("authorization")
        .and_then(|value| value.to_str().ok())
        .ok_or_else(|| Status::unauthenticated("Требуется авторизация"))?;
    let token = header.strip_prefix("Bearer ")
        .filter(|token| !token.is_empty() && !token.chars().any(char::is_whitespace))
        .ok_or_else(|| Status::unauthenticated("Неверный токен"))?;
    let claims = jwt::verify_token(token)
        .map_err(|_| Status::unauthenticated("Неверный токен"))?;
    if !claims.sub.starts_with("player:") || claims.sub.len() == "player:".len() {
        return Err(Status::unauthenticated("Неверный игрок в токене"));
    }
    Ok(claims)
}

// Разрешаю работать только со своими данными
pub fn player_id<T>(request: &Request<T>, requested_id: &str) -> Result<String, Status> {
    let claims = match request.extensions().get::<Claims>() {
        Some(claims) => claims.clone(),
        None => authenticate(request)?,
    };
    if requested_id != claims.sub {
        return Err(Status::permission_denied("Нет доступа к данным другого игрока"));
    }
    Ok(claims.sub)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::romance_club::*;
    use crate::romance_club::auth_api_server::AuthApi;
    use crate::romance_club::progress_api_server::ProgressApi;
    use crate::romance_club::achievement_api_server::AchievementApi;
    use crate::romance_club::shop_api_server::ShopApi;
    use tonic::Code;
    use tonic::service::Interceptor;

    fn request<T>(body: T, token: Option<&str>) -> Request<T> {
        let mut request = Request::new(body);
        if let Some(token) = token {
            request.metadata_mut().insert("authorization", token.parse().unwrap());
        }
        request
    }

    #[test]
    fn interceptor_requires_valid_token_and_keeps_owner() {
        let mut interceptor = crate::AuthInterceptor;
        for header in [None, Some(""), Some("Bearer "), Some("Bearer invalid"), Some("Basic invalid")] {
            assert_eq!(interceptor.call(request((), header)).unwrap_err().code(), Code::Unauthenticated);
        }
        let token = jwt::create_token("player:alice", "alice", false).unwrap();
        assert_eq!(interceptor.call(request((), Some(&token))).unwrap_err().code(), Code::Unauthenticated);
        let header = format!("Bearer {token}");
        let accepted = interceptor.call(request((), Some(&header))).unwrap();
        assert_eq!(accepted.extensions().get::<Claims>().unwrap().sub, "player:alice");
        assert_eq!(player_id(&accepted, "player:alice").unwrap(), "player:alice");
        assert_eq!(player_id(&accepted, "player:bob").unwrap_err().code(), Code::PermissionDenied);
        assert_eq!(player_id(&accepted, "").unwrap_err().code(), Code::PermissionDenied);
    }

    #[test]
    fn owner_check_also_works_without_interceptor() {
        for admin in [false, true] {
            let token = jwt::create_token("player:alice", "alice", admin).unwrap();
            let header = format!("Bearer {token}");
            let req = request((), Some(&header));
            assert_eq!(player_id(&req, "player:alice").unwrap(), "player:alice");
            assert_eq!(player_id(&req, "player:bob").unwrap_err().code(), Code::PermissionDenied);
        }
    }

    #[tokio::test]
    async fn personal_methods_reject_access_before_database_queries() {
        // Без подключения к БД проверяю, что отказ происходит до чтения и записи
        let db = surrealdb::Surreal::<surrealdb::engine::remote::ws::Client>::init();
        let auth = crate::auth_service::AuthApiService::new(db.clone());
        let progress = crate::progress_service::ProgressApiService::new(db.clone());
        let achievements = crate::achievement_service::AchievementApiService::new(db.clone());
        let shop = crate::shop_service::ShopApiService::new(db);
        let token = jwt::create_token("player:alice", "alice", false).unwrap();
        let foreign = format!("Bearer {token}");
        for (header, code) in [(None, Code::Unauthenticated), (Some("Bearer invalid"), Code::Unauthenticated), (Some(foreign.as_str()), Code::PermissionDenied)] {
            assert_eq!(auth.get_player(request(GetPlayerRequest { player_id: "player:bob".into() }, header)).await.unwrap_err().code(), code);
            assert_eq!(progress.get_progress(request(GetProgressRequest { player_id: "player:bob".into(), ..Default::default() }, header)).await.unwrap_err().code(), code);
            assert_eq!(progress.save_progress(request(SaveProgressRequest { player_id: "player:bob".into(), ..Default::default() }, header)).await.unwrap_err().code(), code);
            assert_eq!(progress.reset_progress(request(ResetProgressRequest { player_id: "player:bob".into() }, header)).await.unwrap_err().code(), code);
            assert_eq!(achievements.get_achievements(request(GetAchievementsRequest { player_id: "player:bob".into() }, header)).await.unwrap_err().code(), code);
            assert_eq!(achievements.unlock_achievement(request(UnlockAchievementRequest { player_id: "player:bob".into(), ..Default::default() }, header)).await.unwrap_err().code(), code);
            assert_eq!(shop.get_purchases(request(GetPurchasesRequest { player_id: "player:bob".into() }, header)).await.unwrap_err().code(), code);
            assert_eq!(shop.purchase(request(PurchaseRequest { player_id: "player:bob".into(), ..Default::default() }, header)).await.unwrap_err().code(), code);
            assert_eq!(shop.get_currency(request(GetCurrencyRequest { player_id: "player:bob".into() }, header)).await.unwrap_err().code(), code);
        }
    }
}
