import 'package:flutter/material.dart'; // Импорт тестового экрана
import 'package:flutter_test/flutter_test.dart'; // Импорт проверки времени и нажатий
import 'package:romance_club/widgets/consequence_notice.dart'; // Импорт реакции выбора

void main() {
  testWidgets('Новое сообщение заменяет прежнее и исчезает через четыре секунды', (tester) async {
    final notice = ConsequenceNotice();
    addTearDown(notice.hide);
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const Scaffold(body: Text('История'));
    })));
    notice.show(context, 'Алья это запомнит');
    await tester.pump();
    expect(find.text('Алья это запомнит'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    notice.show(context, 'Доверие Луки выросло');
    await tester.pump();
    expect(find.text('Алья это запомнит'), findsNothing);
    expect(find.text('Доверие Луки выросло'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(const ValueKey('consequence-notice')), findsNothing);
  });

  testWidgets('Плашка не блокирует нажатия и очищается при выходе', (tester) async {
    final notice = ConsequenceNotice();
    late BuildContext context;
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return Scaffold(body: Align(alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.only(top: 90),
          child: TextButton(onPressed: () => taps++, child: const Text('Далее')))));
    })));
    notice.show(context, 'Последствие');
    await tester.pump();
    await tester.tap(find.text('Далее'));
    expect(taps, 1);
    notice.hide();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}