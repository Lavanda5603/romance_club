// Доменная модель покупки
class PurchaseModel {
  final String itemId; // ID предмета (episode:1, subscription, ...)
  final String itemType; // Тип (episode, subscription, currency)
  final String purchasedAt; // Дата покупки

  // Конструктор класса PurchaseModel
  const PurchaseModel({
    required this.itemId,
    required this.itemType,
    required this.purchasedAt,
  });
}

// Доменная модель валюты
class CurrencyModel {
  final String playerId; // ID игрока
  final int diamonds; // Баланс алмазов

  // Конструктор класса CurrencyModel
  const CurrencyModel({
    required this.playerId,
    required this.diamonds,
  });
}