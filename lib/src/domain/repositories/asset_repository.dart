import 'dart:typed_data'; // Импорт Uint8List
import '../models/asset_model.dart'; // Импорт доменной модели

// Контракт репозитория ассетов
abstract class AssetRepository {
  // Получить ассеты по типу (background, character, sound)
  Future<List<AssetModel>> getAssets(String type, {String episodeId = ''});

  // Загрузить новый ассет
  Future<AssetModel?> uploadAsset({
    required String type, // Тип
    required String name, // Имя
    required String emotion, // Эмоция
    required String displayName, // Человеческое имя
    required String episodeId, // ID эпизода
    required Uint8List fileData, // Байты файла
    required String fileName, // Имя файла с расширением
  });

  // Удалить ассет по ID
  Future<bool> deleteAsset(String id);
}