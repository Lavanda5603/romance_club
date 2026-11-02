import 'package:romance_club/services/active_novel.dart'; // Импорт выбранной истории
import 'package:romance_club/screens/ending_gallery_screen.dart'; // Импорт личной галереи истории
import 'dart:convert'; // Импорт настроек истории

import 'package:flutter/material.dart'; // Импорт формы
import 'package:flutter_test/flutter_test.dart'; // Импорт проверок
import 'package:romance_club/generated/novel_api.pb.dart'; // Импорт модели
import 'package:romance_club/screens/novel_editor_screen.dart'; // Импорт редактора

void main() {
  testWidgets('В галерее новой новеллы нет финалов Леди Баг', (tester) async {
    final active = ActiveNovel.shared;
    final previous = active.current;
    final config = active.config;
    try {
      active.current = Novel(id: 'novel:other', title: 'Своя история');
      active.config = {'endings': [{'key': 'Свой финал', 'title': 'Свой финал', 'hint': 'Сделай выбор'}]};
      await tester.pumpWidget(MaterialApp(home: EndingGalleryScreen(loadEndings: () async => {'Свой финал', 'МариКот'})));
      await tester.pumpAndSettle();
      expect(find.text('Открыто 1 из 1'), findsOneWidget);
      expect(find.text('Маринетт и Супер-Кот'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    } finally { active.current = previous; active.config = config; }
  });

  testWidgets(
    'Новая история позволяет менять название и предлагает сохранить перед звуками',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: NovelEditorScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Сначала сохрани новеллу'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Своя история');
      expect(find.text('Своя история'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Загрузить музыку MP3'),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Редактор держит изменения отдельно от модели каталога', (
    tester,
  ) async {
    final original = Novel(
      id: 'novel:test',
      title: 'До изменения',
      configJson: jsonEncode({
        'relationships': [],
        'endings': [],
        'hidden': [],
        'final_episode_id': 0,
        'legacy_rules': false,
      }),
    );
    await tester.pumpWidget(
      MaterialApp(home: NovelEditorScreen(novel: original)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Новое название');
    await tester.pumpWidget(const SizedBox());
    expect(original.title, 'До изменения');
    expect(jsonDecode(original.configJson)['relationships'], isEmpty);
    expect(tester.takeException(), isNull);
  });
}