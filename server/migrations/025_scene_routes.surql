-- Правила перехода храню в данных сцены, а не в коде игры
DEFINE FIELD IF NOT EXISTS routes ON scene TYPE option<array<object>> FLEXIBLE;
