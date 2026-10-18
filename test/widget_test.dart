import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romance_club/main.dart';
import 'package:romance_club/screens/login_screen.dart';

void main() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('romance_app_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => storage.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await storage.delete(recursive: true);
  });

  Future<void> openLogin(WidgetTester tester) async {
    await tester.pumpWidget(const RomanceClubApp());
    // Чтение файла выполняется вне времени анимаций теста
    for (var attempt = 0; attempt < 50 && find.byType(LoginScreen).evaluate().isEmpty; attempt++) {
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
