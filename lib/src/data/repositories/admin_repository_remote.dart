import 'asset_repository_remote.dart';
import '../../domain/repositories/admin_repository.dart'; // Импорт контракта
import '../services/admin_grpc_service.dart'; // Импорт gRPC-сервиса

// Реализация админ-репозитория через gRPC
class AdminRepositoryRemote implements AdminRepository {
  final AdminGrpcService _service; // gRPC-сервис

  // Конструктор класса AdminRepositoryRemote
  AdminRepositoryRemote(this._service);

  // Удалить ассет
  @override
  Future<bool> deleteAsset(String assetId) async {
    try {
      final response = await _service.deleteAsset(assetId);
      if (response.success) AssetRepositoryRemote.invalidateCache();
      return response.success;
    } catch (e) {
      return false;
    }
  }

  // Удалить эпизод
  @override
  Future<bool> deleteEpisode(int episodeId) async {
    try {
      final response = await _service.deleteEpisode(episodeId);
      return response.success;
    } catch (e) {
      return false;
    }
  }
}