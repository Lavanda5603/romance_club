import 'package:romance_club/src/domain/repositories/achievement_repository.dart';
import 'package:romance_club/src/domain/models/achievement_model.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romance_club/generated/episode.pb.dart';
import 'package:romance_club/generated/scene.pb.dart';
import 'package:romance_club/generated/choice.pb.dart';
import 'package:romance_club/generated/action.pb.dart';
import 'package:romance_club/screens/action_editor_screen.dart';
import 'package:romance_club/screens/scene_editor_screen.dart';
import 'package:romance_club/src/core/scene_links.dart';
import 'package:romance_club/src/data/repositories/episode_repository_remote.dart';
import 'package:romance_club/src/data/services/episode_grpc_service.dart';
import 'package:romance_club/src/domain/models/episode_model.dart';
import 'package:romance_club/src/domain/models/progress_model.dart';
import 'package:romance_club/src/domain/repositories/episode_repository.dart';
import 'package:romance_club/src/domain/repositories/progress_repository.dart';
import 'package:romance_club/src/features/game/game_view_model.dart';

class _Episodes implements EpisodeRepository {
  final EpisodeModel episode;
  _Episodes(this.episode);
  @override
  Future<EpisodeModel> getEpisode(int id) async => episode;
  @override
  Future<List<EpisodeModel>> getAllEpisodes() async => [episode];
  @override
  Future<bool> saveEpisode(EpisodeModel episode) async => true;
}

class _Progress implements ProgressRepository {
  @override
  Future<Set<int>> getProgressSummary(String playerId) async => saved.sceneId.isEmpty ? {} : {saved.episodeId};
  ProgressModel saved = ProgressModel.empty();
  final List<ProgressModel> writes = [];
  Completer<void>? gate;
  Completer<void>? readGate;
  bool fail = false;
  @override
  Future<ProgressModel> getProgress(String playerId, int episodeId) async {
    await readGate?.future;
    return saved;
  }
  @override
  Future<int> saveProgress(ProgressModel progress) async {
    writes.add(progress);
    await gate?.future;
    if (fail) throw StateError('Конфликт версии');
    saved = progress;
    return progress.revision + 1;
  }
  @override
  Future<bool> resetProgress(String playerId) async => true;
}

class _EpisodeProgress extends _Progress {
  final Map<int, ProgressModel> records = {};
  @override
  Future<ProgressModel> getProgress(String playerId, int episodeId) async =>
      records[episodeId] ?? ProgressModel.empty();
  @override
  Future<int> saveProgress(ProgressModel progress) async {
    records[progress.episodeId] = progress;
    return progress.revision + 1;
  }
  @override
  Future<bool> resetProgress(String playerId) async =>
      throw StateError('Нельзя сбрасывать все эпизоды');
}

