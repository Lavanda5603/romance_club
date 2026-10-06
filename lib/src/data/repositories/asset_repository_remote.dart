import '../../domain/models/asset_model.dart'; // Импорт доменной модели
import '../../domain/repositories/asset_repository.dart'; // Импорт контракта
import '../services/asset_grpc_service.dart'; // Импорт gRPC-сервиса
import '../../../generated/asset_api.pb.dart'; // Импорт Protobuf-модели

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
    );
  }
}