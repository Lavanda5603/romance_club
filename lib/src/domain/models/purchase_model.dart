// Доменная модель покупки
class PurchaseModel {
  final String itemId; // ID предмета (episode:1, subscription, ...)
  final String itemType; // Тип (episode, subscription, currency)
  final String purchasedAt; // Дата покупки
  final bool entitlementActive; // Право подтвердил сервер
  // Проверяю и подтверждение сервера, и сам товар
  bool get isActiveSubscription => entitlementActive && itemId == 'subscription' && itemType == 'subscription';

  // Конструктор
  const PurchaseModel({
    required this.itemId,
    required this.itemType,
    required this.purchasedAt,
    this.entitlementActive = false,
  });
}

// Доменная модель валюты
class CurrencyModel {
  final String playerId; // ID игрока
  final int diamonds; // Баланс алмазов

  // Конструктор
  const CurrencyModel({
    required this.playerId,
    required this.diamonds,
  });
}