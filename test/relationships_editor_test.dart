import 'dart:convert'; // Импорт настроек уровней
import 'package:flutter/material.dart'; // Импорт виджетов редактора
import 'package:flutter_test/flutter_test.dart'; // Импорт проверки сохранения
import 'package:romance_club/generated/episode_api.pb.dart'; // Импорт версии настроек
import 'package:romance_club/screens/relationships_screen.dart'; // Импорт редактора
import 'package:romance_club/src/data/services/episode_grpc_service.dart'; // Импорт подмены сервера

class _Service extends EpisodeGrpcService {
  RelationshipRules? saved;
  @override
  Future<RelationshipRules> getRelationshipRules() async => RelationshipRules(json: jsonEncode({
    for (final kind in ['romance', 'friendship']) kind: [
      {'points': 0, 'title': 'Знакомство'}, {'points': 3, 'title': 'Симпатия'}, {'points': 7, 'title': 'Близость'},
    ],
  }), revision: 4);
  @override
  Future<RelationshipRules> saveRelationshipRules(RelationshipRules rules) async {
    saved = rules.deepCopy();
    return rules.deepCopy()..revision = 5;
  }
}

void main() {
  testWidgets('Редактирую подпись в приложении и передаю версию серверу', (tester) async {
    final service = _Service();
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(home: RelationshipsScreen(edit: true, episodeService: service)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Первая встреча');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('сохранить'), 250,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('сохранить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('сохранить'));
    await tester.pumpAndSettle();
    expect(service.saved!.revision, 4);
    expect(jsonDecode(service.saved!.json)['romance'][0]['title'], 'Первая встреча');
    expect(find.text('Уровни сохранены для всех игроков'), findsOneWidget);
  });

  testWidgets('Отмена редактирования не сохраняет настройки', (tester) async {
    final service = _Service();
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(home: RelationshipsScreen(edit: true, episodeService: service)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Черновик');
    await tester.pumpWidget(const SizedBox());
    expect(service.saved, isNull);
  });
}