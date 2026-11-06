import 'dart:io'; // Импорт для временного хранилища
import 'dart:async'; // Импорт задержанного ответа сервера
import 'package:flutter/services.dart'; // Импорт платформенных каналов
import 'package:flutter_test/flutter_test.dart'; // Импорт тестов Flutter
import 'package:grpc/grpc.dart'; // Импорт gRPC
import 'package:romance_club/generated/asset_api.pbgrpc.dart'; // Импорт контракта ассетов
import 'package:romance_club/generated/auth_api.pbgrpc.dart'; // Импорт контракта авторизации
import 'package:romance_club/services/session_store.dart'; // Импорт хранения сессии
import 'package:romance_club/src/data/services/asset_grpc_service.dart'; // Импорт сервиса ассетов
import 'package:romance_club/src/data/services/auth_grpc_service.dart'; // Импорт сервиса авторизации
import 'package:romance_club/src/data/services/admin_grpc_service.dart'; // Импорт сервиса админа
import 'package:romance_club/src/data/services/rpc_policy.dart'; // Импорт ошибок сети

class _Assets extends AssetApiServiceBase {
  final calls = <ServiceCall>[];
  bool expired = false;
  Completer<void>? pause;
  final started = Completer<void>();
  void check(ServiceCall call) {
    calls.add(call);
    if (expired) throw const GrpcError.unauthenticated('Expired token');
    if (call.clientMetadata?['authorization'] == null) {
      throw const GrpcError.unauthenticated();
    }
  }
  @override
  Future<GetAssetsResponse> getAssets(ServiceCall call, GetAssetsRequest request) async {
    if (!started.isCompleted) started.complete();
    await pause?.future;
    check(call);
    return GetAssetsResponse();
  }
  @override
  Future<Asset> getAsset(ServiceCall call, GetAssetRequest request) async {
    check(call);
    return Asset(id: request.id);
  }
  @override
  Future<UploadAssetResponse> uploadAsset(ServiceCall call, UploadAssetRequest request) async {
    check(call);
    return UploadAssetResponse(success: true);
  }
  @override
  Future<DeleteAssetResponse> deleteAsset(ServiceCall call, DeleteAssetRequest request) async {
    check(call);
    return DeleteAssetResponse(success: true);
  }
}

class _Auth extends AuthApiServiceBase {
  final calls = <ServiceCall>[];
  @override
  Future<AuthResponse> login(ServiceCall call, LoginRequest request) async {
    calls.add(call);
    return AuthResponse(success: true);
  }
  @override
  Future<AuthResponse> register(ServiceCall call, RegisterRequest request) => login(call, LoginRequest());
  @override
  Future<AuthResponse> getPlayer(ServiceCall call, GetPlayerRequest request) => login(call, LoginRequest());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory storage;
  late Server server;
  late _Assets handler;
  late _Auth authHandler;
  late AssetGrpcService assets;
  late AuthGrpcService auth;
  late AdminGrpcService admin;
  setUp(() async {
    SessionStore.shared = SessionStore();
    storage = await Directory.systemTemp.createTemp('rpc_auth_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => storage.path);
    handler = _Assets();
    authHandler = _Auth();
    server = Server.create(services: [handler, authHandler]);
    await server.serve(address: '127.0.0.1', port: 0);
    assets = AssetGrpcService(host: '127.0.0.1', port: server.port!);
    auth = AuthGrpcService(host: '127.0.0.1', port: server.port!);
    admin = AdminGrpcService(host: '127.0.0.1', port: server.port!);
  });
  tearDown(() async {
    await assets.close();
    await auth.close();
    await admin.close();
    await server.shutdown();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await storage.delete(recursive: true);
  });

  test('Все методы ассетов отправляют текущий токен вместе с deadline', () async {
    await SessionStore.shared.save(const Session('player:1', 'first'));
    await assets.getAssetPage('background');
    await assets.getAsset(id: 'asset:1');
    await assets.uploadAsset(type: 'background', name: 'test', emotion: '',
      displayName: 'test', episodeId: 'episode:1', fileData: Uint8List.fromList([1]), fileName: 'test.png');
    await assets.deleteAsset('asset:1');
    expect(handler.calls, hasLength(4));
    for (final call in handler.calls) {
      expect(call.clientMetadata?['authorization'], 'Bearer first');
      expect(call.deadline, isNotNull);
    }
    // После нового входа сервис беру тот же, а токен уже другой
    await SessionStore.shared.save(const Session('player:1', 'second'));
    await assets.getAssetPage('background');
    expect(handler.calls.last.clientMetadata?['authorization'], 'Bearer second');
  });

  test('Login и Register публичные даже при сохранённом старом токене', () async {
    await SessionStore.shared.save(const Session('player:1', 'expired'));
    await auth.login(login: 'test', password: 'test');
    await auth.register(login: 'test', email: 'test@example.com', password: 'test');
    await auth.getPlayer('player:1');
    expect(authHandler.calls[0].clientMetadata?['authorization'], isNull);
    expect(authHandler.calls[1].clientMetadata?['authorization'], isNull);
    expect(authHandler.calls[2].clientMetadata?['authorization'], 'Bearer expired');
    expect(authHandler.calls.every((call) => call.deadline != null), isTrue);
  });

  test('Без токена защищённые методы не отправляют анонимный запрос', () async {
    final denied = throwsA(isA<GrpcError>().having((e) => e.code, 'code', StatusCode.unauthenticated));
    await expectLater(assets.getAssetPage('background'), denied);
    await expectLater(auth.getPlayer('player:1'), denied);
    await expectLater(admin.deleteAsset('asset:1'), denied);
    await expectLater(admin.deleteEpisode(1), denied);
    expect(handler.calls, isEmpty);
    expect(authHandler.calls, isEmpty);
  });

  test('Истёкшая сессия показывает причину и допускает повтор после входа', () async {
    await SessionStore.shared.save(const Session('player:1', 'expired'));
    handler.expired = true;
    final expired = SessionStore.shared.expired.first;
    try {
      await assets.getAssetPage('background');
      fail('Сервер должен отклонить токен');
    } on GrpcError catch (error) {
      expect(error.code, StatusCode.unauthenticated);
      expect(networkError(error), contains('войдите снова'));
    }
    await expired;
    expect(await SessionStore.shared.load(), isNull);
    handler.expired = false;
    await SessionStore.shared.save(const Session('player:1', 'new-session'));
    await assets.getAssetPage('background');
    expect(handler.calls.last.clientMetadata?['authorization'], 'Bearer new-session');
    expect(networkError(const GrpcError.permissionDenied('Только админ')), 'Только админ');
  });

  test('Поздний UNAUTHENTICATED старого RPC не очищает новый вход', () async {
    await SessionStore.shared.save(const Session('player:a', 'old'));
    handler.pause = Completer<void>();
    handler.expired = true;
    final result = expectLater(assets.getAssetPage('background'),
      throwsA(isA<GrpcError>().having((error) => error.code, 'code', StatusCode.unauthenticated)));
    await handler.started.future;
    await SessionStore.shared.save(const Session('player:b', 'new'));
    handler.pause!.complete();
    await result;
    // Чтение очереди дожидается проверки отказавшего токена
    expect((await SessionStore.shared.load())!.token, 'new');
  });
}
