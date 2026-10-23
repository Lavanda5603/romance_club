import 'rpc_policy.dart'; // Импорт сроков ожидания и ошибок сети
import 'auth_options.dart'; // Метаданные с токеном
import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/progress.pb.dart'; // Импорт Protobuf-модели Progress
import '../../../generated/progress_api.pbgrpc.dart'; // Импорт gRPC-клиента

// Сервис для работы с прогрессом через gRPC
class ProgressGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final ProgressApiClient _client; // gRPC-клиент

  // Конструктор
  ProgressGrpcService({String host = '10.0.2.2', int port = 50051, RpcDeadline? deadlines}) {
    // Создаю канал связи
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    // Создаю gRPC-клиент
    _client = ProgressApiClient(_channel, interceptors: [deadlines ?? RpcDeadline()]);
  }

  // Получить прогресс
  Future<GetProgressSummaryResponse> getProgressSummary(String playerId) async {
    return _client.getProgressSummary(GetProgressSummaryRequest(playerId: playerId), options: await authOptions());
  }

  // Получить прогресс
  Future<Progress> getProgress(String playerId, int episodeId) async {
    final request = GetProgressRequest(
      playerId: playerId,
      episodeId: episodeId,
    );
    return await _client.getProgress(request, options: await authOptions());
  }

  // Сохранить прогресс
  Future<SaveProgressResponse> saveProgress({
    required String playerId,
    required int episodeId,
    required String sceneId,
    required int expectedRevision,
    int expectedGeneration = 0,
    bool completed = false,
    String ending = '',
    required Map<String, bool> flags,
    required Map<String, int> counters,
  }) async {
    final request = SaveProgressRequest(
      playerId: playerId,
      episodeId: episodeId,
      sceneId: sceneId,
      expectedRevision: expectedRevision,
      expectedGeneration: expectedGeneration,
      completed: completed,
      ending: ending,
      flags: flags.entries.toList(),
      counters: counters.entries.toList(),
    );
    return await _client.saveProgress(request, options: await authOptions());
  }

  // Сбросить прогресс
  Future<ResetProgressResponse> resetProgress(String playerId) async {
    final request = ResetProgressRequest(playerId: playerId);
    return await _client.resetProgress(request, options: await authOptions());
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.terminate();
  }
}