import 'dart:io'; // Импорт временной папки настроек
import 'package:flutter/services.dart'; // Импорт подмены пути приложения
import 'package:flutter_test/flutter_test.dart'; // Импорт проверок подключения
import 'package:romance_club/services/server_connection.dart'; // Импорт общего адреса сервера
import 'package:romance_club/src/data/services/asset_grpc_service.dart'; // Импорт проверки канала и кэша

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory folder;
  late String oldHost;
  late int oldPort;
  setUp(() async {
    oldHost = ServerConnection.host;
    oldPort = ServerConnection.port;
    folder = await Directory.systemTemp.createTemp('server_connection_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (_) async => folder.path);
  });
  tearDown(() async {
    ServerConnection.host = oldHost;
    ServerConnection.port = oldPort;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await folder.delete(recursive: true);
  });

  test('Сохраняю адрес USB и восстанавливаю его после запуска', () async {
    await ServerConnection.save(' 127.0.0.1 ', 50052);
    ServerConnection.host = '10.0.2.2';
    ServerConnection.port = 50051;
    await ServerConnection.load();
    expect(ServerConnection.host, '127.0.0.1');
    expect(ServerConnection.port, 50052);
    final service = AssetGrpcService();
    expect(service.host, '127.0.0.1');
    expect(service.port, 50052);
    service.close();
    final explicit = AssetGrpcService(host: 'localhost', port: 1234);
    expect(explicit.host, 'localhost');
    expect(explicit.port, 1234);
    explicit.close();
  });

  test('Отклоняю URL и неверные порты до записи файла', () async {
    for (final host in ['', 'http://localhost', 'localhost:50051', 'bad host', 'host/path']) {
      expect(ServerConnection.valid(host, 50051), isFalse);
    }
    for (final port in [0, -1, 65536]) {
      expect(ServerConnection.valid('localhost', port), isFalse);
    }
    await expectLater(ServerConnection.save('http://localhost', 50051), throwsFormatException);
    expect(ServerConnection.host, oldHost);
  });
}