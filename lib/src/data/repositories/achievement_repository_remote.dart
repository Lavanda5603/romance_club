import '../../domain/models/achievement_model.dart'; // Импорт доменных моделей
import '../../domain/repositories/achievement_repository.dart'; // Импорт контракта
import '../services/achievement_grpc_service.dart'; // Импорт gRPC-сервиса

// Реализация репозитория достижений через gRPC
class AchievementRepositoryRemote implements AchievementRepository {
  final AchievementGrpcService _service; // gRPC-сервис

  // Конструктор класса AchievementRepositoryRemote
  AchievementRepositoryRemote(this._service);

  // Получить достижения игрока
  @override
  Future<List<AchievementModel>> getAchievements(String playerId) async {
    final response = await _service.getAchievements(playerId);

    // Преобразую Protobuf-модели в доменные
    return response.achievements.map((a) {
      return AchievementModel(
        name: a.name,
        unlockedAt: a.unlockedAt,
      );
    }).toList();
  }

  // Открыть достижение
  @override
  Future<bool> unlockAchievement(String playerId, String name) async {
    final response = await _service.unlockAchievement(
      playerId: playerId,
      name: name,
    );
    return response.success;
  }
}