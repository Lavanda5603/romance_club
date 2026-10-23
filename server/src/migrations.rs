use std::{error::Error, io, path::Path}; // Подключаю файлы миграций и ошибки
use sha2::{Digest, Sha256}; // Подключаю проверку содержимого файла
use surrealdb::{engine::remote::ws::Client, types::RecordId, Surreal}; // Подключаю базу и тип ID

type MigrationResult = Result<(), Box<dyn Error + Send + Sync>>;

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
            if recorded["checksum"].as_str() != Some(&checksum) {
                return Err(io::Error::other(format!("Изменена применённая миграция {name}. Добавьте новый файл миграции")).into());
            }
            continue;
        }
        // У файлов уже есть внешние BEGIN/COMMIT, заменяю их общей транзакцией с журналом
        let body = sql.lines().filter(|line| !matches!(line.trim(), "BEGIN TRANSACTION;" | "COMMIT TRANSACTION;"))
            .collect::<Vec<_>>().join("\n");
        let query = format!("BEGIN TRANSACTION;\nIF record::exists($migration_key) {{ THROW 'MIGRATION_ALREADY_APPLIED'; }};\n{body}\nCREATE $migration_key CONTENT {{name:$migration_name,checksum:$migration_checksum,applied_at:time::now()}};\nCOMMIT TRANSACTION;");
        println!("Применяю миграцию: {name}");
        let mut result = db.query(query).bind(("migration_key", key)).bind(("migration_name", name.clone()))
            .bind(("migration_checksum", checksum)).await?;
        let errors = result.take_errors();
        if !errors.is_empty() {
            let details = errors.values().map(ToString::to_string).collect::<Vec<_>>().join("; ");
            return Err(io::Error::other(format!("Ошибка миграции {name}: {details}")).into());
        }
    }
    Ok(())
}

#[cfg(test)]
#[path = "migration_tests.rs"]
mod tests; // Проверки первого переноса и повторных запусков