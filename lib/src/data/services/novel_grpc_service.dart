import 'package:grpc/grpc.dart'; // Импорт связи с каталогом

import '../../../generated/novel_api.pbgrpc.dart'; // Импорт контракта новелл
import '../../../generated/episode.pb.dart'; // Импорт новой главы
import '../../../services/server_connection.dart'; // Импорт выбранного сервера
import 'auth_options.dart'; // Импорт токена
import 'rpc_policy.dart'; // Импорт ограниченного ожидания

class NovelGrpcService {
  late final ClientChannel _channel;
  late final NovelApiClient _client;
  NovelGrpcService() {
    _channel = ClientChannel(
      ServerConnection.host,
      port: ServerConnection.port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    _client = NovelApiClient(_channel, interceptors: [RpcDeadline()]);
  }
  Future<List<Novel>> listNovels() async => (await _client.listNovels(
    ListNovelsRequest(),
    options: await authOptions(),
  )).novels;
  Future<Novel> saveNovel(Novel item) async =>
      _client.saveNovel(item, options: await authOptions());
  Future<Episode> createEpisode(String id, String title) async =>
      _client.createNovelEpisode(
        CreateNovelEpisodeRequest(novelId: id, title: title),
        options: await authOptions(),
      );
  Future<NovelAudio> uploadAudio(
    String id,
    String kind,
    List<int> bytes,
  ) async => _client.uploadAudio(
    UploadNovelAudioRequest(novelId: id, kind: kind, data: bytes),
    options: await authOptions(),
  );
  Future<NovelAudio> getAudio(String novel, String id) async =>
      _client.getAudio(
        NovelAudioRequest(novelId: novel, id: id),
        options: await authOptions(),
      );
  Future<void> close() => _channel.terminate();
}