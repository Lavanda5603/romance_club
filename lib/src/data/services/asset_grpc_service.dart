import 'package:grpc/grpc.dart'; // Импорт gRPC
import 'dart:typed_data'; // Импорт Uint8List
import '../../../generated/asset_api.pbgrpc.dart'; // Импорт gRPC-клиента

// Таймауты для разных операций
const _timeoutFast = Duration(seconds: 10);   // Быстрые
const _timeoutMedium = Duration(seconds: 30); // Средние (upload)
const _timeoutLong = Duration(seconds: 60);   // Длинные (оригинал)

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

    final response = await _client.getAssets(
      request,
      options: CallOptions(timeout: _timeoutFast), // таймаут 10 сек
    );
    return response.assets;
  }

  // Получить оригинал ассета по ID
  Future<Uint8List> getAssetFull(String id) async {
    final request = GetAssetFullRequest(id: id);
    final response = await _client.getAssetFull(
      request,
      options: CallOptions(timeout: _timeoutLong), // таймаут 60 сек
    );
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

    return await _client.uploadAsset(
      request,
      options: CallOptions(timeout: _timeoutMedium), // таймаут 30 сек
    );
  }

  // Удалить ассет по ID
  Future<DeleteAssetResponse> deleteAsset(String id) async {
    final request = DeleteAssetRequest(id: id);
    return await _client.deleteAsset(
      request,
      options: CallOptions(timeout: _timeoutFast), // таймаут 10 сек
    );
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown();
  }
}