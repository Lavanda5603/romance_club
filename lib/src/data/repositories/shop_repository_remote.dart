import '../../domain/models/purchase_model.dart'; // Импорт доменных моделей
import '../../domain/repositories/shop_repository.dart'; // Импорт контракта
import '../services/shop_grpc_service.dart'; // Импорт gRPC-сервиса

// Реализация репозитория магазина через gRPC
class ShopRepositoryRemote implements ShopRepository {
  final ShopGrpcService _service; // gRPC-сервис

  // Конструктор класса ShopRepositoryRemote
  ShopRepositoryRemote(this._service);

  // Получить покупки игрока
  @override
  Future<List<PurchaseModel>> getPurchases(String playerId) async {
    final response = await _service.getPurchases(playerId);

    return response.purchases.map((p) {
      return PurchaseModel(
        itemId: p.itemId,
        itemType: p.itemType,
        purchasedAt: p.purchasedAt,
      );
    }).toList();
  }

  // Купить предмет
  @override
  Future<CurrencyModel?> purchase({
    required String playerId,
    required String itemId,
    required String itemType,
  }) async {
    final response = await _service.purchase(
      playerId: playerId,
      itemId: itemId,
      itemType: itemType,
    );

    if (!response.success) {
      return null;
    }

    if (response.hasCurrency()) {
      return CurrencyModel(
        playerId: response.currency.playerId,
        diamonds: response.currency.diamonds,
      );
    }

    return null;
  }

  // Получить баланс игрока
  @override
  Future<CurrencyModel> getCurrency(String playerId) async {
    final currency = await _service.getCurrency(playerId);

    return CurrencyModel(
      playerId: currency.playerId,
      diamonds: currency.diamonds,
    );
  }
}