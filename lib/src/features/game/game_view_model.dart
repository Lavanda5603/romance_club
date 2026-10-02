import 'package:flutter/foundation.dart'; // Импорт для ChangeNotifier
import '../../core/async_state.dart'; // Импорт состояния
import '../../domain/models/episode_model.dart'; // Импорт доменных моделей
import '../../domain/repositories/episode_repository.dart'; // Импорт контракта

// ViewModel для игрового экрана
class GameViewModel extends ChangeNotifier {
  final EpisodeRepository _repository; // Репозиторий

  // Состояние загрузки эпизода
  AsyncState<EpisodeModel> _state = AsyncState.idle();

  // Текущая сцена (индекс)
  int _currentSceneIndex = 0;

  // Текущие баллы
  int _points = 0;

  // Текущие флаги (имя - значение)
  final Map<String, bool> _flags = {};

  // Геттер для состояния
  AsyncState<EpisodeModel> get state => _state;

  // Геттер для текущей сцены
  SceneModel? get currentScene {
    // Если эпизод загружен и есть сцены
    if (_state.data != null && _state.data!.scenes.isNotEmpty) {
      return _state.data!.scenes[_currentSceneIndex];
    }
    return null;
  }

  // Геттер для баллов
  int get points => _points;

  // Геттер для флагов
  Map<String, bool> get flags => _flags;

  // Конструктор класса GameViewModel
  GameViewModel(this._repository);

  // Загрузить эпизод (сразу из Protobuf — для локального режима)
  void loadEpisodeFromProto(EpisodeModel episode) {
    // Перевожу состояние в успех
    _state = AsyncState.success(episode);
    // Сбрасываю текущую сцену на первую
    _currentSceneIndex = 0;
    // Сбрасываю баллы
    _points = 0;
    // Сбрасываю флаги
    _flags.clear();
    // Уведомляю слушателей
    notifyListeners();
  }

  // Загрузить эпизод по ID (с сервера)
  Future<void> loadEpisode(int id) async {
    // Перевожу состояние в загрузку
    _state = AsyncState.loading();
    notifyListeners();

    try {
      // Запрашиваю эпизод у репозитория
      final episode = await _repository.getEpisode(id);

      // Перевожу состояние в успех
      _state = AsyncState.success(episode);
      // Сбрасываю текущую сцену на первую
      _currentSceneIndex = 0;
      // Сбрасываю баллы
      _points = 0;
      // Сбрасываю флаги
      _flags.clear();
    } catch (e) {
      // Перевожу состояние в ошибку
      _state = AsyncState.failure(e.toString());
    }

    // Уведомляю слушателей
    notifyListeners();
  }

  // Переход к сцене по ID
  void goToScene(int sceneId) {
    // Если эпизода нет - выхожу
    if (_state.data == null) return;

    // Ищу сцену с таким ID
    for (int i = 0; i < _state.data!.scenes.length; i++) {
      if (_state.data!.scenes[i].id == sceneId) {
        _currentSceneIndex = i; // Меняю индекс
        notifyListeners(); // Уведомляю слушателей
        return;
      }
    }
  }

  // Обработка выбора (индекс выбора в текущей сцене)
  void onChoiceSelected(int choiceIndex) {
    // Если сцены нет - выхожу
    if (currentScene == null) return;

    // Беру выбор
    final choice = currentScene!.choices[choiceIndex];

    // Прохожу по всем действиям выбора
    for (final action in choice.actions) {
      if (action.type == 'nextScene') {
        // Переход к сцене
        goToScene(action.sceneId);
      } else if (action.type == 'changeCounter') {
        // Изменение баллов
        _points += action.counterValue;
      } else if (action.type == 'changeFlag') {
        // Установка флага
        _flags[action.flagName] = action.flagValue;
      }
    }

    // Уведомляю слушателей
    notifyListeners();
  }
}