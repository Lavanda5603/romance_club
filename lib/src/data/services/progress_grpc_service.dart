import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/progress.pb.dart'; // Импорт Protobuf-модели Progress
import '../../../generated/progress_api.pbgrpc.dart'; // Импорт gRPC-клиента
import '../../../services/storage_service.dart'; // Импорт StorageService

// Таймаут
const _timeout = Duration(seconds: 10);

// Сервис для работы с прогрессом через gRPC
class ProgressGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final ProgressApiClient _client; // gRPC-клиент

  // Конструктор класса ProgressGrpcService
  ProgressGrpcService({String host = '10.0.2.2', int port = 50051}) {
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _client = ProgressApiClient(_channel);
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

  // Получить прогресс
  Future<Progress> getProgress(String playerId, int episodeId) async {
    final request = GetProgressRequest(
      playerId: playerId,
      episodeId: episodeId,
    );
    final options = await _getAuthOptions();
    return await _client.getProgress(request, options: options);
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
    final options = await _getAuthOptions();
    return await _client.saveProgress(request, options: options);
  }

  // Сбросить прогресс
  Future<ResetProgressResponse> resetProgress(String playerId) async {
    final request = ResetProgressRequest(playerId: playerId);
    final options = await _getAuthOptions();
    return await _client.resetProgress(request, options: options);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown();
  }
}