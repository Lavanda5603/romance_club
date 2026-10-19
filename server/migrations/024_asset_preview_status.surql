-- Храню результат обработки старого изображения отдельно от оригинала
DEFINE FIELD IF NOT EXISTS preview_status ON asset TYPE option<string>;
DEFINE FIELD IF NOT EXISTS preview_source_version ON asset TYPE option<string>;
