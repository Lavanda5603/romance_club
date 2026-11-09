import 'dart:async'; // Импорт для Future и Completer
import 'package:flutter/material.dart'; // Импорт Material UI
import 'package:flutter_test/flutter_test.dart'; // Импорт для тестов Flutter
import 'package:romance_club/generated/episode.pb.dart'; // Импорт Protobuf-моделей эпизодов
import 'package:romance_club/generated/scene.pb.dart'; // Импорт Protobuf-моделей сцен
import 'package:romance_club/screens/episode_editor_screen.dart'; // Импорт экрана редактора эпизода
import 'package:romance_club/screens/scene_editor_screen.dart'; // Импорт выпадающего списка переходов

void main() {
  testWidgets('Новая сцена без ключа не дублирует конец эпизода', (tester) async {
    final scene = Scene(id: 1, title: 'Новая сцена');
    await tester.pumpWidget(MaterialApp(home: SceneEditorScreen(
      scene: scene, allScenes: [scene, scene], onSave: (_) {},
    )));
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButton<String>>(find.byKey(const ValueKey('scene-target')));
    final keys = dropdown.items!.map((item) => item.value).toList();
    expect(keys.where((key) => key == ''), hasLength(1));
    expect(keys.where((key) => key!.startsWith('draft:')), hasLength(1));
    expect(scene.sceneKey, isEmpty); // Исходную модель не меняю до сохранения
    expect(tester.takeException(), isNull);
  });

  testWidgets('Три новые сцены доступны для перехода до сохранения, затем ключи заменяются', (tester) async {
    final requests = <Episode>[];
    await tester.pumpWidget(MaterialApp(home: EpisodeEditorScreen(
      episode: Episode(id: 1, title: 'Эпизод'),
      onSave: (episode) async {
        requests.add(episode.deepCopy());
        final saved = episode.deepCopy();
        final keys = <String, String>{};
        for (var i = 0; i < saved.scenes.length; i++) {
          final scene = saved.scenes[i];
          if (scene.sceneKey.startsWith('draft:')) keys[scene.sceneKey] = 'scene:new_$i';
        }
        for (final scene in saved.scenes) {
          scene.sceneKey = keys[scene.sceneKey] ?? scene.sceneKey;
          scene.nextSceneKey = keys[scene.nextSceneKey] ?? scene.nextSceneKey;
        }
        return saved;
      },
    )));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('создать сцену'));
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();
    final finder = find.byKey(const ValueKey('scene-target'));
    final dropdown = tester.widget<DropdownButton<String>>(finder);
    final keys = dropdown.items!.map((item) => item.value!).toList();
    expect(keys, hasLength(4));
    expect(keys.toSet(), hasLength(4));
    expect(keys.where((key) => key.startsWith('draft:')), hasLength(3));
    final second = dropdown.items!.singleWhere((item) => (item.child as Text).data == 'сцена 2').value!;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('сцена 2').last);
    await tester.pumpAndSettle();
    final save = find.widgetWithText(ElevatedButton, 'сохранить');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('сохранить'));
    await tester.tap(find.text('сохранить'));
    await tester.pumpAndSettle();
    expect(requests.single.scenes[0].nextSceneKey, second);
    await tester.tap(find.text('сохранить'));
    await tester.pumpAndSettle();
    expect(requests[1].scenes.map((scene) => scene.sceneKey), ['scene:new_0', 'scene:new_1', 'scene:new_2']);
    expect(requests[1].scenes[0].nextSceneKey, 'scene:new_1');
    expect(tester.takeException(), isNull);
  });
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