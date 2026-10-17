import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romance_club/generated/episode.pb.dart';
import 'package:romance_club/generated/scene.pb.dart';
import 'package:romance_club/screens/episode_editor_screen.dart';

void main() {
  testWidgets('После создания сцены повторно отправляю постоянный ключ из ответа сервера', (tester) async {
    final requests = <Episode>[];
    var nextKey = 0;
    final original = Episode(id: 6, title: 'Эпизод', version: 1, scenes: [
      Scene(sceneKey: 'scene:existing', title: 'Первая'),
    ]);
    await tester.pumpWidget(MaterialApp(home: EpisodeEditorScreen(
      episode: original,
      onSave: (episode) async {
        requests.add(episode.deepCopy());
        final saved = episode.deepCopy();
        for (final scene in saved.scenes) {
          if (scene.sceneKey.startsWith('draft:')) {
            scene.sceneKey = 'scene:s_test_${++nextKey}';
          }
        }
        return saved;
      },
    )));
    await tester.tap(find.text('создать сцену'));
    await tester.pump();
    await tester.tap(find.text('сохранить'));
    await tester.pumpAndSettle();
    expect(requests.single.scenes.last.sceneKey, startsWith('draft:'));

    await tester.enterText(find.byType(TextField), 'Изменённое название');
    await tester.tap(find.text('сохранить'));
    await tester.pumpAndSettle();
    expect(requests[1].title, 'Изменённое название');
    expect(requests[1].scenes.map((scene) => scene.sceneKey), ['scene:existing', 'scene:s_test_1']);

    // Добавляю ещё одну сцену в том же окне, прежний ключ сохраняется
    await tester.tap(find.text('создать сцену'));
    await tester.pump();
    await tester.tap(find.text('сохранить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('сохранить'));
    await tester.pumpAndSettle();
    expect(requests[3].scenes.map((scene) => scene.sceneKey),
      ['scene:existing', 'scene:s_test_1', 'scene:s_test_2']);
    expect(nextKey, 2);
    expect(original.scenes, hasLength(1));
    expect(tester.takeException(), isNull);
  });

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
