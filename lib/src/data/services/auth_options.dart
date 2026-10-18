import 'package:grpc/grpc.dart'; // Импорт для gRPC-запросов
import '../../../services/storage_service.dart'; // Импорт сервиса хранения

// Добавляю текущий токен к запросу
Future<CallOptions> authOptions() async {
  final token = await StorageService.loadToken();
  if (token.isEmpty) {
    throw GrpcError.unauthenticated('Требуется авторизация');
  }
  return CallOptions(metadata: {'authorization': 'Bearer $token'});
}