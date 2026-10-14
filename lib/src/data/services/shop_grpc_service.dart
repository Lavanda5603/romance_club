import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/shop_api.pbgrpc.dart'; // Импорт gRPC-клиента
import '../../../services/storage_service.dart'; // Импорт StorageService

// Таймаут
const _timeout = Duration(seconds: 15);

// Сервис для работы с магазином через gRPC
class ShopGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final ShopApiClient _client; // gRPC-клиент

  // Конструктор класса ShopGrpcService
  ShopGrpcService({String host = '10.0.2.2', int port = 50051}) {
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _client = ShopApiClient(_channel);
  }

  // Метаданные с токеном
  Future<CallOptions> _getAuthOptions() async {
    final token = await StorageService.loadToken();
    if (token.isEmpty) return CallOptions(timeout: _timeout);
    return CallOptions(
      metadata: {'authorization': 'Bearer $token'},
      timeout: _timeout,
    );
  }

  // Получить покупки
  Future<GetPurchasesResponse> getPurchases(String playerId) async {
    final request = GetPurchasesRequest(playerId: playerId);
    final options = await _getAuthOptions();
    return await _client.getPurchases(request, options: options);
  }

  // Купить
  Future<PurchaseResponse> purchase({
    required String playerId,
    required String itemId,
    required String itemType,
  }) async {
    final request = PurchaseRequest(
      playerId: playerId,
      itemId: itemId,
      itemType: itemType,
    );
    final options = await _getAuthOptions();
    return await _client.purchase(request, options: options);
  }

  // Получить баланс
  Future<Currency> getCurrency(String playerId) async {
    final request = GetCurrencyRequest(playerId: playerId);
    final options = await _getAuthOptions();
    return await _client.getCurrency(request, options: options);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown();
  }
}