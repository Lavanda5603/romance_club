use surrealdb::{engine::remote::ws::Client, Surreal}; // Подключаю базу
use surrealdb::types::{RecordId, RecordIdKey, ToSql}; // Подключаю типизированный ID записи
use tonic::Status; // Подключаю ошибки gRPC

// Для удаления использую отдельный вход с ограниченными правами в базе
pub async fn connection(root: &Surreal<Client>, namespace: &str, database: &str)
    -> Result<Surreal<Client>, Box<dyn std::error::Error + Send + Sync>> {
    let password = format!("{}{}", uuid::Uuid::new_v4().simple(), uuid::Uuid::new_v4().simple());
    root.query("UPSERT asset_delete_identity:server SET password_hash=crypto::argon2::generate($password);")
        .bind(("password", password.clone())).await?.check()?;
    let db = Surreal::new::<surrealdb::engine::remote::ws::Ws>("127.0.0.1:8000/rpc").await?;
    db.signin(surrealdb::opt::auth::Record {
        namespace:namespace.into(), database:database.into(), access:"asset_delete_access".into(),
        params:std::collections::BTreeMap::from([("password".to_owned(), password)]),
    }).await?;
    Ok(db)
}

// Принимаю только полный ID одной записи из таблицы ассетов
pub fn asset_id(value: &str) -> Result<RecordId, Status> {
    let invalid = || Status::invalid_argument("Нужен корректный ID записи из таблицы asset");
    let mut id = RecordId::parse_simple(value).map_err(|_| invalid())?;
    if id.table.as_str() != "asset" { return Err(invalid()); }
    let RecordIdKey::String(key) = &id.key else { return Err(invalid()); };
    if key.trim().is_empty() { return Err(invalid()); }
    // parse_simple читает числа как строки, поэтому отдельно сохраняю числовой тип
    if let Some(raw) = value.strip_prefix("asset:") {
        if let Ok(number) = raw.parse::<i64>() {
            id.key = RecordIdKey::Number(number);
        }
    }
    if id.to_sql() != value { return Err(invalid()); }
    Ok(id)
}

// Оба API удаляют только из явно указанной таблицы, ID передаю параметром
pub async fn delete(db: &Surreal<Client>, value: &str) -> Result<(), Status> {
    let id = asset_id(value)?;
    let mut response = db.query("DELETE asset WHERE id = $id RETURN id;")
        .bind(("id", id)).await.map_err(|e| Status::internal(e.to_string()))?
        .check().map_err(|e| Status::internal(e.to_string()))?;
    let deleted: Vec<serde_json::Value> = response.take(0).map_err(|e| Status::internal(e.to_string()))?;
    if deleted.is_empty() { return Err(Status::not_found("Ассет не найден")); }
    Ok(())
}

#[cfg(test)]
#[path = "asset_delete_tests.rs"]
mod tests; // Проверки таблицы и удаления
