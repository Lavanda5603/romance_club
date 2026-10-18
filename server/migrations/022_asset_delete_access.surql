-- Служебная запись не относится к аккаунтам игроков и недоступна через API
DEFINE TABLE IF NOT EXISTS asset_delete_identity SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD IF NOT EXISTS password_hash ON asset_delete_identity TYPE string;
DEFINE ACCESS IF NOT EXISTS asset_delete_access ON DATABASE TYPE RECORD
    SIGNIN (SELECT * FROM asset_delete_identity WHERE id = asset_delete_identity:server AND crypto::argon2::compare(password_hash, $password))
    DURATION FOR TOKEN 1h, FOR SESSION NONE;
-- Даю чтение для проверки ID и удаление ассета, остальные записи закрыты
DEFINE TABLE OVERWRITE asset SCHEMAFULL
    PERMISSIONS FOR create, update NONE
    FOR select, delete WHERE $auth.id = asset_delete_identity:server;
BEGIN TRANSACTION;
COMMIT TRANSACTION;
