import 'dart:async'; // Импорт задержанного ответа

import 'package:flutter/material.dart'; // Импорт карточек галереи
import 'package:flutter_test/flutter_test.dart'; // Импорт проверок
import 'package:romance_club/screens/ending_gallery_screen.dart'; // Импорт экрана коллекции
import 'package:romance_club/src/core/ending_gallery.dart'; // Импорт известных финалов

void main() {
  test('Считаю только семь известных финалов, без повторов', () {
    expect(knownGalleryEndings(['Лука', 'Лука', 'Секрет', 'Команда вместе']), {
      'Лука',
      'Команда вместе',
    });
    expect(endingGalleryCards.length, 7);
  });

  testWidgets(
    'Открытые карточки доступны, закрытые показывают подсказку без картинки',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EndingGalleryScreen(loadEndings: () async => {'МариАдриан'}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Открыто 1 из 7'), findsOneWidget);
      final opened = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Маринетт и Адриан'),
      );
      final locked = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Маринетт и Супер-Кот'),
      );
      expect(opened.onTap, isNotNull);
      expect(locked.onTap, isNull);
      await tester.tap(find.text('Маринетт и Адриан'));
      await tester.pumpAndSettle();
      expect(find.text('Маринетт и Адриан'), findsOneWidget);
    },
  );

  testWidgets('Ошибка сервера не выдаётся за пустую коллекцию', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EndingGalleryScreen(
          loadEndings: () async => throw StateError('Нет сети'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Открыто 0 из 7'), findsNothing);
  });

  testWidgets('Выход до ответа не вызывает setState после dispose', (
    tester,
  ) async {
    final response = Completer<Set<String>>();
    await tester.pumpWidget(
      MaterialApp(
        home: EndingGalleryScreen(loadEndings: () => response.future),
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    response.complete({'Лука'});
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}