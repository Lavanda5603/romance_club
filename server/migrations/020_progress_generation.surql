DEFINE TABLE IF NOT EXISTS progress_session SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD IF NOT EXISTS player_id ON progress_session TYPE record<player>;
DEFINE FIELD IF NOT EXISTS generation ON progress_session TYPE int DEFAULT 0 ASSERT $value >= 0;
DEFINE FIELD IF NOT EXISTS write_revision ON progress_session TYPE int DEFAULT 0;
