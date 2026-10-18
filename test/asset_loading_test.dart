import 'package:file_picker/file_picker.dart'; // Импорт выбора файла
import 'package:grpc/grpc.dart'; // Импорт для gRPC-запросов
import 'dart:async'; // Импорт для Future и Completer
import 'dart:io'; // Импорт для работы с файлами
import 'dart:typed_data'; // Импорт для байтов картинки
import 'dart:ui' as ui; // Импорт графических классов Flutter
import 'package:flutter/material.dart'; // Импорт Material UI
import 'package:flutter_test/flutter_test.dart'; // Импорт для тестов Flutter
import 'package:romance_club/generated/asset_api.pbgrpc.dart'; // Импорт gRPC-контракта ассетов
import 'package:romance_club/generated/admin_api.pbgrpc.dart'; // Импорт gRPC-контракта админа
import 'package:romance_club/src/data/services/admin_grpc_service.dart'; // Импорт gRPC-сервиса админа
import 'package:romance_club/src/data/repositories/admin_repository_remote.dart'; // Импорт серверного репозитория админа
import 'package:romance_club/screens/asset_picker_screen.dart'; // Импорт экрана выбора картинки
import 'package:romance_club/src/data/services/asset_grpc_service.dart'; // Импорт gRPC-сервиса ассетов
import 'package:romance_club/src/data/repositories/asset_repository_remote.dart'; // Импорт серверного репозитория ассетов
import 'package:romance_club/src/data/repositories/asset_cache.dart'; // Импорт кэша картинок
import 'package:romance_club/src/domain/models/asset_model.dart'; // Импорт модели ассетов
import 'package:romance_club/src/domain/repositories/asset_repository.dart'; // Импорт интерфейса репозитория ассетов

class _Service extends AssetGrpcService {
  int pages = 0;
  int originals = 0;
  final sizes = <String>[];
  int lookups = 0;
  String scope = 'test';
  Completer<GetAssetsResponse>? pending;
  @override
  Future<String> cacheScope() async => scope;
  @override
  Future<GetAssetsResponse> getAssetPage(String type, {String episodeId = '', String cursor = '', int limit = 24}) async {
    pages++;
    if (pending != null) return pending!.future;
    return GetAssetsResponse(assets: [Asset(id: 'asset:1', type: type, version: 'v1', previewData: [1])]);
  }
  @override
  Future<Asset> getAsset({String id = '', String type = '', String name = '', String emotion = '', String episodeId = '', bool metadataOnly = false, String variant = '', int targetWidth = 0, int targetHeight = 0}) async {
    if (metadataOnly) {
      lookups++;
      return Asset(id: 'asset:1', type: type, name: name, emotion: emotion, version: 'v1');
    }
    originals++;
    sizes.add('$variant|$targetWidth|$targetHeight');
    return Asset(id: id, type: type.isEmpty ? 'background' : type, fileData: variant == 'screen' ? [4, 5] : [2, 3], version: 'v1');
  }
  @override
  Future<UploadAssetResponse> uploadAsset({required String type, required String name, required String emotion,
    required String displayName, required String episodeId, required Uint8List fileData, required String fileName}) async =>
    UploadAssetResponse(success: true, asset: Asset(type: type));
  @override
  Future<DeleteAssetResponse> deleteAsset(String id) async => DeleteAssetResponse(success: true);
}

class _PickerRepository implements AssetRepository {
  Uint8List? previewBytes;
  Uint8List? originalBytes;
  final pages = <String>[];
  int originals = 0;
  final second = Completer<AssetPage>();
  AssetModel model(String id) => AssetModel(id: id, type: 'background', name: id, emotion: '', url: '',
    displayName: id, episodeId: '', fileData: originalBytes ?? Uint8List(0), previewData: previewBytes);
  @override
  Future<AssetPage> getAssetPage(String type, {String episodeId = '', String cursor = '', int limit = 24}) async {
    pages.add(cursor);
    return cursor.isEmpty ? AssetPage([model('asset:first')], 'next') : second.future;
  }
  @override
  Future<AssetModel> getAsset({String id = '', String type = '', String name = '', String emotion = '', String episodeId = '', String version = '', String variant = '', int targetWidth = 0, int targetHeight = 0}) async {
    originals++;
    return model(id);
  }
  @override
  Future<bool> deleteAsset(String id) async => true;
  @override
  Future<AssetModel?> uploadAsset({required String type, required String name, required String emotion,
    required String displayName, required String episodeId, required Uint8List fileData, required String fileName}) async => null;
}

