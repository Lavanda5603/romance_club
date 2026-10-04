import 'package:flutter/foundation.dart'; // Импорт для ChangeNotifier и debugPrint
import '../../core/async_state.dart'; // Импорт состояния
import '../../domain/models/episode_model.dart'; // Импорт доменных моделей
import '../../domain/models/progress_model.dart'; // Импорт прогресса
import '../../domain/repositories/episode_repository.dart'; // Импорт контракта
import '../../domain/repositories/progress_repository.dart'; // Импорт контракта прогресса
import '../../../services/storage_service.dart'; // Импорт сервиса хранения

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
  String _playerId = '';

  // Текущая концовка (если эпизод завершён)
  String _ending = '';

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

  // Геттер для концовки
  String get ending => _ending;

  // Геттер: последняя ли сцена
  bool get isLastScene {
    if (_state.data == null) return false;
    return _currentSceneIndex >= _state.data!.scenes.length - 1;
  }

  // ID текущей сцены
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

    // Загружаю player_id из Storage
    _playerId = await StorageService.loadPlayerId();
    if (_playerId.isEmpty) {
      _playerId = 'player:1';
    }

    try {
      final episode = await _repository.getEpisode(id);
      _state = AsyncState.success(episode);

      // Загружаю прогресс
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

  // Проверка условия сцены
  bool _isConditionMet(String condition) {
    // Если условие пустое - показываю сцену
    if (condition.isEmpty) return true;

    // Проверяю условия типа flag:имя=true или flag:имя=false
    if (condition.startsWith('flag:')) {
      final parts = condition.substring(5).split('=');
      if (parts.length == 2) {
        final flagName = parts[0].trim();
        final expected = parts[1].trim().toLowerCase() == 'true';
        final actual = _flags[flagName] ?? false;
        return actual == expected;
      }
    }

    // Проверяю условия типа points>=5 или points<=3
    if (condition.startsWith('points>=')) {
      final value = int.tryParse(condition.substring(8).trim()) ?? 0;
      return _points >= value;
    }
    if (condition.startsWith('points<=')) {
      final value = int.tryParse(condition.substring(8).trim()) ?? 0;
      return _points <= value;
    }
    if (condition.startsWith('points>')) {
      final value = int.tryParse(condition.substring(7).trim()) ?? 0;
      return _points > value;
    }
    if (condition.startsWith('points<')) {
      final value = int.tryParse(condition.substring(7).trim()) ?? 0;
      return _points < value;
    }

    // Неизвестное условие - считаю выполненным
    return true;
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

    // Ищу следующую сцену, у которой выполнено условие
    int nextIndex = _currentSceneIndex + 1;
    while (nextIndex < _state.data!.scenes.length) {
      final nextScene = _state.data!.scenes[nextIndex];
      if (_isConditionMet(nextScene.condition)) {
        _currentSceneIndex = nextIndex;
        _saveProgress();
        notifyListeners();
        return;
      }
      // Пропускаю сцену, если условие не выполнено
      nextIndex++;
    }

    // Если не нашли - переходим на последнюю
    _currentSceneIndex = _state.data!.scenes.length - 1;
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
      } else if (action.type == 'ending') {
        // Установка концовки
        _ending = action.title;
      }
    }
    _saveProgress();
    notifyListeners();
  }

  // Определить концовку по флагам и баллам
  String determineEnding() {
    // Если концовка уже установлена - возвращаю её
    if (_ending.isNotEmpty) return _ending;

    // Простейшая логика концовок (настраивается под сюжет)
    // Флаг выбрал_луку + много баллов = Лука
    if (_flags['выбрал_луку'] == true && _points >= 5) {
      return 'Лука';
    }
    // Флаг выбрал_луку = Лука
    if (_flags['выбрал_луку'] == true) {
      return 'Лука';
    }
    // Флаг выбрал_адриана = Адринетт
    if (_flags['выбрал_адриана'] == true) {
      return 'Адринетт';
    }
    // Флаг выбрал_суперкота = Марикот
    if (_flags['выбрал_суперкота'] == true) {
      return 'Марикот';
    }
    // По умолчанию
    return 'Марикот';
  }

  // Сохранить прогресс
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