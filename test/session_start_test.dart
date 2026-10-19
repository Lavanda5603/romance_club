import 'dart:io'; // Импорт временной папки
import 'package:flutter/material.dart'; // Импорт пустого экрана для закрытия приложения
import 'package:flutter/services.dart'; // Импорт платформенного канала
import 'package:flutter_test/flutter_test.dart'; // Импорт тестов Flutter
import 'package:grpc/grpc.dart'; // Импорт ошибок сервера
import 'package:romance_club/main.dart'; // Импорт запуска приложения
import 'package:romance_club/screens/login_screen.dart'; // Импорт входа
import 'package:romance_club/screens/main_menu_screen.dart'; // Импорт главного меню
import 'package:romance_club/services/session_store.dart'; // Импорт согласованной сессии

void main() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory folder;
  setUp(() async {
    SessionStore.shared = SessionStore();
    folder = await Directory.systemTemp.createTemp('session_start_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => folder.path);
    await SessionStore.shared.clear();
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await folder.delete(recursive: true);
  });

  Future<void> waitFor(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 200 && target.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(target, findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  testWidgets('Один ID без токена не открывает меню и не проверяется как сессия', (tester) async {
    await tester.runAsync(() async {
      await File('${folder.path}/session.json').delete();
      await File('${folder.path}/player_id.txt').writeAsString('player:a');
    });
    var checked = 0;
    await tester.pumpWidget(RomanceClubApp(validateSession: (_) async { checked++; return true; }));
    await waitFor(tester, find.byType(LoginScreen));
    expect(checked, 0);
    expect(find.byType(MainMenu), findsNothing);
  });

  testWidgets('Отказ сервера очищает сессию и открывает повторный вход', (tester) async {
    await tester.runAsync(() => SessionStore.shared.save(const Session('player:a', 'expired')));
    await tester.pumpWidget(RomanceClubApp(validateSession: (session) async {
      expect(session.playerId, 'player:a');
      throw const GrpcError.unauthenticated('Подпись или срок неверны');
    }));
    await waitFor(tester, find.byType(LoginScreen));
    expect(await tester.runAsync(() => SessionStore.shared.load()), isNull);
    expect(find.byType(MainMenu), findsNothing);
  });

  testWidgets('При недоступном сервере сохраняю сессию и предлагаю повтор', (tester) async {
    await tester.runAsync(() => SessionStore.shared.save(const Session('player:a', 'token-a')));
    var attempts = 0;
    await tester.pumpWidget(RomanceClubApp(validateSession: (_) async {
      if (++attempts == 1) throw const GrpcError.unavailable();
      return false;
    }));
    await waitFor(tester, find.text('Повторить'));
    expect(find.byType(MainMenu), findsNothing);
    expect((await tester.runAsync(() => SessionStore.shared.load()))!.token, 'token-a');
    await tester.tap(find.text('Повторить'));
    await waitFor(tester, find.byType(LoginScreen));
    expect(attempts, 2);
  });

  testWidgets('Проверенная сессия открывает меню, её окончание возвращает на вход', (tester) async {
    await tester.runAsync(() => SessionStore.shared.save(const Session('player:a', 'valid')));
    var checked = false;
    await tester.pumpWidget(RomanceClubApp(
      buildMenu: () => const Scaffold(body: Text('Проверенное меню')),
      validateSession: (_) async { checked = true; return true; }));
    await waitFor(tester, find.text('Проверенное меню'));
    expect(checked, isTrue);
    await tester.runAsync(() => SessionStore.shared.invalidate('valid'));
    await waitFor(tester, find.byType(LoginScreen));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(MainMenu), findsNothing);
    expect(await tester.runAsync(() => SessionStore.shared.load()), isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  });

  testWidgets('Ошибка чтения сессии не даёт пройти в меню', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,
      (_) async => throw PlatformException(code: 'storage', message: 'Нет доступа'));
    await tester.pumpWidget(const RomanceClubApp());
    await waitFor(tester, find.text('Повторить'));
    expect(find.byType(MainMenu), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