class _AdminService extends AdminGrpcService {
  @override
  Future<AdminResponse> deleteAsset(String assetId) async => AdminResponse(success: true);
}

class _TimeoutPickerRepository extends _PickerRepository {
  int attempts = 0;
  @override
  Future<AssetPage> getAssetPage(String type, {String episodeId = '', String cursor = '', int limit = 24}) async {
    if (++attempts == 1) throw const GrpcError.deadlineExceeded();
    return AssetPage([], '');
  }
}

class _Files extends FilePicker {
  final int size;
  _Files([this.size = 3]);
  @override
  Future<FilePickerResult?> pickFiles({String? dialogTitle, String? initialDirectory,
    FileType type = FileType.any, List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading, bool allowCompression = false,
    int compressionQuality = 0, bool allowMultiple = false, bool withData = false,
    bool withReadStream = false, bool lockParentWindow = false, bool readSequential = false}) async =>
    FilePickerResult([PlatformFile(name: 'room.png', size: size, bytes: Uint8List(size))]);
}

class _Uploads extends _PickerRepository {
  String? uploadedName;
  String? uploadedEpisode;
  final String existingEpisode;
  _Uploads(this.existingEpisode);
  @override
  Future<AssetPage> getAssetPage(String type, {String episodeId = '', String cursor = '', int limit = 24}) async =>
    AssetPage([AssetModel(id: 'asset:room', type: type, name: 'room', emotion: '', url: '',
      displayName: 'Комната', episodeId: existingEpisode, fileData: Uint8List(0))], '');
  @override
  Future<AssetModel?> uploadAsset({required String type, required String name, required String emotion,
    required String displayName, required String episodeId, required Uint8List fileData, required String fileName}) async {
    uploadedName = name;
    uploadedEpisode = episodeId;
    return model('asset:new');
  }
}

