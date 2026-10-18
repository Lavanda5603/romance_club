import '../../data/services/rpc_policy.dart';
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

  // Общие баллы (points)
  int _points = 0;

  // Счётчики (6 штук: 5 романтики + дружба)
  final Map<String, int> _counters = {
    'romance_adrian': 0, // Маринетт + Адриан
    'romance_cat': 0, // Маринетт + Супер-Кот
    'romance_ladybug_adrian': 0, // Леди Баг + Адриан
    'romance_ladybug_cat': 0, // Леди Баг + Супер-Кот
    'romance_luka': 0, // Маринетт + Лука
    'friendship': 0, // Дружба
  };

  // Текущие флаги (имя - значение)
  final Map<String, bool> _flags = {};

  // ID игрока
  String _playerId = '';

  // Текущая концовка
  String _ending = '';
  bool _completed = false;
  bool get completed => _completed;
  bool _progressSceneMissing = false; // Сохранённая сцена больше не существует

  Future<void> _saveQueue = Future.value();
  int _revision = 0;
  String? _saveError;
  bool _disposed = false;
  int _loadId = 0;
  String? get saveError => _saveError;

  // Дожидаюсь всех записей перед выходом или новой загрузкой
  Future<void> flushProgress() async {
    Future<void> pending;
    do {
      pending = _saveQueue;
      await pending;
    } while (!identical(pending, _saveQueue));
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool get progressSceneMissing => _progressSceneMissing;

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

  // Геттер для баллов (общих)
  int get points => _points;

  // Геттер для счётчиков
  Map<String, int> get counters => _counters;

  // Геттер: баллы любви (сумма 5 романтики)
  int get lovePoints {
    return _counters['romance_adrian']! +
        _counters['romance_cat']! +
        _counters['romance_ladybug_adrian']! +
        _counters['romance_ladybug_cat']! +
        _counters['romance_luka']!;
  }

  // Геттер: баллы дружбы
  int get friendshipPoints => _counters['friendship']!;

  // Геттер для флагов
  Map<String, bool> get flags => _flags;

  // Геттер для концовки
  String get ending => _ending;

  // Конец определяю по переходу сцены, а не по её месту в списке
  bool get isLastScene {
    if (currentScene == null) return false;
    return currentScene!.nextSceneTarget.isEmpty;
  }

  // ID текущей сцены
  String get _currentSceneIdStr {
    if (currentScene == null) return '';
    return currentScene!.sceneKey;
  }

  // Конструктор
  GameViewModel(this._repository, [this._progressRepository, this._achievementRepository]);

  // Загрузить эпизод по ID
  Future<void> loadEpisode(int id, {bool startFromBeginning = false}) async {
    final loadId = ++_loadId;
    await flushProgress();
    if (_disposed || loadId != _loadId) return;
    _saveError = null;
    _revision = 0;
    _state = AsyncState.loading();
    _progressSceneMissing = false;
    _currentSceneIndex = 0;
    _currentTextIndex = 0;
    _points = 0;
    _resetCounters();
    _flags.clear();
    _ending = '';
    _completed = false;
    notifyListeners();

    // Загружаю player_id из Storage
    _playerId = await StorageService.loadPlayerId();
    if (_playerId.isEmpty) {
      _playerId = 'player:1';
    }

    try {
      final episode = await _repository.getEpisode(id);
      if (_disposed || loadId != _loadId) return;

      // Загружаю версию даже при явном перезапуске эпизода
      ProgressModel? loadedProgress;
      if (_progressRepository != null) {
        loadedProgress = await _progressRepository.getProgress(_playerId, id);
        if (_disposed || loadId != _loadId) return;
        _revision = loadedProgress.revision;
      }
      // Сначала записываю начало эпизода, потом открываю игру
      if (startFromBeginning) {
        if (_progressRepository != null) {
          if (episode.scenes.isEmpty) {
            throw StateError('В эпизоде нет сцен');
          }
          final saving = _progressRepository.saveProgress(ProgressModel(
            playerId: _playerId,
            episodeId: id,
            sceneId: episode.scenes.first.sceneKey,
            flags: const {},
            counters: {'points': 0, ..._counters},
            revision: _revision,
            completed: false,
            ending: '',
          ));
          // Новая загрузка тоже должна дождаться сброса
          _saveQueue = saving.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
          final revision = await saving;
          if (_disposed || loadId != _loadId) return;
          _revision = revision;
        }
        _state = AsyncState.success(episode);
        notifyListeners();
        return;
      }
      _state = AsyncState.success(episode);

      // Загружаю прогресс, если есть репозиторий
      if (_progressRepository != null) {
        try {
          final progress = loadedProgress!;
          _completed = progress.completed;
          _ending = progress.ending;

          if (progress.sceneId.isNotEmpty) {
            // Восстанавливаю позицию по постоянному ключу, даже после перестановки
            final index = episode.scenes.indexWhere((scene) => scene.sceneKey == progress.sceneId);
            if (index < 0) {
              _progressSceneMissing = true;
              _state = AsyncState.failure('Сохранённая сцена больше не существует. Можно начать эпизод заново.');
              notifyListeners();
              return;
            }
            _currentSceneIndex = index;
            // Загружаю баллы и счётчики
            _points = progress.counters['points'] ?? 0;
            _loadCounters(progress.counters);
            _flags.addAll(progress.flags);
          } else {
            _currentSceneIndex = 0;
            _points = 0;
            _resetCounters();
            _flags.clear();
          }
        } catch (e) {
          debugPrint('Ошибка загрузки прогресса: $e');
          _currentSceneIndex = 0;
          _points = 0;
          _resetCounters();
          _flags.clear();
        }
      }
      _currentTextIndex = 0;
    } catch (e) {
      if (_disposed || loadId != _loadId) return;
      _state = AsyncState.failure(networkError(e));
    }

    notifyListeners();
  }

  // Сбросить счётчики
  void _resetCounters() {
    _counters['romance_adrian'] = 0;
    _counters['romance_cat'] = 0;
    _counters['romance_ladybug_adrian'] = 0;
    _counters['romance_ladybug_cat'] = 0;
    _counters['romance_luka'] = 0;
    _counters['friendship'] = 0;
  }

  // Загрузить счётчики из progress.counters
  void _loadCounters(Map<String, int> saved) {
    _counters['romance_adrian'] = saved['romance_adrian'] ?? 0;
    _counters['romance_cat'] = saved['romance_cat'] ?? 0;
    _counters['romance_ladybug_adrian'] = saved['romance_ladybug_adrian'] ?? 0;
    _counters['romance_ladybug_cat'] = saved['romance_ladybug_cat'] ?? 0;
    _counters['romance_luka'] = saved['romance_luka'] ?? 0;
    _counters['friendship'] = saved['friendship'] ?? 0;
  }

  // Следующая реплика (если есть)
  void nextText() {
    if (hasMoreTexts) {
      _currentTextIndex++;
      notifyListeners();
    }
  }

  // Проверка условия сцены (flag:имя=true/false, points>=N, points<=N)
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

  // Старые сюжетные ветки пока передают числовой ID
  void goToScene(int sceneId) => goToSceneKey(sceneId > 0 ? 'scene:$sceneId' : '');

  // Перехожу по настоящему ключу сцены, порядок списка не влияет
  void goToSceneKey(String sceneKey) {
    if (_state.data == null || sceneKey.isEmpty) return;
    final visited = <String>{};
    if (_saveError != null) return;
    _goToSceneKey(sceneKey, visited);
    _saveProgress();
    _checkAchievements();
    notifyListeners();
  }

  void _goToSceneKey(String sceneKey, Set<String> visited) {
    if (!visited.add(sceneKey)) {
      debugPrint('[GAME] Цикл в переходах пропущенных сцен: $sceneKey');
      return;
    }
    // Ищу сцену по sceneKey (SurrealDB-id)
    for (int i = 0; i < _state.data!.scenes.length; i++) {
      if (_state.data!.scenes[i].sceneKey == sceneKey) {
        final scene = _state.data!.scenes[i];

        // Проверяю условие
        if (!_isConditionMet(scene.condition)) {
          debugPrint('[GAME] Сцена ${scene.sceneKey} пропущена (условие: ${scene.condition})');

          // Условие не выполнено - иду дальше по nextSceneId этой сцены
          if (scene.nextSceneTarget.isNotEmpty) {
            _goToSceneKey(scene.nextSceneTarget, visited);
            return;
          }
          // Если nextSceneId == 0 - пробую следующую по индексу
          for (int j = i + 1; j < _state.data!.scenes.length; j++) {
            if (_isConditionMet(_state.data!.scenes[j].condition)) {
              _currentSceneIndex = j;
              _currentTextIndex = 0;
              return;
            }
          }
          // Если не нашли - перехожу на последнюю (или конец)
          _currentSceneIndex = _state.data!.scenes.length - 1;
          _currentTextIndex = 0;
          return;
        }

        // Условие выполнено - перехожу
        _currentSceneIndex = i;
        _currentTextIndex = 0;
        return;
      }
    }
    debugPrint('[GAME] Сцена перехода не найдена: $sceneKey');
  }

  // Выбрать следующую сцену по счётчикам (для автовыбора)
  int _pickSceneByCounters(int episodeId) {
    // Для эпизода 4: выбираю между 221 (Адриан), 226 (Кот), 231 (МариНет+Кот), 236 (ЛБ+Адриан)
    if (episodeId == 4) {
      // Считаю максимум среди romance_adrian, romance_cat, romance_ladybug_adrian, romance_ladybug_cat
      final adrian = _counters['romance_adrian']!;
      final cat = _counters['romance_cat']!;
      final lbAdrian = _counters['romance_ladybug_adrian']!;
      final lbCat = _counters['romance_ladybug_cat']!;

      final max = [adrian, cat, lbAdrian, lbCat].reduce((a, b) => a > b ? a : b);

      // Порядок проверки
      if (adrian == max && adrian > 0) return 221;
      if (cat == max && cat > 0) return 226;
      if (lbAdrian == max && lbAdrian > 0) return 236;
      if (lbCat == max && lbCat > 0) return 231;
      return 221; // По умолчанию Адриан
    }

    // Для эпизода 5: 5 веток - 308 (Адриан), 314 (Кот), 320 (Лука), 328 (МариНет+Кот), 334 (ЛБ+Адриан)
    if (episodeId == 5) {
      final adrian = _counters['romance_adrian']!;
      final cat = _counters['romance_cat']!;
      final luka = _counters['romance_luka']!;
      final lbAdrian = _counters['romance_ladybug_adrian']!;
      final lbCat = _counters['romance_ladybug_cat']!;

      final max = [adrian, cat, luka, lbAdrian, lbCat].reduce((a, b) => a > b ? a : b);

      if (adrian == max && adrian > 0) return 308;
      if (cat == max && cat > 0) return 314;
      if (luka == max && luka > 0) return 320;
      if (lbAdrian == max && lbAdrian > 0) return 334;
      if (lbCat == max && lbCat > 0) return 328;
      return 308; // По умолчанию Адриан
    }

    return 0;
  }

  // Переход к следующей сцене (по next_scene_id или по порядку)
  void nextScene() {
    if (_state.data == null) return;
    if (currentScene == null) return;

    // Проверяю: если это сцена 220 (эп 4) или 307 (эп 5) - автовыбор по счётчикам
    // Сравниваю по sceneKey (SurrealDB-id)
    final sceneKey = currentScene!.sceneKey;
    final episodeId = _state.data!.id;

    if ((episodeId == 4 && sceneKey == 'scene:220') ||
        (episodeId == 5 && sceneKey == 'scene:307')) {
      final picked = _pickSceneByCounters(episodeId);
      if (picked > 0) {
        debugPrint('[GAME] Автовыбор сцены по счётчикам: $picked');
        goToScene(picked);
        return;
      }
    }

    // Если у сцены задан nextSceneId - иду на него
    final nextKey = currentScene!.nextSceneTarget;
    if (nextKey.isNotEmpty) {
      goToSceneKey(nextKey);
      return;
    }

    // Если nextSceneId == 0 - конец эпизода
    return;
  }

  // Обработка выбора (индекс выбора в текущей сцене)
  void onChoiceSelected(int choiceIndex) {
    if (currentScene == null || _saveError != null) return;
    final choice = currentScene!.choices[choiceIndex];
    String target = '';
    for (final action in choice.actions) {
      // Переход на сцену (если тип nextScene)
      if (action.type == 'nextScene') {
        target = action.sceneTarget;
      }

      // Счётчик (работает и для nextScene, и для changeCounter)
      if (action.counterName.isNotEmpty && action.counterName != 'points') {
        // Конкретный счётчик (romance_adrian, friendship, ...)
        final current = _counters[action.counterName] ?? 0;
        _counters[action.counterName] = current + action.counterValue;
        debugPrint('[GAME] Счётчик ${action.counterName}: $current → ${_counters[action.counterName]}');
      } else if (action.counterName == 'points') {
        // Общие баллы
        _points += action.counterValue;
      }

      // Флаг (если задан)
      if (action.flagName.isNotEmpty) {
        _flags[action.flagName] = action.flagValue;
      }

      // Концовка (если тип ending)
      if (action.type == 'ending') {
        _ending = action.title;
      }
    }
    // Сначала применяю баллы и флаги, потом проверяю условие новой сцены
    if (target.isNotEmpty) _goToSceneKey(target, <String>{});
    _saveProgress();
    _checkAchievements();
    notifyListeners();
  }

  // Определить концовку по счётчикам (5 концовок)
  String determineEnding() {
    // Если концовка уже установлена вручную - возвращаю её
    if (_ending.isNotEmpty) return _ending;

    // Считаю максимум по 5 романтическим линиям
    final adrian = _counters['romance_adrian']!;
    final cat = _counters['romance_cat']!;
    final luka = _counters['romance_luka']!;
    final lbAdrian = _counters['romance_ladybug_adrian']!;
    final lbCat = _counters['romance_ladybug_cat']!;

    // Если всё по нулям - по умолчанию
    if (adrian == 0 && cat == 0 && luka == 0 && lbAdrian == 0 && lbCat == 0) {
      return 'МариКот';
    }

    final max = [adrian, cat, luka, lbAdrian, lbCat].reduce((a, b) => a > b ? a : b);

    // Порядок проверки - чтобы не было случайных совпадений
    if (adrian == max) return 'МариАдриан';
    if (cat == max) return 'МариКот';
    if (luka == max) return 'Лука';
    if (lbAdrian == max) return 'АдриБаг';
    if (lbCat == max) return 'СуперБаг';

    return 'МариКот';
  }

  // Проверить и открыть достижения
  Future<void> _checkAchievements() async {
    if (_achievementRepository == null) return;
    if (_state.data == null) return;

    try {
      // Достижение: максимум баллов
      if (_points >= 100) {
        await _achievementRepository.unlockAchievement(_playerId, 'max_points');
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

  // Ставлю в очередь отдельный снимок, а не изменяемые карты состояния
  // Завершение сохраняю только после последней реплики и нажатия кнопки
  Future<bool> completeEpisode() async {
    if (currentScene == null || !isLastScene || !isTextFinished ||
        currentScene!.choices.isNotEmpty || _saveError != null || _progressRepository == null) {
      return false;
    }
    if (_completed) {
      await flushProgress();
      return _saveError == null;
    }
    _completed = true;
    await _saveProgress();
    if (_saveError != null) {
      _completed = false;
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<void> _saveProgress() {
    if (_progressRepository == null || _state.data == null || _saveError != null) {
      return _saveQueue;
    }
    final playerId = _playerId;
    final episodeId = _state.data!.id;
    final sceneId = _currentSceneIdStr;
    final completed = _completed;
    final ending = completed ? determineEnding() : '';
    final flags = Map<String, bool>.unmodifiable(_flags);
    final counters = Map<String, int>.unmodifiable({'points': _points, ..._counters});
    _saveQueue = _saveQueue.then((_) async {
      if (_saveError != null) return;
      try {
        _revision = await _progressRepository.saveProgress(ProgressModel(
          playerId: playerId, episodeId: episodeId, sceneId: sceneId,
          flags: flags, counters: counters, revision: _revision, completed: completed, ending: ending,
        ));
      } catch (e) {
        // Не отправляю следующие старые снимки после неудачной записи
        _saveError = 'Не удалось сохранить прогресс: ${networkError(e)}';
        debugPrint(_saveError);
        notifyListeners();
      }
    });
    return _saveQueue;
  }
}
