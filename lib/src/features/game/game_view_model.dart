import 'package:flutter/foundation.dart'; // Импорт для ChangeNotifier и debugPrint
import '../../core/async_state.dart'; // Импорт состояния
import '../../domain/models/episode_model.dart'; // Импорт доменных моделей
import '../../domain/models/progress_model.dart'; // Импорт прогресса
import '../../domain/repositories/episode_repository.dart'; // Импорт контракта
import '../../domain/repositories/progress_repository.dart'; // Импорт контракта прогресса

// ViewModel для игрового экрана
class GameViewModel extends ChangeNotifier {
  final EpisodeRepository _repository; // Репозиторий эпизодов
  final ProgressRepository? _progressRepository; // Репозиторий прогресса

  // Состояние загрузки эпизода
  AsyncState<EpisodeModel> _state = AsyncState.idle();

  // Текущая сцена (индекс)
  int _currentSceneIndex = 0;

  // Текущие баллы
  int _points = 0;

  // Текущие флаги (имя - значение)
  final Map<String, bool> _flags = {};

  // ID игрока
  final int _playerId = 1;

  // Геттер для состояния
  AsyncState<EpisodeModel> get state => _state;

  // Геттер для текущей сцены
  SceneModel? get currentScene {
    if (_state.data != null && _state.data!.scenes.isNotEmpty) {
      return _state.data!.scenes[_currentSceneIndex];
    }
    return null;
  }

  // Геттер для баллов
  int get points => _points;

  // Геттер для флагов
  Map<String, bool> get flags => _flags;

  // Геттер: последняя ли сцена
  bool get isLastScene {
    if (_state.data == null) return false;
    return _currentSceneIndex >= _state.data!.scenes.length - 1;
  }

  // ID текущей сцены (строка)
  String get _currentSceneIdStr {
    if (currentScene == null) return '';

    return currentScene!.sceneKey;
  }

  // Конструктор класса GameViewModel
  GameViewModel(this._repository, [this._progressRepository]);

  // Загрузить эпизод по ID
  Future<void> loadEpisode(int id) async {
    _state = AsyncState.loading();
    notifyListeners();

    try {
      final episode = await _repository.getEpisode(id);
      _state = AsyncState.success(episode);

      // Загружаю прогресс, если есть репозиторий
      if (_progressRepository != null) {
        try {
          final progress = await _progressRepository.getProgress(_playerId, id);

          if (progress.sceneId.isNotEmpty) {
            // Ищу сцену по sceneKey
            for (int i = 0; i < _state.data!.scenes.length; i++) {
              if (_state.data!.scenes[i].sceneKey == progress.sceneId) {
                _currentSceneIndex = i;
                break;
              }
            }
            _points = progress.counters.values.fold(0, (a, b) => a + b);
            _flags.addAll(progress.flags);
          } else {
            _currentSceneIndex = 0;
            _points = 0;
            _flags.clear();
          }
        } catch (e) {
          debugPrint('Ошибка загрузки прогресса: $e');
          _currentSceneIndex = 0;
          _points = 0;
          _flags.clear();
        }
      }
    } catch (e) {
      _state = AsyncState.failure(e.toString());
    }

    notifyListeners();
  }

  // Переход к сцене по ID
  void goToScene(int sceneId) {
    if (_state.data == null) return;
    for (int i = 0; i < _state.data!.scenes.length; i++) {
      if (_state.data!.scenes[i].id == sceneId) {
        _currentSceneIndex = i;
        _saveProgress();
        notifyListeners();
        return;
      }
    }
  }

  // Переход к следующей сцене (по порядку)
  void nextScene() {
    if (_state.data == null) return;
    if (isLastScene) return;
    _currentSceneIndex += 1;
    _saveProgress();
    notifyListeners();
  }

  // Обработка выбора (индекс выбора в текущей сцене)
  void onChoiceSelected(int choiceIndex) {
    if (currentScene == null) return;
    final choice = currentScene!.choices[choiceIndex];
    for (final action in choice.actions) {
      if (action.type == 'nextScene') {
        goToScene(action.sceneId);
      } else if (action.type == 'changeCounter') {
        _points += action.counterValue;
      } else if (action.type == 'changeFlag') {
        _flags[action.flagName] = action.flagValue;
      }
    }
    _saveProgress();
    notifyListeners();
  }

  // Сохранить прогресс на сервере
  Future<void> _saveProgress() async {
    if (_progressRepository == null) return;
    if (_state.data == null) return;

    try {
      final progress = ProgressModel(
        playerId: _playerId,
        episodeId: _state.data!.id,
        sceneId: _currentSceneIdStr,
        flags: _flags,
        counters: {'points': _points},
      );
      await _progressRepository.saveProgress(progress);
    } catch (e) {
      debugPrint('Ошибка сохранения прогресса: $e');
    }
  }
}