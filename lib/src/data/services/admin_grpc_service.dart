import 'grpc_config.dart';
import 'rpc_policy.dart'; // Импорт сроков ожидания и ошибок сети
import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/admin_api.pbgrpc.dart'; // Импорт gRPC-клиента
import 'auth_options.dart'; // Импорт общей проверки токена

// Сервис для админ-операций через gRPC
class AdminGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final AdminApiClient _client; // gRPC-клиент

  // Конструктор
  AdminGrpcService({String host = GrpcConfig.host, int port = GrpcConfig.port, bool tls = GrpcConfig.tls, RpcDeadline? deadlines}) {
    _channel = GrpcConfig.createChannel(host: host, port: port, tls: tls);
    _client = AdminApiClient(_channel, interceptors: [deadlines ?? RpcDeadline()]);
  }

  // Удалить ассет
  Future<AdminResponse> deleteAsset(String assetId) async {
    final request = AdminDeleteAssetRequest(assetId: assetId);
    final options = await authOptions();
    return await _client.deleteAsset(request, options: options);
  }

  // Удалить эпизод
  Future<AdminResponse> deleteEpisode(int episodeId) async {
    final request = AdminDeleteEpisodeRequest(episodeId: episodeId);
    final options = await authOptions();
    return await _client.deleteEpisode(request, options: options);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.terminate();
  }
}