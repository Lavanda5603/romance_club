BEGIN TRANSACTION;
-- Проверяю старые аккаунты до создания индекса, ничего не удаляю
LET $login_counts = SELECT login, count() AS total FROM player GROUP BY login;
IF array::len(array::filter($login_counts, |$entry| $entry.total > 1)) > 0 {
    THROW 'PLAYER_LOGIN_DUPLICATES: в player есть повторяющиеся логины. Разберите дубликаты перед запуском сервера, сохранив аккаунты и их данные';
};
-- Логин сравниваю целиком с учётом регистра, как при входе
DEFINE INDEX IF NOT EXISTS player_login_unique ON TABLE player FIELDS login UNIQUE;
COMMIT TRANSACTION;