void main() {
  test('Экранный размер и оригинал храню в разных записях кэша', () async {
    final service = _Service();
    addTearDown(service.close);
    AssetRepositoryRemote.invalidateCache();
    final repository = AssetRepositoryRemote(service);
    final original = await repository.getAsset(id:'asset:1', version:'v1');
    final screen = await repository.getAsset(id:'asset:1', version:'v1', variant:'screen', targetWidth:720, targetHeight:1280);
    final again = await repository.getAsset(id:'asset:1', version:'v1', variant:'screen', targetWidth:720, targetHeight:1280);
    expect(original.fileData, [2,3]);
    expect(screen.fileData, [4,5]);
    expect(identical(screen.fileData, again.fileData), isTrue);
    expect(service.originals, 2);
    expect(service.sizes, ['|0|0','screen|720|1280']);
    await repository.getAsset(id:'asset:1', version:'v1', variant:'screen', targetWidth:1080, targetHeight:1920);
    expect(service.originals, 3);
  });
  test('Сервис отклоняет лишний байт до авторизации и отправки', () async {
    final service = AssetGrpcService(host: '127.0.0.1', port: 1);
    try {
      await expectLater(service.uploadAsset(type: 'background', name: 'large', emotion: '',
        displayName: 'large', episodeId: 'episode:2', fileName: 'large.png',
        fileData: Uint8List(AssetGrpcService.maxUploadBytes + 1)),
        throwsA(isA<GrpcError>().having((e) => e.code, 'code', StatusCode.invalidArgument)));
    } finally {
      await service.close();
    }
  });
  testWidgets('Picker принимает до 5 MiB и не отправляет файл больше лимита', (tester) async {
    final previous = FilePicker.platform;
    addTearDown(() => FilePicker.platform = previous);
    for (final size in [4 * 1024 * 1024 + 512 * 1024, AssetGrpcService.maxUploadBytes, AssetGrpcService.maxUploadBytes + 1]) {
      FilePicker.platform = _Files(size);
      final repo = _Uploads('');
      await tester.pumpWidget(MaterialApp(home: AssetPickerScreen(key: ValueKey(size),
        type: 'background', title: 'Фоны', episodeId: 'episode:2', repository: repo)));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.upload));
      await tester.pumpAndSettle();
      if (size > AssetGrpcService.maxUploadBytes) {
        expect(find.text('Файл больше 5 MiB (5 242 880 байт)'), findsOneWidget);
        expect(repo.uploadedName, isNull);
        expect(find.byType(AlertDialog), findsNothing);
      } else {
        await tester.enterText(find.byType(TextField).first, 'large');
        await tester.tap(find.text('Загрузить'));
        await tester.pumpAndSettle();
        expect(repo.uploadedName, 'large');
      }
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });

  setUpAll(() { FilePicker.platform = _Files(); });
  testWidgets('Загрузка фона передаёт текущий эпизод без префикса ep1', (tester) async {
    final previous = FilePicker.platform;
    FilePicker.platform = _Files();
    addTearDown(() => FilePicker.platform = previous);
    for (final episode in ['episode:2', 'episode:3', '']) {
      final repo = _Uploads(episode.isEmpty ? 'episode:1' : '');
      await tester.pumpWidget(MaterialApp(home: AssetPickerScreen(key: ValueKey(episode),
        type: 'background', title: 'Фоны', episodeId: episode, repository: repo)));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.upload));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'room');
      await tester.tap(find.text('Загрузить'));
      await tester.pumpAndSettle();
      expect(repo.uploadedName, 'room');
      expect(repo.uploadedEpisode, episode);
      expect(find.text('Ассет загружен'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });
  testWidgets('Дубликат в том же эпизоде не отправляется повторно', (tester) async {
    final previous = FilePicker.platform;
    FilePicker.platform = _Files();
    addTearDown(() => FilePicker.platform = previous);
    final repo = _Uploads('episode:2');
    await tester.pumpWidget(MaterialApp(home: AssetPickerScreen(type: 'background', title: 'Фоны',
      episodeId: 'episode:2', repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.upload));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'room');
    await tester.tap(find.text('Загрузить'));
    await tester.pumpAndSettle();
    expect(repo.uploadedName, isNull);
    expect(find.text('Ассет с таким именем и эмоцией уже существует'), findsOneWidget);
  });

  testWidgets('После deadline сетка снимает загрузку и позволяет повторить', (tester) async {
    final repo = _TimeoutPickerRepository();
    await tester.pumpWidget(MaterialApp(home: AssetPickerScreen(type: 'background', title: 'Фоны', repository: repo)));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Сервер не ответил вовремя'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(repo.attempts, 2);
    expect(find.text('нет ассетов'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  late _Service service;
  late AssetRepositoryRemote repository;
  setUp(() {
    AssetRepositoryRemote.invalidateCache();
    service = _Service();
    repository = AssetRepositoryRemote(service);
  });
  tearDown(() => service.close());

  test('Повторный вход использует страницу, оригинал отдельно и по версии', () async {
    final first = await repository.getAssetPage('background', episodeId: 'episode:1');
    await AssetRepositoryRemote(service).getAssetPage('background', episodeId: 'episode:1');
    expect(service.pages, 1);
    expect(service.originals, 0);
    expect(first.assets.single.fileData, isEmpty);
    expect(first.assets.single.previewData, [1]);
    await repository.getAsset(id: 'asset:1', type: 'background', version: 'v1');
    await repository.getAsset(id: 'asset:1', type: 'background', version: 'v1');
    expect(service.originals, 1);
    await repository.getAsset(id: 'asset:1', type: 'background', version: 'v2');
    expect(service.originals, 2);
    service.scope = 'another user';
    await repository.getAssetPage('background', episodeId: 'episode:1');
    expect(service.pages, 2);
  });

  test('Холодный поиск по имени не загружает каталог и переиспользует оригинал по ID', () async {
    final selected = await repository.getAsset(id: 'asset:1', type: 'background', version: 'v1');
    final inEditor = await AssetRepositoryRemote(service).getAsset(type: 'background', name: 'city', episodeId: 'episode:1');
    expect(service.pages, 0);
    expect(service.lookups, 1);
    expect(service.originals, 1);
    expect(inEditor.fileData, same(selected.fileData));
    final inGame = await repository.getAsset(type: 'background', name: 'city', episodeId: 'episode:1');
    expect(service.lookups, 1);
    expect(inGame.fileData, same(selected.fileData));
  });

  test('Холодный поиск по имени скачивает ровно один оригинал без каталога', () async {
    final original = await repository.getAsset(type: 'background', name: 'city', episodeId: 'episode:1');
    expect(service.pages, 0);
    expect(service.lookups, 1);
    expect(service.originals, 1);
    final selected = await repository.getAsset(id: 'asset:1', type: 'background', version: 'v1');
    expect(selected.fileData, same(original.fileData));
    expect(service.originals, 1);
    AssetRepositoryRemote.invalidateCache('background');
    await repository.getAsset(type: 'background', name: 'city', episodeId: 'episode:1');
    expect(service.lookups, 2);
    expect(service.originals, 2);
  });

  test('Загрузка общего ассета сбрасывает все эпизоды и страницы типа', () async {
    Future<void> load() async {
      for (final ep in ['', 'episode:1', 'episode:2']) {
        for (final cursor in ['', 'next']) {
          await repository.getAssetPage('background', episodeId: ep, cursor: cursor);
        }
      }
    }
    await load();
    await repository.getAssetPage('character');
    await repository.uploadAsset(type: 'background', name: 'new', emotion: '', displayName: 'New',
      episodeId: '', fileData: Uint8List(0), fileName: 'new.png');
    await load();
    await repository.getAssetPage('character');
    expect(service.pages, 13);
    await repository.deleteAsset('asset:1');
    await repository.getAssetPage('character');
    expect(service.pages, 14);
  });

  test('Ответ старого запроса после сброса не возвращается в кэш', () async {
    service.pending = Completer<GetAssetsResponse>();
    final loading = repository.getAssetPage('background');
    await Future<void>.delayed(Duration.zero);
    AssetRepositoryRemote.invalidateCache('background');
    service.pending!.complete(GetAssetsResponse());
    await loading;
    service.pending = null;
    await repository.getAssetPage('background');
    expect(service.pages, 2);
  });

  test('Удаление через AdminApi тоже сбрасывает кэш страниц', () async {
    final admin = _AdminService();
    addTearDown(admin.close);
    await repository.getAssetPage('background', episodeId: 'episode:1');
    await repository.getAssetPage('background', episodeId: 'episode:2');
    expect(await AdminRepositoryRemote(admin).deleteAsset('asset:1'), isTrue);
    await repository.getAssetPage('background', episodeId: 'episode:1');
    await repository.getAssetPage('background', episodeId: 'episode:2');
    expect(service.pages, 4);
  });

  test('Кэш ограничивает память и вытесняет давно не использованные файлы', () {
    final cache = AssetCache<String>(maxBytes: 6, maxEntries: 3);
    cache.put('one', 'background', 'one', 3);
    cache.put('two', 'background', 'two', 3);
    expect(cache.get('one'), 'one');
    cache.put('three', 'background', 'three', 3);
    expect(cache.get('two'), isNull);
    cache.put('large', 'background', 'large', 7);
    expect(cache.get('large'), isNull);
    cache.invalidate('background');
    expect(cache.get('one'), isNull);
  });

  testWidgets('Сетка показывает первую страницу до второй и не запрашивает оригиналы', (tester) async {
    final repo = _PickerRepository();
    await tester.pumpWidget(MaterialApp(home: AssetPickerScreen(type: 'background', title: 'Фоны', repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('asset:first'), findsOneWidget);
    expect(repo.pages, ['']);
    expect(repo.originals, 0);
    await tester.tap(find.text('Загрузить ещё'));
    await tester.pump();
    expect(find.text('asset:first'), findsOneWidget);
    expect(repo.pages, ['', 'next']);
    repo.second.complete(AssetPage([repo.model('asset:second')], ''));
    await tester.pumpAndSettle();
    expect(find.text('asset:second'), findsOneWidget);
    expect(find.text('Загрузить ещё'), findsNothing);
    expect(repo.originals, 0);
    await tester.tap(find.text('asset:second'));
    await tester.pumpAndSettle();
    expect(repo.originals, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Перестроение сетки сохраняет буфер и ключ MemoryImage', (tester) async {
    final bytes = await tester.runAsync(() async {
      final image = await createTestImage(width: 2, height: 2);
      try {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        return png!.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
      } finally {
        image.dispose();
      }
    });
    final repo = _PickerRepository()..previewBytes = bytes;
    Widget screen({bool dark = false}) => MaterialApp(
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      home: AssetPickerScreen(type: 'background', title: 'Фоны', repository: repo),
    );
    MemoryImage provider() => tester.widget<Image>(find.byWidgetPredicate(
      (widget) => widget is Image && widget.image is MemoryImage,
    ).first).image as MemoryImage;

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    final before = provider();
    expect(before.bytes, same(bytes));
    final key = await before.obtainKey(ImageConfiguration.empty);

    // Начало загрузки страницы вызывает setState у уже показанных ячеек
    await tester.tap(find.text('Загрузить ещё'));
    await tester.pump();
    expect(provider().bytes, same(bytes));
    expect(await provider().obtainKey(ImageConfiguration.empty), key);

    repo.second.complete(AssetPage([repo.model('asset:second')], ''));
    await tester.pumpAndSettle();
    await tester.pumpWidget(screen(dark: true));
    await tester.pumpAndSettle();
    expect(provider().bytes, same(bytes));
    expect(await provider().obtainKey(ImageConfiguration.empty), key);
    expect(repo.originals, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('При DPR 3 сетка декодирует миниатюру вместо большого оригинала', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final preview = await tester.runAsync(() async {
      final image = await createTestImage(width: 122, height: 160);
      try {
        final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        image.dispose();
      }
    });
    final repo = _PickerRepository()
      ..previewBytes = preview
      ..originalBytes = await tester.runAsync(() => File('assets/images/ep1/crosswalk.png').readAsBytes());
    await tester.pumpWidget(MaterialApp(home: AssetPickerScreen(type: 'background', title: 'Фоны', repository: repo)));
    await tester.pumpAndSettle();
    final provider = tester.widget<Image>(find.byWidgetPredicate(
      (widget) => widget is Image && widget.image is MemoryImage,
    ).first).image as MemoryImage;
    expect(provider.bytes, same(preview));
    expect(provider.bytes, isNot(same(repo.originalBytes)));
    await tester.runAsync(() async {
      final ready = Completer<ImageInfo>();
      final stream = provider.resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener((info, _) {
        if (!ready.isCompleted) ready.complete(info.clone());
      }, onError: (Object error, StackTrace? stack) {
        if (!ready.isCompleted) ready.completeError(error, stack);
      });
      stream.addListener(listener);
      try {
        final info = await ready.future;
        try {
          expect(info.image.width, lessThanOrEqualTo(160));
          expect(info.image.height, lessThanOrEqualTo(160));
          expect(info.image.width * info.image.height * 4, lessThanOrEqualTo(102400));
        } finally {
          info.dispose();
        }
      } finally {
        stream.removeListener(listener);
      }
    });
    expect(repo.originals, 0);
    expect(tester.takeException(), isNull);
  });
}
