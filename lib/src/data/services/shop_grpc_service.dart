import 'rpc_policy.dart';
import 'auth_options.dart'; // Метаданные с токеном
import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/shop_api.pbgrpc.dart'; // Импорт gRPC-клиента

// Сервис для работы с магазином через gRPC
class ShopGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final ShopApiClient _client; // gRPC-клиент

  // Конструктор класса ShopGrpcService
  ShopGrpcService({String host = '10.0.2.2', int port = 50051, RpcDeadline? deadlines}) {
    // Создаю канал связи
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    // Создаю gRPC-клиент
    _client = ShopApiClient(_channel, interceptors: [deadlines ?? RpcDeadline()]);
  }

  // Получить покупки
  Future<GetPurchasesResponse> getPurchases(String playerId) async {
    final request = GetPurchasesRequest(playerId: playerId);
    return await _client.getPurchases(request, options: await authOptions());
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
    return await _client.purchase(request, options: await authOptions());
  }

  // Получить баланс
  Future<Currency> getCurrency(String playerId) async {
    final request = GetCurrencyRequest(playerId: playerId);
    return await _client.getCurrency(request, options: await authOptions());
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.terminate();
  }
}