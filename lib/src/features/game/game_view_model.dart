import 'package:flutter/foundation.dart'; // Импорт для ChangeNotifier и debugPrint
import '../../core/async_state.dart'; // Импорт состояния
import '../../domain/models/episode_model.dart'; // Импорт доменных моделей
import '../../domain/models/progress_model.dart'; // Импорт прогресса
import '../../domain/repositories/episode_repository.dart'; // Импорт контракта
import '../../domain/repositories/progress_repository.dart'; // Импорт контракта прогресса
import '../../domain/repositories/achievement_repository.dart'; // Импорт контракта достижений
import '../../../services/storage_service.dart'; // Импорт сервиса хранения

// ViewModel для игрового экрана
class GameViewModel extends ChangeNotifier {
  final EpisodeRepository _repository; // Репозиторий эпизодов
  final ProgressRepository? _progressRepository; // Репозиторий прогресса
  final AchievementRepository? _achievementRepository; // Репозиторий достижений

  // Состояние загрузки эпизода
  AsyncState<EpisodeModel> _state = AsyncState.idle();

  // Текущая сцена (индекс)
  int _currentSceneIndex = 0;

  // Текущая реплика (индекс внутри сцены)
  int _currentTextIndex = 0;

  // Текущие баллы
  int _points = 0;

  // Текущие флаги (имя - значение)
  final Map<String, bool> _flags = {};

  // ID игрока
  String _playerId = '';

  // Текущая концовка
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

  // Геттер: текущая реплика
  String get currentText {
    if (currentScene == null) return '';
    if (currentScene!.texts.isEmpty) return '';
    if (_currentTextIndex >= currentScene!.texts.length) {
      return currentScene!.texts.last;
    }
    return currentScene!.texts[_currentTextIndex];
  }

  // Геттер: есть ли ещё реплики
  bool get hasMoreTexts {
    if (currentScene == null) return false;
    return _currentTextIndex < currentScene!.texts.length - 1;
  }

  // Геттер: все ли реплики показаны
  bool get isTextFinished {
    if (currentScene == null) return true;
    return _currentTextIndex >= currentScene!.texts.length - 1;
  }

  // Геттер для баллов
  int get points => _points;

  // Геттер для флагов
  Map<String, bool> get flags => _flags;

  // Геттер для концовки
  String get ending => _ending;

  // Геттер: последняя ли сцена (или nextSceneId == 0)
  bool get isLastScene {
    if (currentScene == null) return true;
    // Если next_scene_id == 0 - это конец
    if (currentScene!.nextSceneId == 0) return true;
    if (_state.data == null) return false;
    return _currentSceneIndex >= _state.data!.scenes.length - 1;
  }

  // ID текущей сцены
  String get _currentSceneIdStr {
    if (currentScene == null) return '';
    return currentScene!.sceneKey;
  }

  // Конструктор класса GameViewModel
  GameViewModel(this._repository, [this._progressRepository, this._achievementRepository]);

  // Загрузить эпизод по ID
  Future<void> loadEpisode(int id, {bool startFromBeginning = false}) async {
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

      // Если надо начать с начала - сбрасываю прогресс
      if (startFromBeginning) {
        _currentSceneIndex = 0;
        _currentTextIndex = 0;
        _points = 0;
        _flags.clear();
        notifyListeners();
        return;
      }

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
      _currentTextIndex = 0;
    } catch (e) {
      _state = AsyncState.failure(e.toString());
    }

    notifyListeners();
  }

  // Следующая реплика (если есть)
  void nextText() {
    if (hasMoreTexts) {
      _currentTextIndex++;
      notifyListeners();
    }
  }

  // Проверка условия сцены
  // ignore: unused_element
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
        _currentTextIndex = 0;
        _saveProgress();
        _checkAchievements();
        notifyListeners();
        return;
      }
    }
  }

  // Переход к следующей сцене (по next_scene_id или по порядку)
  void nextScene() {
    if (_state.data == null) return;
    if (currentScene == null) return;

    // Если у сцены задан nextSceneId - иду на него
    final nextId = currentScene!.nextSceneId;
    if (nextId > 0) {
      goToScene(nextId);
      return;
    }

    // Если nextSceneId == 0 - конец эпизода
    return;
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
    _checkAchievements();
    notifyListeners();
  }

  // Определить концовку по флагам и баллам
  String determineEnding() {
    // Если концовка уже установлена - возвращаю её
    if (_ending.isNotEmpty) return _ending;

    // Логика концовок

    // Маринетт + Лука
    if (_flags['выбрал_луку'] == true) {
      return 'Лука';
    }
    // Леди Баг + Адриан
    if (_flags['выбрал_адрибаг'] == true) {
      return 'АдриБаг';
    }
    // Леди Баг + Супер-Кот
    if (_flags['выбрал_супербаг'] == true) {
      return 'СуперБаг';
    }
    // Маринетт + Адриан
    if (_flags['выбрал_адринетт'] == true) {
      return 'АдриНетт';
    }
    // По умолчанию
    return 'МариКот';
  }

  // Проверить и открыть достижения
  Future<void> _checkAchievements() async {
    if (_achievementRepository == null) return;
    if (_state.data == null) return;

    try {
      // Достижение: все эпизоды
      if (isLastScene) {
        await _achievementRepository.unlockAchievement(_playerId, 'all_episodes');
      }

      // Достижение: максимум баллов
      if (_points >= 100) {
        await _achievementRepository.unlockAchievement(_playerId, 'max_points');
      }

      // Достижение: все концовки
      if (_ending.isNotEmpty) {
        await _achievementRepository.unlockAchievement(_playerId, 'all_endings');
      }

      // Достижение: секретная сцена
      if (_flags['secret_scene'] == true) {
        await _achievementRepository.unlockAchievement(_playerId, 'secret_scene');
      }

      // Достижение: все друзья
      if (_flags['all_friends'] == true) {
        await _achievementRepository.unlockAchievement(_playerId, 'all_friends');
      }
    } catch (e) {
      debugPrint('Ошибка открытия достижения: $e');
    }
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