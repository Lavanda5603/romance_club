import 'package:flutter/foundation.dart'; // Импорт для ChangeNotifier
import '../../core/async_state.dart'; // Импорт состояния
import '../../domain/models/episode_model.dart'; // Импорт доменных моделей
import '../../domain/repositories/episode_repository.dart'; // Импорт контракта

// ViewModel для игрового экрана
class GameViewModel extends ChangeNotifier {
  final EpisodeRepository _repository; // Репозиторий

  // Состояние загрузки эпизода
  AsyncState<EpisodeModel> _state = AsyncState.idle();

  // Геттер для состояния
  AsyncState<EpisodeModel> get state => _state;

  // Конструктор класса GameViewModel
  GameViewModel(this._repository);

  // Загрузить эпизод по ID
  Future<void> loadEpisode(int id) async {
    // Перевожу состояние в загрузку
    _state = AsyncState.loading();
    notifyListeners();

    try {
      // Запрашиваю эпизод у репозитория
      final episode = await _repository.getEpisode(id);

      // Перевожу состояние в успех
      _state = AsyncState.success(episode);
    } catch (e) {
      // Перевожу состояние в ошибку
      _state = AsyncState.failure(e.toString());
    }

    // Уведомляю слушателей
    notifyListeners();
  }
}