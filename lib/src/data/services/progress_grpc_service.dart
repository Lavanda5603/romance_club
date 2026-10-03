import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/progress.pb.dart'; // Импорт Protobuf-модели Progress
import '../../../generated/progress_api.pbgrpc.dart'; // Импорт gRPC-клиента

// Сервис для работы с прогрессом через gRPC
class ProgressGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final ProgressApiClient _client; // gRPC-клиент

  // Конструктор класса ProgressGrpcService
  ProgressGrpcService({String host = '10.0.2.2', int port = 50051}) {
    // Создаю канал связи
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    // Создаю gRPC-клиент
    _client = ProgressApiClient(_channel);
  }

  // Получить прогресс
  Future<Progress> getProgress(String playerId, int episodeId) async {
    final request = GetProgressRequest(
      playerId: playerId,
      episodeId: episodeId,
    );
    return await _client.getProgress(request);
  }

  // Сохранить прогресс
  Future<SaveProgressResponse> saveProgress({
    required String playerId,
    required int episodeId,
    required String sceneId,
    required Map<String, bool> flags,
    required Map<String, int> counters,
  }) async {
    final request = SaveProgressRequest(
      playerId: playerId,
      episodeId: episodeId,
      sceneId: sceneId,
      flags: flags.entries.toList(),
      counters: counters.entries.toList(),
    );
    return await _client.saveProgress(request);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown();
  }
}