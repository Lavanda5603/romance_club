import 'dart:convert'; // Импорт JSON для проверки файла
import 'dart:io'; // Импорт временных файлов
import 'package:flutter_test/flutter_test.dart'; // Импорт тестов
import 'package:romance_club/services/session_store.dart'; // Импорт хранилища сессии

void main() {
  late Directory folder;
  late SessionStore store;
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('session_store_');
    store = SessionStore(directory: () async => folder);
  });
  tearDown(() async => folder.delete(recursive: true));

  test('После перезапуска читаю ID и токен из одной записи', () async {
    await store.save(const Session('player:a', 'token-a'));
    final reopened = SessionStore(directory: () async => folder);
    final session = await reopened.load();
    expect(session!.playerId, 'player:a');
    expect(session.token, 'token-a');
    expect(jsonDecode(await File('${folder.path}/session.json').readAsString()),
      {'player_id': 'player:a', 'token': 'token-a'});
    expect(await File('${folder.path}/session.json.tmp').exists(), isFalse);
  });

  test('Ошибка записи не оставляет ID от нового входа с прежним токеном', () async {
    await store.save(const Session('player:a', 'token-a'));
    final failing = SessionStore(directory: () async => folder, write: (file, data) async {
      await file.writeAsString(data.substring(0, 8));
      throw const FileSystemException('Нет места');
    });
    await expectLater(failing.save(const Session('player:b', 'token-b')), throwsA(isA<FileSystemException>()));
    final session = await store.load();
    expect(session!.playerId, 'player:a');
    expect(session.token, 'token-a');
    expect(await File('${folder.path}/session.json.tmp').exists(), isFalse);
    // После неудачной записи очередь остаётся рабочей
    await store.save(const Session('player:c', 'token-c'));
    expect((await store.load())!.playerId, 'player:c');
  });

  test('При ошибке выхода сессия остаётся полной, ошибка возвращается экрану', () async {
    await store.save(const Session('player:a', 'token-a'));
    final failing = SessionStore(directory: () async => folder,
      write: (_, _) async => throw const FileSystemException('Нет доступа'));
    await expectLater(failing.clear(), throwsA(isA<FileSystemException>()));
    expect((await store.load())!.token, 'token-a');
  });

  test('Пустая пара не заменяет существующую сессию', () async {
    await store.save(const Session('player:a', 'token-a'));
    await expectLater(store.save(const Session('player:b', '')), throwsArgumentError);
    await expectLater(store.save(const Session('', 'token-b')), throwsArgumentError);
    expect((await store.load())!.playerId, 'player:a');
  });

  test('Очередь сохраняет порядок входа и выхода', () async {
    final writes = [
      store.save(const Session('player:a', 'token-a')),
      store.save(const Session('player:b', 'token-b')),
      store.clear(),
    ];
    await Future.wait(writes);
    expect(await store.load(), isNull);
  });

  test('Полную старую пару переношу, выход не восстанавливает её обратно', () async {
    await File('${folder.path}/player_id.txt').writeAsString('player:a');
    await File('${folder.path}/token.txt').writeAsString('token-a');
    expect((await store.load())!.token, 'token-a');
    await store.clear();
    final reopened = SessionStore(directory: () async => folder);
    expect(await reopened.load(), isNull);
  });

  test('Один старый ID не является сессией', () async {
    await File('${folder.path}/player_id.txt').writeAsString('player:a');
    expect(await store.load(), isNull);
    await File('${folder.path}/token.txt').writeAsString('too-late');
    expect(await store.load(), isNull);
  });

  for (final data in ['{broken', '{"player_id":"player:a"}', '{"player_id":4,"token":"t"}']) {
    test('Повреждённую запись отклоняю: $data', () async {
      await File('${folder.path}/session.json').writeAsString(data);
      expect(await store.load(), isNull);
    });
  }

  test('Отказ старому токену не удаляет новую сессию', () async {
    await store.save(const Session('player:a', 'old'));
    await store.save(const Session('player:b', 'new'));
    final events = <String>[];
    final listener = store.expired.listen(events.add);
    await store.invalidate('old');
    expect((await store.load())!.token, 'new');
    expect(events, isEmpty);
    final expired = store.expired.first;
    await store.invalidate('new');
    expect(await expired, contains('Войдите снова'));
    expect(await store.load(), isNull);
    await listener.cancel();
  });

  test('Поздняя проверка запуска не очищает сессию нового аккаунта', () async {
    const old = Session('player:a', 'old');
    await store.save(old);
    await store.save(const Session('player:b', 'new'));
    expect(await store.clearIfCurrent(old), isFalse);
    expect((await store.load())!.playerId, 'player:b');
  });
}
