-- Отдельная транзакция: SurrealDB 4 не строит индекс в той же транзакции,
-- которая добавляет преобразование существующих строк таблицы.
DEFINE FIELD IF NOT EXISTS revision ON progress TYPE int DEFAULT 0
    MIGRATE EXISTING ROWS AS add_progress_revision USING 0;
