import '../../../services/server_connection.dart'; // Импорт выбранного адреса сервера
import 'rpc_policy.dart'; // Импорт сроков ожидания и ошибок сети
import 'auth_options.dart'; // Метаданные с токеном
import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../../../generated/episode_api.pbgrpc.dart'; // Импорт gRPC-клиента

// Сервис для работы с gRPC (транспортный слой)
class EpisodeGrpcService {
  // Общие настройки читают игроки, изменять их разрешает только серверная роль админа.
  Future<RelationshipRules> getRelationshipRules() async =>
    _client.getRelationshipRules(GetAllEpisodesRequest(), options: await authOptions());

  Future<RelationshipRules> saveRelationshipRules(RelationshipRules rules) async =>
    _client.saveRelationshipRules(rules, options: await authOptions());
  late final ClientChannel _channel; // Канал связи
  late final EpisodeApiClient _client; // gRPC-клиент

  // Конструктор
  EpisodeGrpcService({String? host, int? port, RpcDeadline? deadlines}) {
    // Создаю канал связи с сервером
    _channel = ClientChannel(
      host ?? ServerConnection.host,
      port: port ?? ServerConnection.port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(), // Без шифрования
      ),
    );

    // Создаю gRPC-клиент
    _client = EpisodeApiClient(_channel, interceptors: [deadlines ?? RpcDeadline()]);
  }

  // Получить эпизод по ID
  Future<Episode> getEpisode(int id) async {
    // Создаю запрос
    final request = GetEpisodeRequest(id: id);

    // Вызываю метод сервера
    return await _client.getEpisode(request, options: await authOptions());
  }

  // Получить все эпизоды
  Future<List<Episode>> getAllEpisodes() async {
    // Создаю запрос
    final request = GetAllEpisodesRequest();

    // Вызываю метод сервера
    final response = await _client.getAllEpisodes(request, options: await authOptions());

    // Возвращаю список эпизодов
    return response.episodes;
  }

  // Сохранить эпизод
  Future<SaveEpisodeResponse> saveEpisode(Episode episode) async {
    // Создаю запрос
    final request = SaveEpisodeRequest(episode: episode);

    // Вызываю метод сервера
    return await _client.saveEpisode(request, options: await authOptions());
  }

  // Удалить эпизод
  Future<DeleteEpisodeResponse> deleteEpisode(int id) async {
    // Создаю запрос
    final request = DeleteEpisodeRequest(id: id);

    // Вызываю метод сервера
    return await _client.deleteEpisode(request, options: await authOptions());
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.terminate(); // Закрываю канал
  }
}