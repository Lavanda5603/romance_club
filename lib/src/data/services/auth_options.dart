import 'package:grpc/grpc.dart'; // Импорт для gRPC-запросов
import '../../../services/storage_service.dart'; // Импорт сервиса хранения
import '../../../services/session_store.dart'; // Импорт окончания сессии

// Добавляю текущий токен к запросу
Future<CallOptions> authOptions() async {
  final token = await StorageService.loadToken();
  if (token.isEmpty) {
    await SessionStore.shared.notifyMissing();
    throw GrpcError.unauthenticated('Требуется авторизация');
  }
  return CallOptions(metadata: {'authorization': 'Bearer $token'});
}
