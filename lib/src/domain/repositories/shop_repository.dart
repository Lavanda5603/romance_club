import '../models/purchase_model.dart'; // Импорт доменных моделей

// Контракт репозитория магазина
abstract class ShopRepository {
  // Получить покупки игрока
  Future<List<PurchaseModel>> getPurchases(String playerId);

  // Купить предмет
  Future<CurrencyModel?> purchase({
    required String playerId,
    required String itemId,
    required String itemType,
  });

  // Получить баланс игрока
  Future<CurrencyModel> getCurrency(String playerId);
}