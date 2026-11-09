import 'package:flutter/material.dart' hide Action; // Импорт редактора без конфликта имён
import 'package:flutter_test/flutter_test.dart'; // Импорт проверок цены
import 'package:romance_club/generated/choice.pb.dart'; // Импорт платного выбора
import 'package:romance_club/generated/action.pb.dart'; // Импорт перехода
import 'package:romance_club/screens/choice_editor_screen.dart'; // Импорт управления ценой в приложении

void main() {
  for (final price in [40,14]) {
    testWidgets('Цена из редактора: $price, ключ покупки остаётся постоянным', (tester) async {
      final original = Choice(text:'Остаться',title:'Разговор',diamondPrice:30,premiumKey:'choice:mask_rooftop',
        actions:[Action(type:'nextScene',sceneKey:'scene:hidden_ep4_mask')]);
      Choice? saved;
      await tester.pumpWidget(MaterialApp(home:ChoiceEditorScreen(choice:original,onSave:(value)=>saved=value)));
      await tester.pumpAndSettle();
      final field=find.byKey(const ValueKey('choice-diamond-price'));
      await tester.ensureVisible(field);
      await tester.enterText(field,'$price');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('сохранить'));
      await tester.tap(find.text('сохранить'));
      await tester.pumpAndSettle();
      expect(original.diamondPrice,30);
      if (price==40) {
        expect(saved!.diamondPrice,40);
        expect(saved!.premiumKey,'choice:mask_rooftop');
      } else {
        expect(saved,isNull);
        expect(find.text('Цена: 0 бесплатно или от 15 до 50 алмазов'),findsOneWidget);
      }
    });
  }
}