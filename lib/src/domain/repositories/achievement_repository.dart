import '../models/achievement_model.dart'; // Импорт доменных моделей

// Контракт репозитория достижений
abstract class AchievementRepository {
  // Получить достижения игрока
  Future<List<AchievementModel>> getAchievements(String playerId);

  // Открыть достижение
  Future<bool> unlockAchievement(String playerId, String name);
}