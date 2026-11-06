import 'package:flutter/material.dart' hide Action; // Импорт Material UI
import 'package:flutter_test/flutter_test.dart'; // Импорт для тестов Flutter
import 'package:romance_club/generated/action.pb.dart'; // Импорт Protobuf-моделей действий
import 'package:romance_club/generated/choice.pb.dart'; // Импорт Protobuf-моделей выборов
import 'package:romance_club/generated/scene.pb.dart'; // Импорт Protobuf-моделей сцен
import 'package:romance_club/generated/episode.pb.dart'; // Импорт Protobuf-моделей эпизодов
import 'package:romance_club/screens/choice_editor_screen.dart'; // Импорт экрана редактора выбора
import 'package:romance_club/screens/scene_editor_screen.dart'; // Импорт экрана редактора сцены
import 'package:romance_club/screens/episode_editor_screen.dart'; // Импорт экрана редактора эпизода

void main() {
  Choice choice() => Choice(title: 'Выбор', text: 'Ответ', actions: [
    Action(type: 'changeFlag', title: 'Действие', flagName: 'secret', flagValue: true),
  ]);

  for (final saveChoice in [false, true]) {
    testWidgets('Изменённое действие передаю родителю только с сохранением выбора: $saveChoice', (tester) async {
      final original = choice();
      final before = original.writeToJson();
      Choice? saved;
      await tester.pumpWidget(MaterialApp(home: ChoiceEditorScreen(
        choice: original, onSave: (value) => saved = value,
      )));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byIcon(Icons.edit));
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Новое действие');
      await tester.ensureVisible(find.text('сохранить'));
      await tester.tap(find.text('сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('Новое действие'), findsOneWidget);
      expect(original.writeToJson(), before);
      if (saveChoice) {
        await tester.ensureVisible(find.text('сохранить'));
        await tester.tap(find.text('сохранить'));
        await tester.pumpAndSettle();
        expect(saved!.actions.single.title, 'Новое действие');
        expect(identical(saved!.actions.single, original.actions.single), isFalse);
      } else {
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(saved, isNull);
      }
      expect(original.writeToJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Сохранённый выбор остаётся в черновике до сохранения сцены', (tester) async {
    final original = Scene(sceneKey: 'scene:1', title: 'Сцена', choices: [choice()]);
    final before = original.writeToJson();
    var saves = 0;
    await tester.pumpWidget(MaterialApp(home: SceneEditorScreen(
      scene: original, onSave: (_) => saves++,
    )));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.edit).last);
    await tester.tap(find.byIcon(Icons.edit).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Новый выбор');
    await tester.ensureVisible(find.text('сохранить'));
    await tester.tap(find.text('сохранить'));
    await tester.pumpAndSettle();
    expect(original.writeToJson(), before);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(original.writeToJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('После ответа сохранения эпизода продолжаю менять отдельный черновик', (tester) async {
    final response = Episode(id: 1, title: 'Эпизод', scenes: [
      Scene(sceneKey: 'scene:1', title: 'Первая', choices: [choice()]),
    ]);
    final before = response.writeToJson();
    await tester.pumpWidget(MaterialApp(home: EpisodeEditorScreen(
      episode: response, onSave: (_) async => response,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('сохранить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('создать сцену'));
    await tester.pumpAndSettle();
    expect(response.writeToJson(), before);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(response.writeToJson(), before);
    expect(tester.takeException(), isNull);
  });
}
