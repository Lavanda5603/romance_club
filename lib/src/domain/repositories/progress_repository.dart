import '../models/progress_model.dart'; // Импорт доменных моделей

// Контракт репозитория прогресса
abstract class ProgressRepository {
  // Получить прогресс игрока по эпизоду
  Future<ProgressModel> getProgress(String playerId, int episodeId);

  // Сохранить прогресс
  Future<bool> saveProgress(ProgressModel progress);

  // Сбросить прогресс игрока
  Future<bool> resetProgress(String playerId);
}