import '../models/progress_model.dart'; // Импорт доменных моделей

// Контракт репозитория прогресса
abstract class ProgressRepository {
  Future<Set<int>> getProgressSummary(String playerId);
  // Получить прогресс игрока по эпизоду
  Future<ProgressModel> getProgress(String playerId, int episodeId);

  // Сохранить прогресс
  Future<int> saveProgress(ProgressModel progress);

  // Сбросить прогресс игрока
  Future<bool> resetProgress(String playerId);
}
