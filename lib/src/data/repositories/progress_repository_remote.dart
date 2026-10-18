import '../../domain/models/progress_model.dart'; // Импорт доменных моделей
import '../../domain/repositories/progress_repository.dart'; // Импорт контракта
import '../services/progress_grpc_service.dart'; // Импорт gRPC-сервиса
import '../../../generated/progress.pb.dart'; // Импорт Protobuf-модели Progress

// Реализация репозитория прогресса через gRPC
class ProgressRepositoryRemote implements ProgressRepository {
  final ProgressGrpcService _service; // gRPC-сервис

  // Конструктор класса ProgressRepositoryRemote
  ProgressRepositoryRemote(this._service);

  @override
  Future<Set<int>> getProgressSummary(String playerId) async {
    final response = await _service.getProgressSummary(playerId);
    return Set.unmodifiable(response.episodeIds);
  }

  // Получить прогресс игрока
  @override
  Future<ProgressModel> getProgress(String playerId, int episodeId) async {
    final progress = await _service.getProgress(playerId, episodeId);
    return toDomain(progress);
  }

  // Сохранить прогресс
  @override
  Future<int> saveProgress(ProgressModel progress) async {
    final response = await _service.saveProgress(
      playerId: progress.playerId,
      episodeId: progress.episodeId,
      sceneId: progress.sceneId,
      expectedRevision: progress.revision,
      completed: progress.completed,
      flags: progress.flags,
      counters: progress.counters,
    );
    if (!response.success) throw StateError(response.message);
    return response.revision;
  }

  // Сбросить прогресс игрока
  @override
  Future<bool> resetProgress(String playerId) async {
    final response = await _service.resetProgress(playerId);
    return response.success;
  }

  // Преобразование Protobuf-модели в доменную
  ProgressModel toDomain(Progress progress) {
    return ProgressModel(
      playerId: progress.playerId,
      episodeId: progress.episodeId,
      sceneId: progress.sceneId,
      revision: progress.revision,
      completed: progress.completed,
      flags: Map<String, bool>.from(progress.flags),
      counters: Map<String, int>.from(progress.counters),
    );
  }
}
