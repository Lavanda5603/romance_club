import 'dart:async'; // Импорт для Future и Completer
import 'dart:typed_data'; // Импорт для байтов картинки
import 'dart:ui' as ui; // Импорт графических классов Flutter
import 'package:flutter/material.dart'; // Импорт Material UI
import 'package:flutter_test/flutter_test.dart'; // Импорт для тестов Flutter
import 'package:romance_club/generated/episode.pb.dart'; // Импорт Protobuf-моделей эпизодов
import 'package:romance_club/generated/scene.pb.dart'; // Импорт Protobuf-моделей сцен
import 'package:romance_club/screens/scene_editor_screen.dart'; // Импорт экрана редактора сцены
import 'package:romance_club/screens/game_screen.dart'; // Импорт экрана игры
import 'package:romance_club/src/domain/models/asset_model.dart'; // Импорт модели ассетов
import 'package:romance_club/src/domain/models/episode_model.dart'; // Импорт модели эпизодов
import 'package:romance_club/src/domain/repositories/asset_repository.dart'; // Импорт интерфейса репозитория ассетов
import 'package:romance_club/src/domain/repositories/episode_repository.dart'; // Импорт интерфейса репозитория эпизодов
import 'package:romance_club/src/features/game/game_view_model.dart'; // Импорт состояния и логики игры
import 'package:romance_club/src/core/async_state.dart'; // Импорт состояния загрузки

class _Assets implements AssetRepository {
  final Uint8List bytes;
  final requests = <String>[];
  final sizes = <String>[];
  final waits = <String, Completer<AssetModel>>{};
  int pages = 0;
  _Assets(this.bytes);
  AssetModel model(String name) => AssetModel(id: 'asset:$name', type: 'background', name: name,
    emotion: '', url: '', displayName: name, episodeId: 'episode:7', fileData: bytes, previewData: bytes);
  @override
  Future<AssetModel> getAsset({String id = '', String type = '', String name = '', String emotion = '', String episodeId = '', String version = '', String variant = '', int targetWidth = 0, int targetHeight = 0}) async {
    requests.add('$type|$name|$emotion|$episodeId');
    sizes.add('$variant|$targetWidth|$targetHeight');
    return waits[name]?.future ?? model(name);
  }
  @override
  Future<AssetPage> getAssetPage(String type, {String episodeId = '', String cursor = '', int limit = 24}) async {
    pages++;
    return const AssetPage([], '');
  }
  @override
  Future<bool> deleteAsset(String id) async => true;
  @override
  Future<AssetModel?> uploadAsset({required String type, required String name, required String emotion,
    required String displayName, required String episodeId, required Uint8List fileData, required String fileName}) async => null;
}

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

class _Game extends GameViewModel {
  final _Episodes episodes;
  AsyncState<EpisodeModel> _loaded = AsyncState.idle();
  int _index = 0;
  _Game(this.episodes) : super(episodes);
  @override
  AsyncState<EpisodeModel> get state => _loaded;
  @override
  SceneModel? get currentScene => _loaded.data?.scenes[_index];
  @override
  Future<void> loadEpisode(int id, {bool startFromBeginning = false}) async {
    _loaded = AsyncState.loading();
    notifyListeners();
    _loaded = AsyncState.success(await episodes.getEpisode(id));
    notifyListeners();
  }
  @override
  void nextScene() {
    _index++;
    notifyListeners();
  }
}

void main() {
  Future<Uint8List> picture(WidgetTester tester) async => (await tester.runAsync(() async {
    final image = await createTestImage(width: 2, height: 2);
    try {
      final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally { image.dispose(); }
  }))!;

  testWidgets('Редактор запрашивает только выбранные фон и эмоцию персонажа', (tester) async {
    final assets = _Assets(await picture(tester));
    await tester.pumpWidget(MaterialApp(home: SceneEditorScreen(
      scene: Scene(background: 'city', character: 'hero', characterEmotion: 'happy'),
      episodeId: 'episode:7', assetRepository: assets, onSave: (_) {},
    )));
    await tester.pumpAndSettle();
    expect(assets.requests, containsAll(['background|city||episode:7', 'character|hero|happy|episode:7']));
    expect(assets.requests, hasLength(2));
    expect(assets.pages, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Пустая сцена не отправляет запросы картинок и каталога', (tester) async {
    final assets = _Assets(await picture(tester));
    await tester.pumpWidget(MaterialApp(home: SceneEditorScreen(scene: Scene(), assetRepository: assets, onSave: (_) {})));
    await tester.pumpAndSettle();
    expect(assets.requests, isEmpty);
    expect(assets.pages, 0);
  });

  testWidgets('Медленный ответ не возвращает удалённого персонажа в предпросмотр', (tester) async {
    final assets = _Assets(await picture(tester));
    final pending = Completer<AssetModel>();
    assets.waits['hero'] = pending;
    await tester.pumpWidget(MaterialApp(home: SceneEditorScreen(
      scene: Scene(character: 'hero', characterEmotion: 'happy'),
      assetRepository: assets, onSave: (_) {},
    )));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.close));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    pending.complete(assets.model('hero'));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((widget) => widget is Image && widget.image is MemoryImage), findsNothing);
    expect(assets.pages, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Игра берёт картинки загруженной сцены при пустых scenes в списке эпизодов', (tester) async {
    final assets = _Assets(await picture(tester));
    const full = EpisodeModel(id: 7, title: 'Полный эпизод', version: 1, scenes: [
      SceneModel(id: 1, sceneKey: 'scene:1', title: 'Первая', background: 'city', character: 'hero', characterEmotion: 'happy',
        texts: ['Текст'], choices: [], condition: '', textPosition: 'bottom_center', characterPosition: 'center', nextSceneId: 2),
      SceneModel(id: 2, sceneKey: 'scene:2', title: 'Вторая', background: 'room', character: '', characterEmotion: '',
        texts: ['Продолжение'], choices: [], condition: '', textPosition: 'bottom_center', characterPosition: 'center', nextSceneId: 0),
    ]);
    final game = _Game(_Episodes(full));
    addTearDown(game.dispose);
    final summary = Episode(id: 7, title: 'Краткий эпизод');
    expect(summary.scenes, isEmpty);
    await tester.pumpWidget(MaterialApp(home: GameScreen(episode: summary, viewModel: game, assetRepository: assets)));
    await tester.pumpAndSettle();
    expect(find.text('Текст'), findsOneWidget);
    expect(assets.requests, containsAll(['background|city||episode:7', 'character|hero|happy|episode:7']));
    expect(assets.requests, hasLength(2));
    expect(assets.pages, 0);
    expect(assets.sizes.every((size) => size.startsWith('screen|')), isTrue);
    expect(assets.sizes.every((size) => !size.contains('|0|')), isTrue);
    game.nextScene();
    await tester.pumpAndSettle();
    expect(assets.requests.last, 'background|room||episode:7');
    expect(assets.requests, hasLength(3));
    expect(assets.pages, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
