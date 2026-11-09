import 'package:flutter/material.dart'; // Импорт оформления
import 'package:flutter_test/flutter_test.dart'; // Импорт проверок
import 'package:romance_club/generated/choice.pb.dart'; // Импорт выбора
import 'package:romance_club/screens/choice_editor_screen.dart'; // Импорт редактора записи
import 'package:romance_club/screens/diary_screen.dart'; // Импорт дневника

void main() {
  testWidgets('Пустой дневник не придумывает решения', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DiaryScreen(loadEntries: () async => {})));
    await tester.pumpAndSettle();
    expect(find.text('Здесь появятся твои важные решения'), findsOneWidget);
  });
  testWidgets('Записи показываю по эпизодам', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DiaryScreen(loadEntries: () async => {'1. Начало': ['Я поддержала Алью']})));
    await tester.pumpAndSettle();
    expect(find.text('1. Начало'), findsOneWidget);
    expect(find.text('Я поддержала Алью'), findsOneWidget);
  });
  testWidgets('Редактор сохраняет запись действием с постоянной отметкой', (tester) async {
    Choice? saved;
    final original = Choice(title: 'Поддержать', text: 'Я рядом');
    await tester.pumpWidget(MaterialApp(home: ChoiceEditorScreen(choice: original, onSave: (value) => saved = value)));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('diary-entry-editor'));
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Я поддержала Алью');
    await tester.ensureVisible(find.text('сохранить'));
    await tester.tap(find.text('сохранить'));
    await tester.pumpAndSettle();
    expect(original.actions, isEmpty);
    expect(saved!.actions.single.title, 'Я поддержала Алью');
    expect(saved!.actions.single.flagName, startsWith('diary_'));
    expect(saved!.actions.single.flagValue, isTrue);
  });
}