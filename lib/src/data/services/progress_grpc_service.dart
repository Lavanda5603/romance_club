import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/progress.pb.dart'; // Импорт Protobuf-модели Progress
import '../../../generated/progress_api.pbgrpc.dart'; // Импорт gRPC-клиента

// Сервис для работы с прогрессом через gRPC (транспортный слой)
class ProgressGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final ProgressApiClient _client; // gRPC-клиент

  // Конструктор класса ProgressGrpcService
  ProgressGrpcService({String host = '10.0.2.2', int port = 50051}) {
    // Создаю канал связи с сервером
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(), // Без шифрования
      ),
    );

    // Создаю gRPC-клиент
    _client = ProgressApiClient(_channel);
  }

  // Получить прогресс игрока по эпизоду
  Future<Progress> getProgress(int playerId, int episodeId) async {
    // Создаю запрос
    final request = GetProgressRequest(
      playerId: playerId,
      episodeId: episodeId,
    );

    // Вызываю метод сервера
    return await _client.getProgress(request);
  }

  // Сохранить прогресс
  Future<SaveProgressResponse> saveProgress({
    required int playerId,
    required int episodeId,
    required String sceneId,
    required Map<String, bool> flags,
    required Map<String, int> counters,
  }) async {
    // Создаю запрос
    final request = SaveProgressRequest(
      playerId: playerId,
      episodeId: episodeId,
      sceneId: sceneId,
      flags: flags.entries.toList(), // преобразую Map в список MapEntry
      counters: counters.entries.toList(),
    );

    // Вызываю метод сервера
    return await _client.saveProgress(request);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown(); // Закрываю канал
  }
}