class _Achievements extends AchievementRepository {
  final calls = <String>[];
  @override
  Future<List<AchievementModel>> getAchievements(String playerId) async => [];
  @override
  Future<bool> unlockAchievement(String playerId, String name) async { calls.add(name); return true; }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late EpisodeGrpcService service;
  late EpisodeRepositoryRemote mapper;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('scene_links_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => temp.path);
    service = EpisodeGrpcService();
    mapper = EpisodeRepositoryRemote(service);
  });
  tearDown(() async {
    await service.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await temp.delete(recursive: true);
  });

  Episode story() => Episode(id: 1, title: 'Проверка переходов', version: 1, scenes: [
    Scene(id: 200, sceneKey: 'scene:200', orderIndex: 0, title: 'Первая',
      texts: ['Начало'], nextSceneKey: 'scene:branch', choices: [
        Choice(text: 'Выбор', actions: [Action(type: 'nextScene', sceneKey: 'scene:ending')]),
      ]),
    Scene(sceneKey: 'scene:branch', orderIndex: 1, title: 'Ветка', texts: ['Ветка'], nextSceneKey: 'scene:ending'),
    Scene(sceneKey: 'scene:ending', orderIndex: 2, title: 'Конец', texts: ['Конец']),
  ]);

  test('Сохраняю строковые ключи в Protobuf и доменных моделях', () {
    final proto = Episode.fromBuffer(story().writeToBuffer());
    final domain = mapper.toDomain(proto);
    expect(domain.scenes[0].nextSceneTarget, 'scene:branch');
    expect(domain.scenes[0].choices[0].actions[0].sceneTarget, 'scene:ending');
    final restored = mapper.toProto(domain);
    expect(restored.scenes[0].nextSceneKey, 'scene:branch');
    expect(restored.scenes[0].choices[0].actions[0].sceneKey, 'scene:ending');
    expect(restored.scenes[2].orderIndex, 2);
  });

  test('Перехожу по строковым ключам и сохраняю настоящий ключ прогресса', () async {
    final progress = _Progress();
    final vm = GameViewModel(_Episodes(mapper.toDomain(story())), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1, startFromBeginning: true);
    vm.nextScene();
    expect(vm.currentScene!.sceneKey, 'scene:branch');
    await vm.flushProgress();
    expect(progress.saved.sceneId, 'scene:branch');
    vm.nextScene();
    expect(vm.currentScene!.sceneKey, 'scene:ending');
    expect(vm.isLastScene, isTrue);
    vm.goToScene(200);
    vm.onChoiceSelected(0);
    expect(vm.currentScene!.sceneKey, 'scene:ending');
  });

  test('Порядок сцен не меняет цель перехода и не завершает эпизод раньше времени', () async {
    final proto = story();
    final first = proto.scenes.removeAt(0);
    proto.scenes.add(first);
    final vm = GameViewModel(_Episodes(mapper.toDomain(proto)));
    addTearDown(vm.dispose);
    await vm.loadEpisode(1, startFromBeginning: true);
    vm.goToSceneKey('scene:200');
    expect(vm.isLastScene, isFalse);
    vm.nextScene();
    expect(vm.currentScene!.sceneKey, 'scene:branch');
  });

  test('Последняя сцена с переходом назад не завершает эпизод', () async {
    final proto = story();
    proto.scenes.last.nextSceneKey = 'scene:branch';
    final progress = _Progress();
    final vm = GameViewModel(_Episodes(mapper.toDomain(proto)), progress);
    addTearDown(vm.dispose);
    expect(vm.isLastScene, isFalse);
    await vm.loadEpisode(1);
    vm.goToSceneKey('scene:ending');
    await vm.flushProgress();
    expect(vm.isLastScene, isFalse);
    expect(await vm.completeEpisode(), isFalse);
    vm.nextScene();
    await vm.flushProgress();
    expect(vm.currentScene!.sceneKey, 'scene:branch');
    expect(progress.saved.completed, isFalse);
  });

  test('Конечная сцена в середине списка завершает эпизод', () async {
    final proto = story();
    final ending = proto.scenes.removeLast();
    proto.scenes.insert(1, ending);
    final progress = _Progress();
    final vm = GameViewModel(_Episodes(mapper.toDomain(proto)), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1);
    vm.goToSceneKey('scene:ending');
    expect(vm.isLastScene, isTrue);
    expect(await vm.completeEpisode(), isTrue);
    expect(progress.saved.completed, isTrue);
    expect(progress.saved.sceneId, 'scene:ending');
  });

  test('Последняя сцена со старым числовым переходом тоже не конец', () async {
    final proto = story();
    proto.scenes.last.nextSceneId = 200;
    final vm = GameViewModel(_Episodes(mapper.toDomain(proto)));
    addTearDown(vm.dispose);
    await vm.loadEpisode(1);
    vm.goToSceneKey('scene:ending');
    expect(vm.isLastScene, isFalse);
    expect(await vm.completeEpisode(), isFalse);
    vm.nextScene();
    expect(vm.currentScene!.sceneKey, 'scene:200');
  });

  test('Читаю старый числовой переход без привязки к номеру строки', () async {
    final proto = story();
    proto.scenes[1].id = 900;
    proto.scenes[1].sceneKey = 'scene:900';
    proto.scenes[0].nextSceneKey = '';
    proto.scenes[0].nextSceneId = 900;
    final vm = GameViewModel(_Episodes(mapper.toDomain(proto)));
    addTearDown(vm.dispose);
    await vm.loadEpisode(1, startFromBeginning: true);
    vm.nextScene();
    expect(vm.currentScene!.sceneKey, 'scene:900');
  });

  test('Останавливаю цикл пропущенных сцен с невыполненным условием', () async {
    final proto = story();
    proto.scenes[1].condition = 'points>100';
    proto.scenes[1].nextSceneKey = 'scene:branch';
    final vm = GameViewModel(_Episodes(mapper.toDomain(proto)));
    addTearDown(vm.dispose);
    await vm.loadEpisode(1, startFromBeginning: true);
    vm.nextScene();
    expect(vm.currentScene!.sceneKey, 'scene:200');
  });

  test('Новые сцены получают разные временные ключи', () {
    final keys = List.generate(100, (_) => newSceneKey());
    expect(keys.toSet().length, 100);
    expect(keys.every((key) => key.startsWith('draft:')), isTrue);
  });

  test('Выбор записываю один раз с баллами и флагами до проверки условия', () async {
    final proto = story();
    proto.scenes[0].choices[0].actions[0]
      ..counterName = 'points' ..counterValue = 2
      ..flagName = 'chosen' ..flagValue = true;
    proto.scenes[2].condition = 'points>=2';
    final progress = _Progress();
    final vm = GameViewModel(_Episodes(mapper.toDomain(proto)), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1);
    vm.onChoiceSelected(0);
    await vm.flushProgress();
    expect(progress.writes, hasLength(1));
    expect(progress.saved.sceneId, 'scene:ending');
    expect(progress.saved.counters['points'], 2);
    expect(progress.saved.flags['chosen'], isTrue);
    await vm.loadEpisode(1);
    expect(vm.points, 2);
    expect(vm.flags['chosen'], isTrue);
  });

  for (final position in ['до', 'внутри', 'после']) {
    for (final condition in ['flag:secret_scene=true', 'points>=5']) {
      test('Эффект $position nextScene открывает условие $condition', () async {
        final proto = story();
        final transition = Action(type: 'nextScene', sceneKey: 'scene:ending');
        final effect = Action(type: 'changeCounter', counterName: 'points', counterValue: 5,
          flagName: 'secret_scene', flagValue: true);
        final actions = proto.scenes[0].choices[0].actions;
        actions.clear();
        if (position == 'внутри') {
          transition
            ..counterName = 'points' ..counterValue = 5
            ..flagName = 'secret_scene' ..flagValue = true;
          actions.add(transition);
        } else {
          actions.addAll(position == 'до' ? [effect, transition] : [transition, effect]);
        }
        proto.scenes[2].condition = condition;
        final progress = _Progress();
        final vm = GameViewModel(_Episodes(mapper.toDomain(proto)), progress);
        addTearDown(vm.dispose);
        await vm.loadEpisode(1);
        vm.onChoiceSelected(0);
        expect(vm.currentScene!.sceneKey, 'scene:ending');
        await vm.flushProgress();
        expect(progress.writes, hasLength(1));
        expect(progress.saved.sceneId, 'scene:ending');
        expect(progress.saved.flags['secret_scene'], isTrue);
        expect(progress.saved.counters['points'], 5);
        await vm.loadEpisode(1);
        expect(vm.currentScene!.sceneKey, 'scene:ending');
        expect(vm.flags['secret_scene'], isTrue);
        expect(vm.points, 5);
      });
    }
  }

  test('Все эффекты выбора учитываю перед единственным переходом и сохранением', () async {
    final proto = story();
    proto.scenes[0].choices[0].actions
      ..clear()
      ..addAll([
        Action(type: 'nextScene', sceneKey: 'scene:branch', counterName: 'points', counterValue: 2),
        Action(type: 'setFlag', flagName: 'secret_scene', flagValue: true),
        Action(type: 'changeCounter', counterName: 'points', counterValue: 3),
        Action(type: 'nextScene', sceneKey: 'scene:ending', counterName: 'friendship', counterValue: 4),
      ]);
    proto.scenes[2].condition = 'points>=5';
    final progress = _Progress();
    final vm = GameViewModel(_Episodes(mapper.toDomain(proto)), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1);
    final visited = <String>[];
    vm.addListener(() { visited.add(vm.currentScene!.sceneKey); });
    vm.onChoiceSelected(0);
    await vm.flushProgress();
    expect(visited, ['scene:ending']);
    expect(progress.writes, hasLength(1));
    expect(progress.saved.sceneId, 'scene:ending');
    expect(progress.saved.counters['points'], 5);
    expect(progress.saved.counters['friendship'], 4);
    expect(progress.saved.flags['secret_scene'], isTrue);
  });

  test('Сброс записываю до открытия игры и восстанавливаю после выхода без перехода', () async {
    final progress = _Progress()..saved = const ProgressModel(
      playerId: 'player:1', episodeId: 1, sceneId: 'scene:ending',
      revision: 7, completed: true, ending: 'Секрет',
      flags: {'secret': true}, counters: {'points': 100, 'friendship': 9},
    );
    final vm = GameViewModel(_Episodes(mapper.toDomain(story())), progress);
    progress.gate = Completer<void>();
    final loading = vm.loadEpisode(1, startFromBeginning: true);
    while (progress.writes.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(vm.state.isLoading, isTrue);
    expect(vm.currentScene, isNull);
    expect(progress.saved.sceneId, 'scene:ending');
    progress.gate!.complete();
    await loading;
    expect(vm.state.error, isNull);
    expect(progress.writes, hasLength(1));
    expect(progress.saved.episodeId, 1);
    expect(progress.saved.revision, 7);
    expect(progress.saved.completed, isFalse);
    expect(progress.saved.ending, isEmpty);
    expect(progress.saved.flags, isEmpty);
    expect(progress.saved.counters.values.every((value) => value == 0), isTrue);
    vm.dispose();
    final reopened = GameViewModel(_Episodes(mapper.toDomain(story())), progress);
    addTearDown(reopened.dispose);
    await reopened.loadEpisode(1);
    expect(reopened.currentScene!.sceneKey, 'scene:200');
    expect(reopened.points, 0);
    expect(reopened.completed, isFalse);
  });

  test('При отказе сброса не открываю игру и сохраняю прежнюю запись', () async {
    final old = const ProgressModel(playerId: 'player:1', episodeId: 1,
      sceneId: 'scene:ending', flags: {'old': true}, counters: {'points': 50});
    final progress = _Progress()..saved = old..fail = true;
    final vm = GameViewModel(_Episodes(mapper.toDomain(story())), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1, startFromBeginning: true);
    expect(vm.state.error, isNotNull);
    expect(vm.state.isLoading, isFalse);
    expect(vm.currentScene, isNull);
    expect(progress.saved, same(old));
    progress.fail = false;
    await vm.loadEpisode(1, startFromBeginning: true);
    expect(vm.state.error, isNull);
    expect(progress.saved.sceneId, 'scene:200');
  });

  test('Начало одного эпизода не меняет сохранение другого', () async {
    final progress = _EpisodeProgress();
    const other = ProgressModel(playerId: 'player:1', episodeId: 2,
      sceneId: 'scene:other', completed: true, revision: 8,
      flags: {'secret': true}, counters: {'points': 80});
    progress.records[2] = other;
    final vm = GameViewModel(_Episodes(mapper.toDomain(story())), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1, startFromBeginning: true);
    expect(vm.state.error, isNull);
    expect(progress.records[1]!.sceneId, 'scene:200');
    expect(progress.records[2], same(other));
  });

  test('Начатый эпизод завершаю только после подтверждения конца', () async {
    final progress = _Progress();
    final vm = GameViewModel(_Episodes(mapper.toDomain(story())), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1);
    expect(await vm.completeEpisode(), isFalse);
    vm.nextScene();
    await vm.flushProgress();
    expect(progress.saved.completed, isFalse);
    vm.nextScene();
    await vm.flushProgress();
    expect(vm.currentScene!.sceneKey, 'scene:ending');
    expect(progress.saved.completed, isFalse);
    final before = progress.writes.length;
    expect(await vm.completeEpisode(), isTrue);
    expect(progress.writes.length, before + 1);
    expect(progress.saved.completed, isTrue);
    expect(progress.saved.sceneId, 'scene:ending');
    expect(await vm.completeEpisode(), isTrue);
    expect(progress.writes.length, before + 1);
    await vm.loadEpisode(1);
    expect(vm.completed, isTrue);
    await vm.loadEpisode(1, startFromBeginning: true);
    expect(vm.completed, isFalse);
    expect(progress.saved.completed, isFalse);
  });

  test('Конец с несколькими репликами нельзя завершить до последней', () async {
    final proto = story();
    proto.scenes[2].texts.add('Последняя реплика');
    final progress = _Progress();
    final vm = GameViewModel(_Episodes(mapper.toDomain(proto)), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1);
    vm.goToSceneKey('scene:ending');
    await vm.flushProgress();
    expect(await vm.completeEpisode(), isFalse);
    expect(progress.saved.completed, isFalse);
    vm.nextText();
    expect(await vm.completeEpisode(), isTrue);
    expect(progress.saved.completed, isTrue);
  });

  test('Завершение дожидается записи и не скрывает отказ сохранения', () async {
    final progress = _Progress();
    final vm = GameViewModel(_Episodes(mapper.toDomain(story())), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1);
    vm.goToSceneKey('scene:ending');
    await vm.flushProgress();
    progress.gate = Completer<void>();
    progress.fail = true;
    var finished = false;
    final ending = vm.completeEpisode().then((value) { finished = true; return value; });
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    expect(progress.saved.completed, isFalse);
    progress.gate!.complete();
    expect(await ending, isFalse);
    expect(vm.completed, isFalse);
    expect(progress.saved.completed, isFalse);
    expect(vm.saveError, isNotNull);
  });

  test('Не выдаю достижения «все» до чтения, концовку передаю с завершением', () async {
    final proto = story();
    proto.scenes[0].choices[0].actions.add(Action(type:'ending', title:'Секрет'));
    final progress = _Progress();
    final achievements = _Achievements();
    final vm = GameViewModel(_Episodes(mapper.toDomain(proto)), progress, achievements);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1);
    vm.onChoiceSelected(0);
    await vm.flushProgress();
    expect(progress.saved.completed, isFalse);
    expect(progress.saved.ending, isEmpty);
    expect(achievements.calls, isNot(contains('all_episodes')));
    expect(achievements.calls, isNot(contains('all_endings')));
    expect(await vm.completeEpisode(), isTrue);
    expect(progress.saved.ending, 'Секрет');
    await vm.loadEpisode(1);
    expect(vm.determineEnding(), 'Секрет');
    expect(achievements.calls, isNot(contains('all_endings')));
  });

  test('Медленные записи идут по очереди со своими снимками и версиями', () async {
    final progress = _Progress()..gate = Completer<void>();
    final vm = GameViewModel(_Episodes(mapper.toDomain(story())), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1);
    vm.nextScene();
    vm.flags['later'] = true;
    vm.nextScene();
    await Future<void>.delayed(Duration.zero);
    expect(progress.writes, hasLength(1));
    expect(progress.writes.first.sceneId, 'scene:branch');
    expect(progress.writes.first.flags, isEmpty);
    progress.gate!.complete();
    await vm.flushProgress();
    expect(progress.writes.map((p) => p.revision), [0, 1]);
    expect(progress.saved.sceneId, 'scene:ending');
    expect(progress.saved.flags['later'], isTrue);
  });

  test('После конфликта не отправляю старые снимки и показываю ошибку', () async {
    final progress = _Progress()..fail = true;
    final vm = GameViewModel(_Episodes(mapper.toDomain(story())), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1);
    vm.nextScene();
    vm.nextScene();
    await vm.flushProgress();
    expect(progress.writes, hasLength(1));
    expect(vm.saveError, contains('Конфликт версии'));
    expect(progress.saved.sceneId, isEmpty);
    progress.fail = false;
    await vm.loadEpisode(1);
    vm.nextScene();
    await vm.flushProgress();
    expect(vm.saveError, isNull);
    expect(progress.saved.sceneId, 'scene:branch');
  });

  test('Закрытие экрана не обрывает уже поставленную запись', () async {
    final progress = _Progress()..gate = Completer<void>();
    final vm = GameViewModel(_Episodes(mapper.toDomain(story())), progress);
    await vm.loadEpisode(1);
    vm.nextScene();
    vm.dispose();
    progress.gate!.complete();
    await vm.flushProgress();
    expect(progress.saved.sceneId, 'scene:branch');
  });

  test('Не начинаю игру и запись, пока не загружена версия прогресса', () async {
    final progress = _Progress()..readGate = Completer<void>();
    progress.saved = const ProgressModel(playerId: 'player:test', episodeId: 1,
      sceneId: 'scene:200', revision: 7, flags: {}, counters: {'points': 2});
    final vm = GameViewModel(_Episodes(mapper.toDomain(story())), progress);
    addTearDown(vm.dispose);
    final loading = vm.loadEpisode(1);
    await Future<void>.delayed(Duration.zero);
    expect(vm.state.isLoading, isTrue);
    vm.nextScene();
    expect(progress.writes, isEmpty);
    progress.readGate!.complete();
    await loading;
    vm.nextScene();
    await vm.flushProgress();
    expect(progress.saved.revision, 7);
    expect(progress.saved.counters['points'], 2);
  });

  testWidgets('В редакторе действия выбираю сцену по ключу', (tester) async {
    // Одинаковые старые id не должны объединять разные сцены
    final scenes = [
      Scene(id: 1, sceneKey: 'scene:200', title: 'Первая'),
      Scene(id: 1, sceneKey: 'scene:branch', title: 'Ветка'),
    ];
    await tester.pumpWidget(MaterialApp(home: ActionEditorScreen(
      allScenes: scenes,
      action: Action(type: 'nextScene', sceneKey: 'scene:branch'),
      onSave: (_) {},
    )));
    final dropdown = tester.widget<DropdownButton<String>>(find.byKey(const ValueKey('action-scene-target')));
    expect(dropdown.value, 'scene:branch');
    expect(dropdown.items!.map((item) => item.value), ['', 'scene:200', 'scene:branch']);
    expect(tester.takeException(), isNull);
  });
  testWidgets('В редакторе сцены сохраняю выбранный ключ без подмены номером', (tester) async {
    final scenes = [
      Scene(id: 1, sceneKey: 'scene:200', title: 'Первая', nextSceneKey: 'scene:branch'),
      Scene(id: 1, sceneKey: 'scene:branch', title: 'Ветка'),
    ];
    Scene? saved;
    await tester.pumpWidget(MaterialApp(home: SceneEditorScreen(
      scene: scenes[0], allScenes: scenes, onSave: (scene) => saved = scene,
    )));
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButton<String>>(find.byKey(const ValueKey('scene-target')));
    expect(dropdown.value, 'scene:branch');
    expect(dropdown.items!.map((item) => item.value), ['', 'scene:200', 'scene:branch']);
    dropdown.onChanged!('scene:200');
    await tester.pump();
    await tester.ensureVisible(find.text('сохранить').last);
    await tester.tap(find.text('сохранить').last);
    await tester.pump();
    expect(saved!.sceneKey, 'scene:200');
    expect(saved!.nextSceneKey, 'scene:200');
    expect(saved!.nextSceneId, 0);
    expect(tester.takeException(), isNull);
  });

  test('После изменения названия и перестановки продолжаю с сохранённой сцены', () async {
    final progress = _Progress();
    progress.saved = const ProgressModel(playerId: 'player:test', episodeId: 1,
      sceneId: 'scene:branch', flags: {'saved_flag': true}, counters: {'points': 12, 'friendship': 3});
    final edited = story();
    edited.title = 'Новое название';
    edited.scenes[1].texts[0] = 'Изменённый текст';
    final branch = edited.scenes.removeAt(1);
    edited.scenes.insert(0, branch);
    final vm = GameViewModel(_Episodes(mapper.toDomain(edited)), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1);
    expect(vm.currentScene!.sceneKey, 'scene:branch');
    expect(vm.currentText, 'Изменённый текст');
    expect(vm.points, 12);
    expect(vm.friendshipPoints, 3);
    expect(vm.flags['saved_flag'], isTrue);
    expect(progress.saved.sceneId, 'scene:branch');
  });

  test('При старой удалённой сцене не подменяю прогресс началом эпизода', () async {
    final progress = _Progress();
    progress.saved = const ProgressModel(playerId: 'player:test', episodeId: 1,
      sceneId: 'scene:deleted', flags: {'saved_flag': true}, counters: {'points': 12});
    final vm = GameViewModel(_Episodes(mapper.toDomain(story())), progress);
    addTearDown(vm.dispose);
    await vm.loadEpisode(1);
    expect(vm.state.error, contains('Сохранённая сцена больше не существует'));
    expect(vm.progressSceneMissing, isTrue);
    expect(vm.currentScene, isNull);
    expect(progress.saved.sceneId, 'scene:deleted');
    expect(progress.saved.counters['points'], 12);
    // Только явный перезапуск записывает новую стартовую позицию
    await vm.loadEpisode(1, startFromBeginning: true);
    expect(vm.state.error, isNull);
    expect(vm.progressSceneMissing, isFalse);
    expect(progress.saved.sceneId, 'scene:200');
    expect(progress.saved.counters['points'], 0);
  });

}
