import 'dart:async'; // Импорт управляемой загрузки эпизода
import 'dart:io'; // Импорт временного хранилища
import 'dart:ui' as ui; // Импорт кодирования тестовой картинки
import 'package:flutter/material.dart'; // Импорт игровых виджетов
import 'package:flutter/services.dart'; // Импорт канала хранилища и байтов
import 'package:flutter_test/flutter_test.dart'; // Импорт тестов Flutter
import 'package:grpc/grpc.dart'; // Импорт ответа об отсутствующей картинке
import 'package:romance_club/generated/episode.pb.dart'; // Импорт метаданных эпизода
import 'package:romance_club/screens/game_screen.dart'; // Импорт игрового экрана
import 'package:romance_club/services/session_store.dart'; // Импорт полной тестовой сессии
import 'package:romance_club/src/domain/models/episode_model.dart'; // Импорт полного дерева эпизода
import 'package:romance_club/src/domain/models/asset_model.dart'; // Импорт картинки
import 'package:romance_club/src/domain/repositories/episode_repository.dart'; // Импорт загрузки эпизода
import 'package:romance_club/src/domain/repositories/asset_repository.dart'; // Импорт загрузки картинок
import 'package:romance_club/src/features/game/game_view_model.dart'; // Импорт игровой логики

class _Episodes implements EpisodeRepository {
  final calls = <int>[];
  Completer<EpisodeModel>? pending;
  @override
  Future<EpisodeModel> getEpisode(int id) async {
    calls.add(id);
    return pending == null ? story(id) : pending!.future;
  }
  @override
  Future<List<EpisodeModel>> getAllEpisodes() async => [];
  @override
  Future<bool> saveEpisode(EpisodeModel episode) async => true;
}

EpisodeModel story(int id) => EpisodeModel(id: id, title: 'Полный эпизод $id', version: 1,
  scenes: [for (var i = 1; i <= 2; i++) SceneModel(id: i, sceneKey: 'scene:$id$i', title: 'Сцена $i',
    background: 'room$id$i', character: 'hero$id', characterEmotion: i == 1 ? 'happy' : 'sad',
    texts: ['Реплика $id$i'], choices: [], condition: '', textPosition: 'bottom_center',
    characterPosition: 'center', nextSceneId: 0, nextSceneKey: i == 1 ? 'scene:${id}2' : '')]);

class _Assets implements AssetRepository {
  final Uint8List bytes;
  bool missing = false; // Проверяю точную локальную копию при отсутствии файла на сервере
  final calls = <String>[];
  _Assets(this.bytes);
  @override
  Future<AssetPage> getAssetPage(String type, {String episodeId = '', String cursor = '', int limit = 24}) async {
    fail('Игра не должна скачивать каталог');
  }
  @override
  Future<AssetModel> getAsset({String id = '', String type = '', String name = '', String emotion = '',
    String episodeId = '', String version = '', String variant = '', int targetWidth = 0, int targetHeight = 0}) async {
    expect(variant, 'screen');
    expect(targetWidth, greaterThan(0));
    expect(targetHeight, greaterThan(0));
    calls.add('$episodeId|$type|$name|$emotion');
    if (missing) throw const GrpcError.notFound('Точной картинки нет в каталоге');
    return AssetModel(id: 'asset:$name', type: type, name: name, emotion: emotion,
      url: '', displayName: name, episodeId: episodeId, fileData: bytes);
  }
  @override
  Future<bool> deleteAsset(String id) async => false;
  @override
  Future<AssetModel?> uploadAsset({required String type, required String name, required String emotion,
    required String displayName, required String episodeId, required Uint8List fileData, required String fileName}) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory folder;
  late Uint8List bytes;
  setUpAll(() async {
    final image = await createTestImage(width: 2, height: 2);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    bytes = png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
    image.dispose();
  });
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('game_assets_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async => folder.path);
    SessionStore.shared = SessionStore();
    await SessionStore.shared.save(const Session('player:test', 'test-token'));
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await folder.delete(recursive: true);
  });

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }
  Finder pictures() => find.byWidgetPredicate((widget) => widget is Image && widget.image is MemoryImage);

  testWidgets('Точные локальные картинки пары и бегущей Маринетт доступны после NotFound', (tester) async {
    final episode = story(1);
    final first = episode.scenes.first;
    final localStory = EpisodeModel(id: 1, title: episode.title, version: 1,
      scenes: [SceneModel(id: first.id, sceneKey: first.sceneKey, title: first.title,
        background: 'ep1/kiss_marinet_adrian', character: 'marinet', characterEmotion: 'running',
        texts: first.texts, choices: [], condition: '', textPosition: first.textPosition,
        characterPosition: first.characterPosition, nextSceneId: 0, nextSceneKey: '')]);
    final episodes = _Episodes()..pending = Completer<EpisodeModel>();
    final assets = _Assets(bytes)..missing = true;
    final vm = GameViewModel(episodes);
    addTearDown(vm.dispose);
    await tester.pumpWidget(MaterialApp(home: GameScreen(episode: Episode(id: 1), viewModel: vm, assetRepository: assets)));
    episodes.pending!.complete(localStory);
    await drain(tester);
    expect(assets.calls, ['episode:1|background|ep1/kiss_marinet_adrian|', 'episode:1|character|marinet|running']);
    expect(pictures(), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Пустые метаданные ждут полного эпизода, после загрузки видны обе картинки', (tester) async {
    final episodes = _Episodes()..pending = Completer<EpisodeModel>();
    final assets = _Assets(bytes);
    final vm = GameViewModel(episodes);
    addTearDown(vm.dispose);
    final metadata = Episode(id: 1, title: 'Из списка');
    await tester.pumpWidget(MaterialApp(home: GameScreen(episode: metadata, viewModel: vm, assetRepository: assets)));
    await drain(tester);
    expect(episodes.calls, [1]);
    expect(metadata.scenes, isEmpty);
    expect(assets.calls, isEmpty);
    episodes.pending!.complete(story(1));
    await drain(tester);
    expect(assets.calls, ['episode:1|background|room11|', 'episode:1|character|hero1|happy']);
    expect(pictures(), findsNWidgets(2));
    expect(find.text('Реплика 11'), findsOneWidget);
    // Новая реплика не вызывает повторного скачивания
    vm.notifyListeners();
    await tester.pump();
    expect(assets.calls, hasLength(2));
    vm.goToSceneKey('scene:12');
    await drain(tester);
    expect(assets.calls.skip(2), ['episode:1|background|room12|', 'episode:1|character|hero1|sad']);
    expect(pictures(), findsNWidgets(2));
    expect(find.text('Реплика 12'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Следующий эпизод и повторный вход берут картинки из своего полного дерева', (tester) async {
    final episodes = _Episodes();
    final assets = _Assets(bytes);
    for (final id in [1, 2, 1]) {
      final vm = GameViewModel(episodes);
      await tester.pumpWidget(MaterialApp(home: GameScreen(key: UniqueKey(),
        episode: Episode(id: id), viewModel: vm, assetRepository: assets)));
      await drain(tester);
      expect(assets.calls.skip(assets.calls.length - 2), ['episode:$id|background|room${id}1|', 'episode:$id|character|hero$id|happy']);
      expect(pictures(), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    }
    expect(episodes.calls, [1, 2, 1]);
    expect(tester.takeException(), isNull);
  });
}