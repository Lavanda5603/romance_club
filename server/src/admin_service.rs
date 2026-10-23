use tonic::{Request, Response, Status}; // Импорт tonic
use surrealdb::engine::remote::ws::Client; // Импорт клиента SurrealDB
use surrealdb::Surreal; // Импорт Surreal
use crate::romance_club::admin_api_server::AdminApi; // Импорт трейта AdminApi
use crate::romance_club::{
    AdminDeleteAssetRequest, AdminDeleteEpisodeRequest, AdminResponse,
}; // Импорт структур

// Сервис для админ-операций
pub struct AdminApiService {
    db: Surreal<Client>, // Подключение к SurrealDB
    delete_db: Surreal<Client>, // Отдельное подключение для удаления ассетов
}

impl AdminApiService {
    // Создать новый сервис
    pub fn new(db: Surreal<Client>) -> Self {
        Self { delete_db:db.clone(), db }
    }
    // Ограничиваю права удаления ассетов на уровне подключения
    pub fn with_delete_db(mut self, db: Surreal<Client>) -> Self { self.delete_db=db; self }
}

#[tonic::async_trait]
impl AdminApi for AdminApiService {
    // Удалить ассет
    async fn delete_asset(
        &self,
        request: Request<AdminDeleteAssetRequest>,
    ) -> Result<Response<AdminResponse>, Status> {
        // Проверяю админа
        crate::request_auth::check_admin(&request)?;
        crate::asset_delete::asset_id(&request.get_ref().asset_id)?;
        crate::request_auth::check_current_admin(&request, &self.db).await?;

        let id = request.into_inner().asset_id;

        println!("[ADMIN_DELETE_ASSET] Удаляю ассет: {}", id);

        // Использую ту же проверку таблицы, что и в AssetApi
        crate::asset_delete::delete(&self.delete_db, &id).await?;

        println!("[ADMIN_DELETE_ASSET] Ассет удалён: {}", id);

        Ok(Response::new(AdminResponse {
            success: true,
            message: "Ассет удалён".to_string(),
        }))
    }

    // Удалить эпизод
    async fn delete_episode(
        &self,
        request: Request<AdminDeleteEpisodeRequest>,
    ) -> Result<Response<AdminResponse>, Status> {
        // Проверяю админа
        crate::request_auth::check_current_admin(&request, &self.db).await?;

        let id = request.into_inner().episode_id;

        println!("[ADMIN_DELETE_EPISODE] Удаляю эпизод ID: {}", id);

        // Удаляю дерево целиком и откатываю все изменения при ошибке
        crate::episode_delete::delete(&self.db, id).await?;

        println!("[ADMIN_DELETE_EPISODE] Эпизод удалён");

        Ok(Response::new(AdminResponse {
            success: true,
            message: "Эпизод удалён".to_string(),
        }))
    }
}