-- Начатый эпизод не считаю завершённым
DEFINE FIELD IF NOT EXISTS completed ON progress TYPE bool DEFAULT false
    MIGRATE EXISTING ROWS AS add_progress_completed USING false;
