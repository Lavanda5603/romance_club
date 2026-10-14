import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/achievement_api.pbgrpc.dart'; // Импорт gRPC-клиента
import '../../../services/storage_service.dart'; // Импорт StorageService

// Таймаут
const _timeout = Duration(seconds: 10);

// Сервис для работы с достижениями через gRPC
class AchievementGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final AchievementApiClient _client; // gRPC-клиент

  // Конструктор класса AchievementGrpcService
  AchievementGrpcService({String host = '10.0.2.2', int port = 50051}) {
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _client = AchievementApiClient(_channel);
  }

  // Метаданные с токеном
  Future<CallOptions> _getAuthOptions() async {
    final token = await StorageService.loadToken();
    if (token.isEmpty) return CallOptions(timeout: _timeout);
    return CallOptions(
      metadata: {'authorization': 'Bearer $token'},
      timeout: _timeout,
    );
  }

  // Получить достижения игрока
  Future<GetAchievementsResponse> getAchievements(String playerId) async {
    final request = GetAchievementsRequest(playerId: playerId);
    final options = await _getAuthOptions();
    return await _client.getAchievements(request, options: options);
  }

  // Открыть достижение
  Future<UnlockAchievementResponse> unlockAchievement({
    required String playerId,
    required String name,
  }) async {
    final request = UnlockAchievementRequest(
      playerId: playerId,
      name: name,
    );
    final options = await _getAuthOptions();
    return await _client.unlockAchievement(request, options: options);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown();
  }
}