import 'dart:io';
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
  ProgressModel saved = ProgressModel.empty();
  @override
  Future<ProgressModel> getProgress(String playerId, int episodeId) async => saved;
  @override
  Future<bool> saveProgress(ProgressModel progress) async { saved = progress; return true; }
  @override
  Future<bool> resetProgress(String playerId) async => true;
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
