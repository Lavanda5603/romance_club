import 'dart:typed_data'; // Импорт Uint8List
import '../../domain/models/asset_model.dart'; // Импорт доменной модели
import '../../domain/repositories/asset_repository.dart'; // Импорт контракта
import '../services/asset_grpc_service.dart'; // Импорт gRPC-сервиса
import '../../../generated/asset_api.pbgrpc.dart'; // Импорт Protobuf-моделей

// Реализация репозитория через gRPC
class AssetRepositoryRemote implements AssetRepository {
  final AssetGrpcService _service; // gRPC-сервис

  // Статический кэш ассетов по типу (живёт между экземплярами)
  static final Map<String, List<AssetModel>> _cache = {};

  // Конструктор класса AssetRepositoryRemote
  AssetRepositoryRemote(this._service);

  // Очистить кэш для типа (при upload/delete)
  static void invalidateCache(String type) {
    _cache.remove(type);
  }

  // Получить ассеты по типу (с кэшем)
  @override
  Future<List<AssetModel>> getAssets(String type, {String episodeId = '', bool forceRefresh = false}) async {
    // Ключ кэша: тип и эпизод
    final cacheKey = '$type::$episodeId';

    // Если не forceRefresh и кэш есть - возвращаю из кэша
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Запрашиваю с сервера
    final assets = await _service.getAssets(type, episodeId: episodeId);
    final models = assets.map(toDomain).toList();

    // Сохраняю в кэш
    _cache[cacheKey] = models;

    return models;
  }

  // Получить оригинал ассета по ID
  @override
  Future<Uint8List> getAssetFull(String id) async {
    return await _service.getAssetFull(id);
  }

  // Получить ассет по имени и эмоции (для выбранного в редакторе)
  @override
  Future<AssetModel?> getAssetByName(String type, String name, {String emotion = ''}) async {
    // Ищу в кэше по всем ключам с этим типом
    for (final entry in _cache.entries) {
      if (entry.key.startsWith('$type::')) {
        for (final a in entry.value) {
          if (a.name == name && a.emotion == emotion) {
            return a;
          }
        }
      }
    }

    // Если в кэше нет - запрашиваю с сервера (эпизод пустой - все ассеты типа)
    final assets = await _service.getAssets(type);
    for (final a in assets) {
      final m = toDomain(a);
      if (m.name == name && m.emotion == emotion) {
        return m;
      }
    }
    return null;
  }

  // Загрузить новый ассет
  @override
  Future<AssetModel?> uploadAsset({
    required String type,
    required String name,
    required String emotion,
    required String displayName,
    required String episodeId,
    required Uint8List fileData,
    required String fileName,
  }) async {
    try {
      final response = await _service.uploadAsset(
        type: type,
        name: name,
        emotion: emotion,
        displayName: displayName,
        episodeId: episodeId,
        fileData: fileData,
        fileName: fileName,
      );

      if (response.success && response.hasAsset()) {
        // Инвалидирую кэш для этого типа
        _cache.remove('$type::');
        _cache.remove('$type::$episodeId');
        return toDomain(response.asset);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Удалить ассет по ID
  @override
  Future<bool> deleteAsset(String id) async {
    try {
      final response = await _service.deleteAsset(id);
      if (response.success) {
        // Инвалидирую кэш (не знаю тип - чищу всё)
        _cache.clear();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Преобразование Protobuf-модели в доменную
  AssetModel toDomain(Asset asset) {
    return AssetModel(
      id: asset.id,
      type: asset.type,
      name: asset.name,
      emotion: asset.emotion,
      url: asset.url,
      displayName: asset.displayName,
      episodeId: asset.episodeId,
      previewData: Uint8List.fromList(asset.previewData),
    );
  }
}