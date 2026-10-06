// Доменная модель ассета (картинки, звука)
class AssetModel {
  final String id; // ID в SurrealDB
  final String type; // Тип: background, character, sound
  final String name; // Имя: ep1/paris_morning, marinet
  final String emotion; // Эмоция: happy, sad
  final String url; // Путь к файлу
  final String displayName; // Человеческое имя
  final String episodeId; // ID эпизода

  // Конструктор класса AssetModel
  const AssetModel({
    required this.id,
    required this.type,
    required this.name,
    required this.emotion,
    required this.url,
    required this.displayName,
    required this.episodeId,
  });
}