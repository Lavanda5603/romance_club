import 'dart:convert'; // Читаю подготовленные сюжетные вставки
import 'dart:io'; // Подключаю файлы тестовых данных
import 'package:flutter/services.dart'; // Подключаю подмену локального хранилища
import 'package:flutter_test/flutter_test.dart'; // Подключаю проверки Flutter
import 'package:romance_club/generated/episode.pb.dart'; // Подключаю эпизоды
import 'package:romance_club/generated/scene.pb.dart'; // Подключаю сцены и правила
import 'package:romance_club/generated/choice.pb.dart'; // Подключаю выборы
import 'package:romance_club/generated/action.pb.dart'; // Подключаю действия
import 'package:romance_club/services/session_store.dart'; // Подключаю тестовую сессию
import 'package:romance_club/src/data/repositories/episode_repository_remote.dart'; // Подключаю преобразование моделей
import 'package:romance_club/src/data/services/episode_grpc_service.dart'; // Подключаю клиент для преобразования без RPC
import 'package:romance_club/src/domain/models/episode_model.dart'; // Подключаю доменный эпизод
import 'package:romance_club/src/domain/models/progress_model.dart'; // Подключаю снимок прогресса
import 'package:romance_club/src/domain/repositories/episode_repository.dart'; // Подключаю контракт истории
import 'package:romance_club/src/domain/repositories/progress_repository.dart'; // Подключаю контракт прогресса
import 'package:romance_club/src/features/game/game_view_model.dart'; // Подключаю настоящий движок

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
  ProgressModel saved;
  _Progress(this.saved);
  @override
  Future<ProgressModel> getProgress(String playerId, int episodeId) async => saved;
  @override
  Future<int> saveProgress(ProgressModel progress) async {
    saved = progress;
    return progress.revision + 1;
  }
  @override
  Future<Set<int>> getProgressSummary(String playerId) async => {};
  @override
  Future<bool> resetProgress(String playerId) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = jsonDecode(File('server/story/hidden_scenes.json').readAsStringSync()) as Map<String, dynamic>;
  final nodes = (manifest['scenes'] as List).cast<Map<String, dynamic>>();
  late Directory folder;
  late EpisodeGrpcService service;
  late EpisodeRepositoryRemote mapper;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('hidden_scenes_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => folder.path);
    SessionStore.shared = SessionStore();
    await SessionStore.shared.save(const Session('player:check', 'test-token'));
    service = EpisodeGrpcService();
    mapper = EpisodeRepositoryRemote(service);
  });
  tearDown(() async {
    await service.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await folder.delete(recursive: true);
  });

  // Основные сцены заменяю короткими заглушками, сами вставки беру из сюжетного файла.
  EpisodeModel episode(int id) {
    final scenes = <String, Scene>{'scene:test_start': Scene(sceneKey: 'scene:test_start', texts: ['Начало'])};
    for (final node in nodes.where((n) => n['episode'] == id)) {
      final key = node['key'] as String;
      final target = node['next'] as String;
      scenes[key] = Scene(sceneKey: key, title: node['title'], condition: node['condition'],
        texts: (node['texts'] as List).cast<String>(), nextSceneKey: target,
        choices: [for (final reply in node['replies']) Choice(text: reply['text'], actions: [
          Action(type: 'nextScene', sceneKey: target, counterName: reply['counter'] ?? '', counterValue: reply['value'] ?? 0,
            flagName: reply['flag'] ?? 'secret_scene', flagValue: reply['flag_value'] ?? true),
          Action(type: 'changeFlag', flagName: node['seen_flag'], flagValue: true),
          Action(type: 'changeFlag', flagName: 'secret_scene', flagValue: true),
        ])]);
    }
    for (final entry in (manifest['entries'] as List).where((e) => e['episode'] == id)) {
      scenes[entry['key']] = Scene(sceneKey: entry['key'], texts: ['Основной сюжет'], nextSceneKey: entry['next']);
    }
    for (final entry in (manifest['conditional_entries'] as List).where((e) => e['episode'] == id)) {
      scenes[entry['key']] = Scene(sceneKey: entry['key'], texts: ['Основной сюжет'], nextSceneKey: entry['next'],
        routes: [for (final route in entry['routes']) SceneRoute(condition: route['condition'], sceneKey: route['scene_key'])]);
    }
    final targets = scenes.values.expand((s) => [s.nextSceneKey, ...s.routes.map((r) => r.sceneKey)]).where((k) => k.isNotEmpty).toSet();
    for (final key in targets) { scenes.putIfAbsent(key, () => Scene(sceneKey: key, texts: ['Основной сюжет'])); }
    return mapper.toDomain(Episode(id: id, scenes: scenes.values));
  }

  final unlocks = <String, (Map<String, int>, Map<String, bool>)>{
    'ep1_alya': ({'friendship_alya': 2}, {}),
    'ep1_tikki': ({}, {'помог_дедушке': true}),
    'ep2_luka': ({'romance_luka': 3}, {}),
    'ep2_cat': ({'romance_cat': 1}, {}),
    'ep2_adrian': ({'romance_ladybug_adrian': 2}, {'говорила_с_адрианом_ночью': true}),
    'ep3_fu': ({'friendship': 3}, {'помог_дедушке': true}),
    'ep3_blog': ({'friendship_alya': 2}, {}),
    'ep3_kagami': ({'friendship_kagami': 2}, {'дружелюбна_с_кагами': true}),
    'ep3_chloe': ({'friendship': 2}, {}),
    'ep4_luka': ({'romance_luka': 5}, {'намекнула_о_секрете': true}),
    'ep4_mask': ({'romance_ladybug_cat': 5}, {}),
    'ep4_adrian': ({'romance_ladybug_adrian': 5}, {}),
  };

  for (final node in nodes.where((n) => n['kind'] == 'bonus')) {
    final key = node['key'] as String;
    final id = node['episode'] as int;
    final (counters, flags) = unlocks[key.replaceFirst('scene:hidden_', '')]!;
    for (final open in [false, true]) {
      test('${node['title']}: ${open ? 'читаю, сохраняю и не повторяю' : 'закрытая вставка не блокирует сюжет'}', () async {
        final model = episode(id);
        final progress = _Progress(ProgressModel(playerId: 'player:check', episodeId: id,
          sceneId: 'scene:test_start', flags: open ? flags : {}, counters: open ? counters : {}));
        final vm = GameViewModel(_Episodes(model), progress);
        await vm.loadEpisode(id);
        vm.goToSceneKey(key);
        expect(vm.state.error, null);
        if (open) {
          expect(vm.currentScene!.sceneKey, key);
          expect(vm.flags['secret_scene'], isNot(true));
          await vm.flushProgress();
          // Восстанавливаю незаконченный разговор до установки флага прочтения.
          final resumed = GameViewModel(_Episodes(model), progress);
          await resumed.loadEpisode(id);
          expect(resumed.currentScene!.sceneKey, key);
          expect(resumed.flags[node['seen_flag']], isNot(true));
          resumed.dispose();
          while (vm.hasMoreTexts) { vm.nextText(); }
          vm.onChoiceSelected(0);
          expect(vm.flags[node['seen_flag']], true);
          expect(vm.flags['secret_scene'], true);
          expect(vm.currentScene!.sceneKey, isNot(key));
          await vm.flushProgress();
          expect(progress.saved.flags[node['seen_flag']], true);
          vm.goToSceneKey(key);
          expect(vm.currentScene!.sceneKey, isNot(key));
        } else {
          expect(vm.currentScene!.sceneKey, isNot(key));
          expect(vm.flags['secret_scene'], isNot(true));
        }
        await vm.flushProgress();
        vm.dispose();
      });
    }
  }

  for (final early in [false, true]) {
    test('Лука: ${early ? 'не повторяю раннее признание' : 'сохраняю обычное признание'}', () async {
      final progress = _Progress(ProgressModel(playerId: 'player:check', episodeId: 4,
        sceneId: 'scene:216', counters: {}, flags: {'seen_hidden_ep4_luka': early}));
      final vm = GameViewModel(_Episodes(episode(4)), progress);
      await vm.loadEpisode(4);
      vm.nextScene();
      expect(vm.currentScene!.sceneKey, early ? 'scene:hidden_ep4_luka_reminder' : 'scene:217');
      await vm.flushProgress();
      vm.dispose();
    });
  }

  for (final team in [false, true]) {
    test('Особый финал ${team ? 'команды' : 'выбора себя'} читаю до завершения', () async {
      final counters = team ? {'friendship_alya': 2, 'friendship_nino': 2, 'friendship_kagami': 2, 'friendship_chloe': 2} : <String,int>{};
      final progress = _Progress(ProgressModel(playerId: 'player:check', episodeId: 5,
        sceneId: 'scene:307', counters: counters, flags: {}));
      final vm = GameViewModel(_Episodes(episode(5)), progress);
      await vm.loadEpisode(5);
      vm.nextScene();
      expect(vm.currentScene!.sceneKey, team ? 'scene:hidden_team_final' : 'scene:hidden_self_final');
      expect(vm.currentScene!.texts.length, greaterThan(1));
      expect(await vm.completeEpisode(), false);
      while (vm.hasMoreTexts) { vm.nextText(); }
      expect(await vm.completeEpisode(), true);
      expect(progress.saved.ending, team ? 'Команда вместе' : 'Выбираю себя');
      expect(progress.saved.completed, true);
      vm.dispose();
    });
  }
}