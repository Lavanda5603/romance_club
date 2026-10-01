import '../models/episode_model.dart'; // Импорт доменных моделей

// Контракт репозитория эпизодов
abstract class EpisodeRepository {
  // Получить эпизод по ID
  Future<EpisodeModel> getEpisode(int id);

  // Получить все эпизоды
  Future<List<EpisodeModel>> getAllEpisodes();

  // Сохранить эпизод
  Future<bool> saveEpisode(EpisodeModel episode);
}