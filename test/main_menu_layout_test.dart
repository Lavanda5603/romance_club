import 'dart:io'; // Импорт отдельной папки теста
import 'package:flutter/material.dart'; // Импорт размеров экрана
import 'package:flutter/services.dart'; // Импорт подмены хранилища
import 'package:flutter_test/flutter_test.dart'; // Импорт проверки главного меню
import 'package:romance_club/screens/main_menu_screen.dart'; // Импорт реального меню
import 'package:romance_club/services/session_store.dart'; // Импорт пустой тестовой сессии

void main() {
  testWidgets('На маленьком экране ссылки ниже двух кнопок, без значков и переполнения', (tester) async {
    final folder = (await tester.runAsync(() => Directory.systemTemp.createTemp('menu_layout_')))!;
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async => folder.path);
    SessionStore.shared=SessionStore();
    tester.view.physicalSize=const Size(800,480);
    tester.view.devicePixelRatio=1;
    addTearDown(() async {
      tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,null);
      await folder.delete(recursive:true);
    });
    await tester.pumpWidget(const MaterialApp(home:MainMenu()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds:30)));
    await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);
    expect(find.byIcon(Icons.auto_stories),findsNothing);
    expect(find.byIcon(Icons.book_outlined),findsNothing);
    final developer=find.textContaining('разработчик');
    final album=find.text('Альбом скрытых сцен');
    final diary=find.text('Мой дневник');
    expect(tester.getTopLeft(album).dy,greaterThan(tester.getBottomLeft(developer).dy));
    expect(tester.getTopLeft(diary).dy,greaterThan(tester.getBottomLeft(album).dy));
    await tester.ensureVisible(diary);
    await tester.pumpAndSettle();
    expect(diary.hitTestable(),findsOneWidget);
  });
}