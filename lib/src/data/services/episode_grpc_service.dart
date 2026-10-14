import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../../../generated/episode_api.pbgrpc.dart'; // Импорт gRPC-клиента
import '../../../services/storage_service.dart'; // Импорт StorageService

// Таймауты
const _timeoutFast = Duration(seconds: 15);   // Метаданные
const _timeoutMedium = Duration(seconds: 30); // Эпизод целиком
const _timeoutLong = Duration(seconds: 60);   // Сохранение

// Сервис для работы с gRPC (транспортный слой)
class EpisodeGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final EpisodeApiClient _client; // gRPC-клиент

  // Конструктор класса EpisodeGrpcService
  EpisodeGrpcService({String host = '10.0.2.2', int port = 50051}) {
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _client = EpisodeApiClient(_channel);
  }

  // Метаданные с токеном
  Future<CallOptions> _getAuthOptions({Duration? timeout}) async {
    final token = await StorageService.loadToken();
    final t = timeout ?? _timeoutFast;
    if (token.isEmpty) return CallOptions(timeout: t);
    return CallOptions(
      metadata: {'authorization': 'Bearer $token'},
      timeout: t,
    );
  }

  // Получить эпизод по ID
  Future<Episode> getEpisode(int id) async {
    final request = GetEpisodeRequest(id: id);
    final options = await _getAuthOptions(timeout: _timeoutMedium); // 30 сек
    return await _client.getEpisode(request, options: options);
  }

  // Получить все эпизоды
  Future<List<Episode>> getAllEpisodes() async {
    final request = GetAllEpisodesRequest();
    final options = await _getAuthOptions(); // 15 сек
    final response = await _client.getAllEpisodes(request, options: options);
    return response.episodes;
  }

  // Сохранить эпизод
  Future<SaveEpisodeResponse> saveEpisode(Episode episode) async {
    final request = SaveEpisodeRequest(episode: episode);
    final options = await _getAuthOptions(timeout: _timeoutLong); // 60 сек
    return await _client.saveEpisode(request, options: options);
  }

  // Удалить эпизод
  Future<DeleteEpisodeResponse> deleteEpisode(int id) async {
    final request = DeleteEpisodeRequest(id: id);
    final options = await _getAuthOptions(timeout: _timeoutMedium); // 30 сек
    return await _client.deleteEpisode(request, options: options);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown();
  }
}