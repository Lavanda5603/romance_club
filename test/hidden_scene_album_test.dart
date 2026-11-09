import 'dart:async'; // Импорт задержанного ответа
import 'package:flutter/material.dart'; // Импорт виджетов
import 'package:flutter_test/flutter_test.dart'; // Импорт проверок альбома
import 'package:romance_club/screens/hidden_scene_album_screen.dart'; // Импорт экрана

void main() {
  testWidgets('Показываю открытый разговор и блокирую закрытый', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HiddenSceneAlbumScreen(
      loadFlags: () async => {'seen_hidden_ep1_alya'})));
    await tester.pumpAndSettle();
    expect(find.text('Открыто 1 из 12'), findsOneWidget);
    final open = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Настоящие подруги'));
    final locked = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Тайна талисманов'));
    expect(open.onTap, isNotNull);
    expect(locked.onTap, isNull);
  });

  testWidgets('Поздний ответ после выхода не обращается к закрытому экрану', (tester) async {
    final response = Completer<Set<String>>();
    await tester.pumpWidget(MaterialApp(home: HiddenSceneAlbumScreen(loadFlags: () => response.future)));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    response.complete({});
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ошибка загрузки даёт повтор вместо ложных закрытых сцен', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HiddenSceneAlbumScreen(
      loadFlags: () async => throw StateError('Сеть недоступна'))));
    await tester.pumpAndSettle();
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Открыто 0 из 12'), findsNothing);
  });
}