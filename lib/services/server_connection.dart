import 'dart:convert'; // Импорт сохранения адреса сервера
import 'dart:io'; // Импорт файла настроек
import 'package:path_provider/path_provider.dart'; // Импорт папки приложения

// Храню один адрес для всех сервисов приложения.
class ServerConnection {
  static String host = const String.fromEnvironment('GRPC_HOST', defaultValue: '10.0.2.2');
  static int port = const int.fromEnvironment('GRPC_PORT', defaultValue: 50051);

  static bool valid(String host, int? port) => host.trim().isNotEmpty &&
    !RegExp(r'[\s/:?#]').hasMatch(host.trim()) && port != null && port > 0 && port <= 65535;

  static Future<File> _file() async => File('${(await getApplicationDocumentsDirectory()).path}/server_connection.json');

  // Восстанавливаю адрес до создания первого канала связи.
  static Future<void> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final savedHost = data['host'];
      final savedPort = data['port'];
      if (savedHost is String && savedPort is int && valid(savedHost, savedPort)) {
        host = savedHost.trim();
        port = savedPort;
      }
    } catch (_) {
      // При повреждённом файле оставляю исходный адрес доступным для исправления.
    }
  }

  static Future<void> save(String newHost, int newPort) async {
    if (!valid(newHost, newPort)) throw const FormatException('Проверь адрес и порт сервера');
    final file = await _file();
    await file.writeAsString(jsonEncode({'host': newHost.trim(), 'port': newPort}), flush: true);
    host = newHost.trim();
    port = newPort;
  }
}