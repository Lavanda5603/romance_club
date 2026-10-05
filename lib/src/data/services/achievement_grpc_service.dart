import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/achievement_api.pbgrpc.dart'; // Импорт gRPC-клиента

// Сервис для работы с достижениями через gRPC
class AchievementGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final AchievementApiClient _client; // gRPC-клиент

  // Конструктор класса AchievementGrpcService
  AchievementGrpcService({String host = '10.0.2.2', int port = 50051}) {
    // Создаю канал связи
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    // Создаю gRPC-клиент
    _client = AchievementApiClient(_channel);
  }

  // Получить достижения игрока
  Future<GetAchievementsResponse> getAchievements(String playerId) async {
    final request = GetAchievementsRequest(playerId: playerId);
    return await _client.getAchievements(request);
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
    return await _client.unlockAchievement(request);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown();
  }
}