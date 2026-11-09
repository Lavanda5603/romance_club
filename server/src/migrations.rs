use std::{error::Error, io, path::Path}; // Подключаю файлы миграций и ошибки
use sha2::{Digest, Sha256}; // Подключаю проверку содержимого файла
use surrealdb::{engine::remote::ws::Client, types::RecordId, Surreal}; // Подключаю базу и тип ID

type MigrationResult = Result<(), Box<dyn Error + Send + Sync>>;

#[path = "migration_compat.rs"]
mod compatibility;

// Повторять целиком можно только атомарную транзакцию: её записи откатились.
async fn retry_transaction<F, Fut>(mut query: F) -> Result<surrealdb::IndexedResults, Box<dyn Error + Send + Sync>>
where
    F: FnMut() -> Fut,
    Fut: std::future::Future<Output = Result<surrealdb::IndexedResults, surrealdb::Error>>,
{
    for attempt in 0..8 {
        let mut result = query().await?;
        let errors = result.take_errors();
        if errors.is_empty() { return Ok(result); }
        let conflict = errors.values().any(|error|
            matches!(error.query_details(), Some(surrealdb::types::QueryError::TransactionConflict)));
        if conflict && attempt < 7 {
            tokio::time::sleep(std::time::Duration::from_millis(10 << attempt)).await;
            continue;
        }
        return Err(io::Error::other(errors.values().map(ToString::to_string).collect::<Vec<_>>().join("; ")).into());
    }
    unreachable!()
}

// Версию записываю в той же транзакции, что и изменение базы
pub async fn apply_dir(db: &Surreal<Client>, directory: &Path) -> MigrationResult {
    let mut paths = std::fs::read_dir(directory)?.map(|entry| entry.map(|entry| entry.path()))
        .collect::<Result<Vec<_>, _>>()?;
    paths.retain(|path| path.extension().is_some_and(|extension| extension == "surql"));
    paths.sort();
    if paths.is_empty() { return Err(io::Error::other("Не найдены файлы миграций").into()); }
    db.query("DEFINE TABLE IF NOT EXISTS schema_migration SCHEMAFULL PERMISSIONS NONE;
        DEFINE FIELD IF NOT EXISTS name ON schema_migration TYPE string;
        DEFINE FIELD IF NOT EXISTS checksum ON schema_migration TYPE string;
        DEFINE FIELD IF NOT EXISTS applied_at ON schema_migration TYPE datetime;").await?.check()?;
    for path in paths {
        let name = path.file_name().and_then(|name| name.to_str()).ok_or_else(|| io::Error::other("Неверное имя миграции"))?.to_owned();
        let sql = std::fs::read_to_string(&path)?;
        let checksum = format!("{:x}", Sha256::digest(sql.replace("\r\n", "\n").as_bytes()));
        let key = RecordId::new("schema_migration", name.clone());
        let mut recorded = db.query("SELECT * FROM ONLY $key;").bind(("key", key.clone())).await?.check()?;
        let recorded: Option<serde_json::Value> = recorded.take(0)?;
        if let Some(recorded) = recorded {
            let previous = recorded["checksum"].as_str().unwrap_or_default();
            if previous != checksum && !compatibility::accepts(&name, previous, &checksum) {
                return Err(io::Error::other(format!("Изменена применённая миграция {name}. Добавьте новый файл миграции")).into());
            }
            continue;
        }
        // У файлов уже есть внешние BEGIN/COMMIT, заменяю их общей транзакцией с журналом
        let body = sql.lines().filter(|line| !matches!(line.trim(), "BEGIN TRANSACTION;" | "COMMIT TRANSACTION;"))
            .collect::<Vec<_>>().join("\n");
        let query = format!("BEGIN TRANSACTION;\nIF record::exists($migration_key) {{ THROW 'MIGRATION_ALREADY_APPLIED'; }};\n{body}\nCREATE $migration_key CONTENT {{name:$migration_name,checksum:$migration_checksum,applied_at:time::now()}};\nCOMMIT TRANSACTION;");
        println!("Применяю миграцию: {name}");
        retry_transaction(|| async {
            db.query(query.clone()).bind(("migration_key", key.clone())).bind(("migration_name", name.clone()))
                .bind(("migration_checksum", checksum.clone())).await
        }).await.map_err(|error| io::Error::other(format!("Ошибка миграции {name}: {error}")))?;
    }
    Ok(())
}

#[cfg(test)]
#[path = "migration_tests.rs"]
mod tests; // Проверки первого переноса и повторных запусков
