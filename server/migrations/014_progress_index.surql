-- SurrealDB 4 строит индекс только после фиксации переноса записей.
DEFINE INDEX IF NOT EXISTS progress_owner_episode ON progress FIELDS player_id, episode_id UNIQUE;
