import 'dart:typed_data'; // Импорт Uint8List
import '../../domain/models/asset_model.dart'; // Импорт доменной модели
import '../../domain/repositories/asset_repository.dart'; // Импорт контракта
import '../services/asset_grpc_service.dart'; // Импорт gRPC-сервиса
import '../../../generated/asset_api.pbgrpc.dart'; // Импорт Protobuf-моделей

// Реализация репозитория через gRPC
class AssetRepositoryRemote implements AssetRepository {
  final AssetGrpcService _service; // gRPC-сервис

  // Конструктор класса AssetRepositoryRemote
  AssetRepositoryRemote(this._service);

  // Получить ассеты по типу
  @override
  Future<List<AssetModel>> getAssets(String type, {String episodeId = ''}) async {
    // Запрашиваю ассеты у сервера
    final assets = await _service.getAssets(type, episodeId: episodeId);

    // Преобразую Protobuf-модели в доменные
    return assets.map(toDomain).toList();
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
      // Отправляю на сервер
      final response = await _service.uploadAsset(
        type: type,
        name: name,
        emotion: emotion,
        displayName: displayName,
        episodeId: episodeId,
        fileData: fileData,
        fileName: fileName,
      );

      // Если успешно - возвращаю ассет
      if (response.success && response.hasAsset()) {
        return toDomain(response.asset);
      }
      return null;
    } catch (e) {
      return null; // Ошибка загрузки
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
      fileData: Uint8List.fromList(asset.fileData),
    );
  }
}