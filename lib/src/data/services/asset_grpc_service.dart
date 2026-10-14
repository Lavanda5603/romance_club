import 'package:grpc/grpc.dart'; // Импорт gRPC
import 'dart:typed_data'; // Импорт Uint8List
import '../../../generated/asset_api.pbgrpc.dart'; // Импорт gRPC-клиента

// Сервис для работы с gRPC (транспортный слой)
class AssetGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final AssetApiClient _client; // gRPC-клиент

  // Конструктор класса AssetGrpcService
  AssetGrpcService({String host = '10.0.2.2', int port = 50051}) {
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );

    _client = AssetApiClient(_channel);
  }

  // Получить ассеты по типу (с превью, без оригиналов)
  Future<List<Asset>> getAssets(String type, {String episodeId = ''}) async {
    final request = GetAssetsRequest(
      type: type,
      episodeId: episodeId,
    );

    final response = await _client.getAssets(request);
    return response.assets;
  }

  // Получить оригинал ассета по ID
  Future<Uint8List> getAssetFull(String id) async {
    final request = GetAssetFullRequest(id: id);
    final response = await _client.getAssetFull(request);
    return Uint8List.fromList(response.fileData);
  }

  // Загрузить новый ассет
  Future<UploadAssetResponse> uploadAsset({
    required String type,
    required String name,
    required String emotion,
    required String displayName,
    required String episodeId,
    required Uint8List fileData,
    required String fileName,
  }) async {
    final request = UploadAssetRequest(
      type: type,
      name: name,
      emotion: emotion,
      displayName: displayName,
      episodeId: episodeId,
      fileData: fileData,
      fileName: fileName,
    );

    return await _client.uploadAsset(request);
  }

  // Удалить ассет по ID
  Future<DeleteAssetResponse> deleteAsset(String id) async {
    final request = DeleteAssetRequest(id: id);
    return await _client.deleteAsset(request);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown();
  }
}