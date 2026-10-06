import 'dart:typed_data'; // Импорт Uint8List

// Доменная модель ассета (картинки, звука)
class AssetModel {
  final String id; // ID в SurrealDB
  final String type; // Тип: background, character, sound
  final String name; // Имя
  final String emotion; // Эмоция
  final String url; // Путь к файлу
  final String displayName; // Человеческое имя
  final String episodeId; // ID эпизода
  final Uint8List fileData; // Байты файла (сама картинка)

  // Конструктор класса AssetModel
  const AssetModel({
    required this.id,
    required this.type,
    required this.name,
    required this.emotion,
    required this.url,
    required this.displayName,
    required this.episodeId,
    required this.fileData,
  });
}