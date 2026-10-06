import '../models/asset_model.dart'; // Импорт доменной модели

// Контракт репозитория ассетов
abstract class AssetRepository {
  // Получить ассеты по типу (background, character, sound)
  Future<List<AssetModel>> getAssets(String type, {String episodeId = ''});
}