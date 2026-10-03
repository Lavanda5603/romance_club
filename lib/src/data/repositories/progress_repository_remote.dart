import '../../domain/models/progress_model.dart'; // Импорт доменных моделей
import '../../domain/repositories/progress_repository.dart'; // Импорт контракта
import '../services/progress_grpc_service.dart'; // Импорт gRPC-сервиса
import '../../../generated/progress.pb.dart'; // Импорт Protobuf-модели Progress

// Реализация репозитория прогресса через gRPC
class ProgressRepositoryRemote implements ProgressRepository {
  final ProgressGrpcService _service; // gRPC-сервис

  // Конструктор класса ProgressRepositoryRemote
  ProgressRepositoryRemote(this._service);

  // Получить прогресс игрока по эпизоду
  @override
  Future<ProgressModel> getProgress(int playerId, int episodeId) async {
    // Запрашиваю прогресс у сервера
    final progress = await _service.getProgress(playerId, episodeId);

    // Преобразую Protobuf-модель в доменную
    return toDomain(progress);
  }

  // Сохранить прогресс
  @override
  Future<bool> saveProgress(ProgressModel progress) async {
    // Отправляю на сервер
    final response = await _service.saveProgress(
      playerId: progress.playerId,
      episodeId: progress.episodeId,
      sceneId: progress.sceneId,
      flags: progress.flags,
      counters: progress.counters,
    );

    // Возвращаю результат
    return response.success;
  }

  // Преобразование Protobuf-модели в доменную
  ProgressModel toDomain(Progress progress) {
    return ProgressModel(
      playerId: progress.playerId,
      episodeId: progress.episodeId,
      sceneId: progress.sceneId,
      flags: Map<String, bool>.from(progress.flags),
      counters: Map<String, int>.from(progress.counters),
    );
  }
}