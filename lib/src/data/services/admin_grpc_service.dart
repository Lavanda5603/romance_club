import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/admin_api.pbgrpc.dart'; // Импорт gRPC-клиента
import '../../../services/storage_service.dart'; // Импорт StorageService

// Сервис для админ-операций через gRPC
class AdminGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final AdminApiClient _client; // gRPC-клиент

  // Конструктор класса AdminGrpcService
  AdminGrpcService({String host = '10.0.2.2', int port = 50051}) {
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _client = AdminApiClient(_channel);
  }

  // Метаданные с токеном
  Future<CallOptions> _getAuthOptions() async {
    final token = await StorageService.loadToken();
    if (token.isEmpty) return CallOptions();
    return CallOptions(
      metadata: {'authorization': 'Bearer $token'},
    );
  }

  // Удалить ассет
  Future<AdminResponse> deleteAsset(String assetId) async {
    final request = AdminDeleteAssetRequest(assetId: assetId);
    final options = await _getAuthOptions();
    return await _client.deleteAsset(request, options: options);
  }

  // Удалить эпизод
  Future<AdminResponse> deleteEpisode(int episodeId) async {
    final request = AdminDeleteEpisodeRequest(episodeId: episodeId);
    final options = await _getAuthOptions();
    return await _client.deleteEpisode(request, options: options);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown();
  }
}