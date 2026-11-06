-- Добавляю поле is_admin (админ ли игрок)
DEFINE FIELD IF NOT EXISTS is_admin ON TABLE player TYPE bool DEFAULT false
    MIGRATE EXISTING ROWS AS add_player_admin USING false;
