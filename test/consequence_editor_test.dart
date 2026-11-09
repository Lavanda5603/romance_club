import 'package:flutter/material.dart'; // Импорт экрана редактора
import 'package:flutter_test/flutter_test.dart'; // Импорт проверок сохранения
import 'package:romance_club/generated/choice.pb.dart'; // Импорт выбора
import 'package:romance_club/generated/action.pb.dart' as story; // Импорт действия без конфликтов Material
import 'package:romance_club/screens/choice_editor_screen.dart'; // Импорт поля последствия

void main() {
  for (final text in ['Алья это запомнит', '']) {
    testWidgets('Редактирую сообщение через поле выбора: "$text"', (tester) async {
      final original = Choice(title: 'Выбор', text: 'Поддержать', actions: [
        story.Action(type: 'notification', title: 'Старый текст'),
        story.Action(type: 'changeCounter', counterName: 'friendship', counterValue: 2),
      ]);
      Choice? saved;
      await tester.pumpWidget(MaterialApp(home: ChoiceEditorScreen(choice: original, onSave: (value) => saved = value)));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('consequence-editor'));
      await tester.ensureVisible(field);
      await tester.enterText(field, text);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('сохранить'));
      await tester.tap(find.text('сохранить'));
      await tester.pumpAndSettle();
      expect(original.actions.first.title, 'Старый текст');
      final notices = saved!.actions.where((a) => a.type == 'notification').toList();
      expect(notices.length, text.isEmpty ? 0 : 1);
      if (text.isNotEmpty) expect(notices.single.title, text);
      expect(saved!.actions.where((a) => a.type == 'changeCounter').single.counterValue, 2);
    });
  }
}