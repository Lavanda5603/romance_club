import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../../../generated/episode_api.pbgrpc.dart'; // Импорт gRPC-клиента

// Сервис для работы с gRPC (транспортный слой)
class EpisodeGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final EpisodeApiClient _client; // gRPC-клиент

  // Конструктор класса EpisodeGrpcService
  EpisodeGrpcService({String host = '10.0.2.2', int port = 50051}) {
    // Создаю канал связи с сервером
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(), // Без шифрования
      ),
    );

    // Создаю gRPC-клиент
    _client = EpisodeApiClient(_channel);
  }

  // Получить эпизод по ID
  Future<Episode> getEpisode(int id) async {
    // Создаю запрос
    final request = GetEpisodeRequest(id: id);

    // Вызываю метод сервера
    return await _client.getEpisode(request);
  }

  // Получить все эпизоды
  Future<List<Episode>> getAllEpisodes() async {
    // Создаю запрос
    final request = GetAllEpisodesRequest();

    // Вызываю метод сервера
    final response = await _client.getAllEpisodes(request);

    // Возвращаю список эпизодов
    return response.episodes;
  }

  // Сохранить эпизод
  Future<SaveEpisodeResponse> saveEpisode(Episode episode) async {
    // Создаю запрос
    final request = SaveEpisodeRequest(episode: episode);

    // Вызываю метод сервера
    return await _client.saveEpisode(request);
  }

  // Удалить эпизод
  Future<DeleteEpisodeResponse> deleteEpisode(int id) async {
    // Создаю запрос
    final request = DeleteEpisodeRequest(id: id);

    // Вызываю метод сервера
    return await _client.deleteEpisode(request);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown(); // Закрываю канал
  }
}