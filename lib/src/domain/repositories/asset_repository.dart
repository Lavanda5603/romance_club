import 'dart:typed_data'; // Импорт Uint8List
import '../models/asset_model.dart'; // Импорт доменной модели

// Контракт репозитория ассетов
abstract class AssetRepository {
  // Получить ассеты по типу (background, character, sound) (forceRefresh: true - игнорировать кэш и загрузить заново)
  Future<List<AssetModel>> getAssets(String type, {String episodeId = '', bool forceRefresh = false});

  // Получить оригинал ассета по ID (для отображения в сцене)
  Future<Uint8List> getAssetFull(String id);

  // Загрузить новый ассет
  Future<AssetModel?> uploadAsset({
    required String type,
    required String name,
    required String emotion,
    required String displayName,
    required String episodeId,
    required Uint8List fileData,
    required String fileName,
  });

  // Удалить ассет по ID
  Future<bool> deleteAsset(String id);
}