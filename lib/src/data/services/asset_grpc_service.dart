import 'rpc_policy.dart';
import 'auth_options.dart'; // Метаданные с токеном
import '../../../services/storage_service.dart';
import 'package:grpc/grpc.dart'; // Импорт gRPC
import 'dart:typed_data'; // Импорт Uint8List
import '../../../generated/asset_api.pbgrpc.dart'; // Импорт gRPC-клиента

// Сервис для работы с gRPC (транспортный слой)
class AssetGrpcService {
  static const maxUploadBytes = 5 * 1024 * 1024;
  final String host;
  final int port;
  Future<String> cacheScope() async => '$host:$port:${await StorageService.loadToken()}';
  late final ClientChannel _channel; // Канал связи
  late final AssetApiClient _client; // gRPC-клиент

  // Конструктор
  AssetGrpcService({this.host = '10.0.2.2', this.port = 50051, RpcDeadline? deadlines}) {
    // Создаю канал связи с сервером
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(), // Без шифрования
      ),
    );

    // Создаю gRPC-клиент
    _client = AssetApiClient(_channel, interceptors: [deadlines ?? RpcDeadline()]);
  }

  // Получить ассеты по типу
  Future<GetAssetsResponse> getAssetPage(String type, {String episodeId = '', String cursor = '', int limit = 24}) async {
    // Создаю запрос
    final request = GetAssetsRequest(
      type: type,
      episodeId: episodeId,
      cursor: cursor,
      limit: limit,
    );

    // Вызываю метод сервера
    final response = await _client.getAssets(request, options: await authOptions());

    // Возвращаю список ассетов
    return response;
  }

  Future<Asset> getAsset({String id = '', String type = '', String name = '', String emotion = '', String episodeId = '', bool metadataOnly = false}) async {
    return _client.getAsset(GetAssetRequest(id: id, type: type, name: name, emotion: emotion, episodeId: episodeId, metadataOnly: metadataOnly), options: await authOptions());
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
    if (fileData.length > maxUploadBytes) {
      throw const GrpcError.invalidArgument('Файл больше 5 MiB (5 242 880 байт)');
    }
    // Создаю запрос
    final request = UploadAssetRequest(
      type: type,
      name: name,
      emotion: emotion,
      displayName: displayName,
      episodeId: episodeId,
      fileData: fileData,
      fileName: fileName,
    );

    // Вызываю метод сервера
    return await _client.uploadAsset(request, options: await authOptions());
  }

  // Удалить ассет по ID
  Future<DeleteAssetResponse> deleteAsset(String id) async {
    // Создаю запрос
    final request = DeleteAssetRequest(id: id);

    // Вызываю метод сервера
    return await _client.deleteAsset(request, options: await authOptions());
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.terminate(); // Закрываю канал
  }
}