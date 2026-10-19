import 'dart:async'; // Импорт для Future и Completer
import 'dart:io'; // Импорт для работы с файлами
import 'package:flutter/material.dart'; // Импорт Material UI
import 'package:flutter/services.dart'; // Импорт платформенных каналов Flutter
import 'package:flutter_test/flutter_test.dart'; // Импорт для тестов Flutter
import 'package:romance_club/main.dart'; // Импорт приложения
import 'package:romance_club/screens/login_screen.dart'; // Импорт экрана входа
import 'package:romance_club/services/session_store.dart'; // Импорт целой сессии

void main() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory storage;
  setUp(() async {
    SessionStore.shared = SessionStore();
    storage = await Directory.systemTemp.createTemp('romance_app_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => storage.path);
    await SessionStore.shared.clear();
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await storage.delete(recursive: true);
  });

  Future<void> openLogin(WidgetTester tester) async {
    await tester.pumpWidget(const RomanceClubApp());
    // Чтение файла выполняется вне времени анимаций теста
    for (var attempt = 0; attempt < 200 && find.byType(LoginScreen).evaluate().isEmpty; attempt++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('Без сохранённого игрока открываю вход после стартового экрана', (tester) async {
    await openLogin(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Пустые поля входа показывают ошибку без запроса к серверу', (tester) async {
    await openLogin(tester);
    final login = find.widgetWithText(ElevatedButton, 'войти');
    expect(login, findsOneWidget);
    await tester.tap(login);
    await tester.pump();
    expect(find.text('Заполните все поля'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Закрытый стартовый экран не открывает вход после позднего чтения', (tester) async {
    final path = Completer<String>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => path.future);
    await tester.pumpWidget(const RomanceClubApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: Text('Другой экран')));
    path.complete(storage.path);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pumpAndSettle();
    expect(find.text('Другой экран'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
