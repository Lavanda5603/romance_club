use tonic::{Request, Status}; // Подключаю запросы, ответы и ошибки gRPC
use crate::jwt::{Claims, JwtKeys}; // Подключаю модули сервера

// Проверяю токен и получаю данные игрока
pub fn authenticate<T>(request: &Request<T>, jwt: &JwtKeys) -> Result<Claims, Status> {
    let header = request.metadata().get("authorization")
        .and_then(|value| value.to_str().ok())
        .ok_or_else(|| Status::unauthenticated("Требуется авторизация"))?;
    let token = header.strip_prefix("Bearer ")
        .filter(|token| !token.is_empty() && !token.chars().any(char::is_whitespace))
        .ok_or_else(|| Status::unauthenticated("Неверный токен"))?;
    let claims = jwt.verify_token(token)
        .map_err(|_| Status::unauthenticated("Неверный токен"))?;
    if !claims.sub.starts_with("player:") || claims.sub.len() == "player:".len() {
        return Err(Status::unauthenticated("Неверный игрок в токене"));
    }
    Ok(claims)
}

// Проверяю, что контент меняет админ
pub fn check_admin<T>(request: &Request<T>) -> Result<(), Status> {
    let claims = request.extensions().get::<Claims>()
        .ok_or_else(|| Status::unauthenticated("Требуется авторизация"))?;
    if !claims.is_admin {
        return Err(Status::permission_denied("Только админ может выполнить это действие"));
    }
    Ok(())
}

// Разрешаю работать только со своими данными
pub fn player_id<T>(request: &Request<T>, requested_id: &str) -> Result<String, Status> {
    let claims = request.extensions().get::<Claims>()
        .ok_or_else(|| Status::unauthenticated("Требуется авторизация"))?;
    if requested_id != claims.sub {
        return Err(Status::permission_denied("Нет доступа к данным другого игрока"));
    }
    Ok(claims.sub.clone())
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

    // Этот ключ используется только в тестах
    fn test_keys() -> JwtKeys {
        JwtKeys::from_secret("test_key_only_0123456789_ABCDEFGHIJKLMN").unwrap()
    }

    fn request<T>(body: T, token: Option<&str>) -> Request<T> {
        let mut request = Request::new(body);
        if let Some(token) = token {
            request.metadata_mut().insert("authorization", token.parse().unwrap());
        }
        if let Ok(claims) = authenticate(&request, &test_keys()) {
            request.extensions_mut().insert(claims);
        }
        request
    }

    #[test]
    fn interceptor_requires_valid_token_and_keeps_owner() {
        let mut interceptor = crate::AuthInterceptor { jwt: test_keys() };
        for header in [None, Some(""), Some("Bearer "), Some("Bearer invalid"), Some("Basic invalid")] {
            assert_eq!(interceptor.call(request((), header)).unwrap_err().code(), Code::Unauthenticated);
        }
        let token = test_keys().create_token("player:alice", "alice", false).unwrap();
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
            let token = test_keys().create_token("player:alice", "alice", admin).unwrap();
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
        let auth = crate::auth_service::AuthApiService::new(db.clone(), test_keys());
        let progress = crate::progress_service::ProgressApiService::new(db.clone());
        let achievements = crate::achievement_service::AchievementApiService::new(db.clone());
        let shop = crate::shop_service::ShopApiService::new(db);
        let token = test_keys().create_token("player:alice", "alice", false).unwrap();
        let foreign = format!("Bearer {token}");
        for (header, code) in [(None, Code::Unauthenticated), (Some("Bearer invalid"), Code::Unauthenticated), (Some(foreign.as_str()), Code::PermissionDenied)] {
            assert_eq!(auth.get_player(request(GetPlayerRequest { player_id: "player:bob".into() }, header)).await.unwrap_err().code(), code);
            assert_eq!(progress.get_progress(request(GetProgressRequest { player_id: "player:bob".into(), ..Default::default() }, header)).await.unwrap_err().code(), code);
            assert_eq!(progress.get_progress_summary(request(GetProgressSummaryRequest { player_id: "player:bob".into() }, header)).await.unwrap_err().code(), code);
            assert_eq!(progress.save_progress(request(SaveProgressRequest { player_id: "player:bob".into(), ..Default::default() }, header)).await.unwrap_err().code(), code);
            assert_eq!(progress.reset_progress(request(ResetProgressRequest { player_id: "player:bob".into() }, header)).await.unwrap_err().code(), code);
            assert_eq!(achievements.get_achievements(request(GetAchievementsRequest { player_id: "player:bob".into() }, header)).await.unwrap_err().code(), code);
            assert_eq!(achievements.unlock_achievement(request(UnlockAchievementRequest { player_id: "player:bob".into(), ..Default::default() }, header)).await.unwrap_err().code(), code);
            assert_eq!(shop.get_purchases(request(GetPurchasesRequest { player_id: "player:bob".into() }, header)).await.unwrap_err().code(), code);
            assert_eq!(shop.purchase(request(PurchaseRequest { player_id: "player:bob".into(), ..Default::default() }, header)).await.unwrap_err().code(), code);
            assert_eq!(shop.get_currency(request(GetCurrencyRequest { player_id: "player:bob".into() }, header)).await.unwrap_err().code(), code);
        }
    }
    #[test]
    fn content_changes_require_admin_role() {
        for admin in [false, true] {
            let token = test_keys().create_token("player:editor", "editor", admin).unwrap();
            let header = format!("Bearer {token}");
            let req = request((), Some(&header));
            assert_eq!(check_admin(&req).is_ok(), admin);
            let mut interceptor = crate::AuthInterceptor { jwt: test_keys() };
            let intercepted = interceptor.call(req).unwrap();
            assert_eq!(check_admin(&intercepted).is_ok(), admin);
        }
    }

    #[tokio::test]
    async fn all_content_methods_check_role_before_database_queries() {
        let db = surrealdb::Surreal::<surrealdb::engine::remote::ws::Client>::init();
        let episodes = crate::EpisodeApiService::new(db.clone());
        let assets = crate::asset_service::AssetApiService::new(db.clone());
        let admin = crate::admin_service::AdminApiService::new(db);
        let token = test_keys().create_token("player:reader", "reader", false).unwrap();
        let header = format!("Bearer {token}");
        for (token, code) in [(None, Code::Unauthenticated), (Some("Bearer invalid"), Code::Unauthenticated), (Some(header.as_str()), Code::PermissionDenied)] {
            use crate::romance_club::episode_api_server::EpisodeApi;
            use crate::romance_club::asset_api_server::AssetApi;
            use crate::romance_club::admin_api_server::AdminApi;
            assert_eq!(episodes.save_episode(request(SaveEpisodeRequest::default(), token)).await.unwrap_err().code(), code);
            assert_eq!(episodes.delete_episode(request(DeleteEpisodeRequest::default(), token)).await.unwrap_err().code(), code);
            assert_eq!(assets.upload_asset(request(UploadAssetRequest::default(), token)).await.unwrap_err().code(), code);
            assert_eq!(assets.delete_asset(request(DeleteAssetRequest::default(), token)).await.unwrap_err().code(), code);
            assert_eq!(admin.delete_asset(request(AdminDeleteAssetRequest::default(), token)).await.unwrap_err().code(), code);
            assert_eq!(admin.delete_episode(request(AdminDeleteEpisodeRequest::default(), token)).await.unwrap_err().code(), code);
        }
    }

}