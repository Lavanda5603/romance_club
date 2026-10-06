import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/asset_api.pbgrpc.dart'; // Импорт gRPC-клиента

// Сервис для работы с gRPC (транспортный слой)
class AssetGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final AssetApiClient _client; // gRPC-клиент

  // Конструктор класса AssetGrpcService
  AssetGrpcService({String host = '10.0.2.2', int port = 50051}) {
    // Создаю канал связи с сервером
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(), // Без шифрования
      ),
    );

    // Создаю gRPC-клиент
    _client = AssetApiClient(_channel);
  }

  // Получить ассеты по типу
  Future<List<Asset>> getAssets(String type, {String episodeId = ''}) async {
    // Создаю запрос
    final request = GetAssetsRequest(
      type: type,
      episodeId: episodeId,
    );

    // Вызываю метод сервера
    final response = await _client.getAssets(request);

    // Возвращаю список ассетов
    return response.assets;
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown(); // Закрываю канал
  }
}