import 'package:flutter/material.dart'; // Импорт Material UI
import 'package:flutter_test/flutter_test.dart'; // Импорт тестов Flutter
import 'package:romance_club/generated/episode.pb.dart'; // Импорт модели эпизода
import 'package:romance_club/generated/shop_api.pb.dart' as pb; // Импорт ответа магазина
import 'package:romance_club/screens/shop_screen.dart'; // Импорт магазина
import 'package:romance_club/src/data/repositories/shop_repository_remote.dart'; // Импорт репозитория магазина
import 'package:romance_club/src/data/services/shop_grpc_service.dart'; // Импорт сервиса магазина
import 'package:romance_club/src/data/services/episode_grpc_service.dart'; // Импорт сервиса эпизодов
import 'package:romance_club/src/domain/models/purchase_model.dart'; // Импорт модели покупки
import 'package:romance_club/src/domain/repositories/shop_repository.dart'; // Импорт интерфейса магазина

class _Episodes extends EpisodeGrpcService {
  int calls = 0;
  @override
  Future<List<Episode>> getAllEpisodes() async {
    calls++;
    return [Episode(id: 1, title: 'Первый эпизод')];
  }
}

class _Shop implements ShopRepository {
  final List<PurchaseModel> initial;
  final List<PurchaseModel> after;
  bool bought = false;
  _Shop(this.initial, {this.after = const []});
  @override
  Future<List<PurchaseModel>> getPurchases(String playerId) async => bought ? after : initial;
  @override
  Future<CurrencyModel> getCurrency(String playerId) async => CurrencyModel(playerId: playerId, diamonds: 500);
  @override
  Future<CurrencyModel?> purchase({required String playerId, required String itemId, required String itemType}) async {
    bought = true;
    return CurrencyModel(playerId: playerId, diamonds: 0);
  }
}

class _Service extends ShopGrpcService {
  @override
  Future<pb.GetPurchasesResponse> getPurchases(String playerId) async => pb.GetPurchasesResponse(purchases: [
    pb.Purchase(itemId: 'subscription', itemType: 'subscription', entitlementActive: true),
    pb.Purchase(itemId: 'subscription', itemType: 'unknown'),
  ]);
}

PurchaseModel subscription(bool active, {String type = 'subscription'}) => PurchaseModel(
  itemId: 'subscription', itemType: type, purchasedAt: '', entitlementActive: active);

void main() {
  test('Право из Protobuf передаю в доменную модель без догадок по ID', () async {
    final service = _Service();
    addTearDown(service.close);
    final purchases = await ShopRepositoryRemote(service).getPurchases('player:test');
    expect(purchases[0].isActiveSubscription, isTrue);
    expect(purchases[1].isActiveSubscription, isFalse);
    expect(subscription(true, type: 'unknown').isActiveSubscription, isFalse);
  });

  for (final record in [subscription(false), subscription(false, type: 'unknown'), subscription(true, type: 'episode'), subscription(true)]) {
    testWidgets('Магазин признаёт только подтверждённую подписку: ${record.itemType}/${record.entitlementActive}', (tester) async {
      final episodes = _Episodes();
      addTearDown(episodes.close);
      await tester.pumpWidget(MaterialApp(home: ShopScreen(repository: _Shop([record]),
        episodeService: episodes, loadPlayerId: () async => 'player:test')));
      await tester.pumpAndSettle();
      expect(episodes.calls, record.isActiveSubscription ? 1 : 0);
      expect(find.text('активна'), record.isActiveSubscription ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final confirmed in [false, true]) {
    testWidgets('После оплаты перечитываю подтверждение права: $confirmed', (tester) async {
      final episodes = _Episodes();
      addTearDown(episodes.close);
      final shop = _Shop([], after: [subscription(confirmed)]);
      await tester.pumpWidget(MaterialApp(home: ShopScreen(repository: shop,
        episodeService: episodes, loadPlayerId: () async => 'player:test')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('купить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('купить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Купить'));
      await tester.pumpAndSettle();
      expect(shop.bought, isTrue);
      expect(episodes.calls, confirmed ? 1 : 0);
      expect(find.text('активна'), confirmed ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}