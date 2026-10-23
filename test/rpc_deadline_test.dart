import 'dart:async'; // Импорт для Future и Completer
import 'package:flutter_test/flutter_test.dart'; // Импорт для тестов Flutter
import 'package:grpc/grpc.dart'; // Импорт для gRPC-запросов
import 'package:romance_club/generated/auth_api.pbgrpc.dart'; // Импорт gRPC-контракта авторизации
import 'package:romance_club/src/data/services/auth_grpc_service.dart'; // Импорт gRPC-сервиса авторизации
import 'package:romance_club/src/data/services/rpc_policy.dart'; // Импорт сроков ожидания и ошибок сети

class _Auth extends AuthApiServiceBase {
  final started = Completer<void>();
  final finish = Completer<AuthResponse>();
  ServiceCall? call;
  int requests = 0;
  @override
  Future<AuthResponse> login(ServiceCall call, LoginRequest request) {
    requests++;
    this.call = call;
    if (!started.isCompleted) started.complete();
    if (request.login == 'retry') return Future.value(AuthResponse(success: true));
    return finish.future;
  }
  @override
  Future<AuthResponse> register(ServiceCall call, RegisterRequest request) => finish.future;
  @override
  Future<AuthResponse> getPlayer(ServiceCall call, GetPlayerRequest request) => finish.future;
}

void main() {
  test('Разные сроки для чтения, записи и файлов', () {
    final policy = RpcDeadline();
    expect(policy.timeoutFor('/AssetApi/GetAssets'), const Duration(seconds: 15));
    expect(policy.timeoutFor('/ProgressApi/GetProgress'), const Duration(seconds: 15));
    expect(policy.timeoutFor('/EpisodeApi/GetEpisode'), const Duration(seconds: 30));
    expect(policy.timeoutFor('/ProgressApi/SaveProgress'), const Duration(seconds: 30));
    expect(policy.timeoutFor('/ShopApi/Purchase'), const Duration(seconds: 30));
    expect(policy.timeoutFor('/AssetApi/UploadAsset'), const Duration(seconds: 60));
    expect(policy.timeoutFor('/AssetApi/GetAsset'), const Duration(seconds: 60));
  });

  test('Открытое соединение без ответа завершается deadline, повтор работает', () async {
    final handler = _Auth();
    final server = Server.create(services: [handler]);
    await server.serve(address: '127.0.0.1', port: 0);
    final service = AuthGrpcService(host: '127.0.0.1', port: server.port!,
      deadlines: RpcDeadline(write: const Duration(seconds: 1)));
    try {
      // Сначала открываю соединение, чтобы проверять зависший ответ, а не первое подключение
      expect((await service.login(login: 'retry', password: 'test')).success, isTrue);
      final pending = service.login(login: 'hang', password: 'test');
      await expectLater(pending, throwsA(isA<GrpcError>().having((e) => e.code, 'code', StatusCode.deadlineExceeded)));
      expect(handler.started.isCompleted, isTrue);
      expect(handler.requests, 2);
      expect(handler.call!.deadline, isNotNull);
      expect((await service.login(login: 'retry', password: 'test')).success, isTrue);
      expect(handler.requests, 3);
    } finally {
      handler.finish.complete(AuthResponse());
      await service.close();
      await server.shutdown();
    }
  });

  test('Закрытие сервиса отменяет ответ, не ждёт deadline', () async {
    final handler = _Auth();
    final server = Server.create(services: [handler]);
    await server.serve(address: '127.0.0.1', port: 0);
    final service = AuthGrpcService(host: '127.0.0.1', port: server.port!);
    try {
      final result = expectLater(service.login(login: 'hang', password: 'test'), throwsA(isA<GrpcError>()));
      await handler.started.future.timeout(const Duration(seconds: 3));
      await service.close().timeout(const Duration(seconds: 2));
      await result.timeout(const Duration(seconds: 2));
    } finally {
      handler.finish.complete(AuthResponse());
      await server.shutdown();
    }
  });

  test('Deadline сохраняет токен и не увеличивает заданный короткий срок', () async {
    final handler = _Auth();
    final server = Server.create(services: [handler]);
    await server.serve(address: '127.0.0.1', port: 0);
    final channel = ClientChannel('127.0.0.1', port: server.port!,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()));
    final api = AuthApiClient(channel, interceptors: [RpcDeadline()]);
    try {
      // Короткий срок проверяю на уже открытом соединении
      await api.login(LoginRequest(login: 'retry'), options: CallOptions(timeout: const Duration(seconds: 3)));
      await expectLater(api.login(LoginRequest(login: 'hang'), options: CallOptions(
        timeout: const Duration(milliseconds: 250), metadata: {'authorization': 'Bearer test-token'})),
        throwsA(isA<GrpcError>().having((e) => e.code, 'code', StatusCode.deadlineExceeded)));
      expect(handler.call!.clientMetadata?['authorization'], 'Bearer test-token');
    } finally {
      handler.finish.complete(AuthResponse());
      await channel.terminate();
      await server.shutdown();
    }
  });

  test('Ошибки зависшего ответа и подключения различаются', () {
    expect(networkError(const GrpcError.deadlineExceeded()), contains('не ответил вовремя'));
    expect(networkError(const GrpcError.unavailable()), contains('Проверьте подключение'));
    expect(networkError(const GrpcError.permissionDenied('Нет прав')), 'Нет прав');
  });
}