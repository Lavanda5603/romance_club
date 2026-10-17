import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romance_club/generated/episode.pb.dart';
import 'package:romance_club/generated/scene.pb.dart';
import 'package:romance_club/screens/episode_editor_screen.dart';

void main() {
  testWidgets('Жду ответ сервера и не отправляю повторное сохранение', (tester) async {
    final pending = Completer<Episode>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(home: EpisodeEditorScreen(
      episode: Episode(id: 6, title: 'Эпизод', version: 1),
      onSave: (episode) { calls++; return pending.future; },
    )));
    await tester.enterText(find.byType(TextField), 'Новое название');
    await tester.tap(find.text('сохранить'));
    await tester.pump();
    expect(calls, 1);
    expect(find.text('Эпизод сохранён на сервере'), findsNothing);
    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'сохранить'));
    expect(button.onPressed, isNull);
    pending.complete(Episode(id: 6, title: 'Новое название', version: 1, scenes: [
      Scene(id: 331, sceneKey: 'scene:331', title: 'Сцена с сервера'),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('Сцена с сервера'), findsOneWidget);
    expect(find.text('Эпизод сохранён на сервере'), findsOneWidget);
  });

  testWidgets('При ошибке не показываю успешное сохранение', (tester) async {
    await tester.pumpWidget(MaterialApp(home: EpisodeEditorScreen(
      episode: Episode(id: 6, title: 'Эпизод', version: 1),
      onSave: (_) async => throw StateError('Нет связи'),
    )));
    await tester.tap(find.text('сохранить'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ошибка сохранения:'), findsOneWidget);
    expect(find.text('Эпизод сохранён на сервере'), findsNothing);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'сохранить')).onPressed, isNotNull);
  });
}