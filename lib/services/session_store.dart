import 'dart:async'; // Импорт очереди операций и событий
import 'dart:convert'; // Импорт JSON
import 'dart:io'; // Импорт файлов
import 'package:path_provider/path_provider.dart'; // Импорт папки приложения

// ID и токен всегда сохраняю вместе
class Session {
  final String playerId;
  final String token;
  const Session(this.playerId, this.token);
}

class SessionStore {
  static SessionStore shared = SessionStore();
  final Future<Directory> Function() directory;
  final Future<void> Function(File, String)? write;
  final _expired = StreamController<String>.broadcast();
  Stream<String> get expired => _expired.stream;
  Future<void> _queue = Future.value();

  SessionStore({Future<Directory> Function()? directory, this.write})
      : directory = directory ?? getApplicationDocumentsDirectory;

  // Чтение, вход и выход не обгоняют друг друга
  Future<T> _serial<T>(Future<T> Function() action) async {
    final previous = _queue;
    final release = Completer<void>.sync();
    _queue = release.future;
    await previous;
    try {
      return await action();
    } finally {
      release.complete();
    }
  }

  Future<void> _put(Directory folder, Session? session) async {
    final data = jsonEncode(session == null ? null : {
      'player_id': session.playerId, 'token': session.token,
    });
    final pending = File('${folder.path}/session.json.tmp');
    try {
      if (write != null) {
        await write!(pending, data);
      } else {
        await pending.writeAsString(data, flush: true);
      }
      // До переименования прежняя сессия остаётся целой
      await pending.rename('${folder.path}/session.json');
    } finally {
      if (await pending.exists()) await pending.delete();
    }
  }

  Future<Session?> _read(Directory folder) async {
    final file = File('${folder.path}/session.json');
    if (await file.exists()) {
      try {
        final data = jsonDecode(await file.readAsString());
        if (data == null) return null;
        if (data is Map && data['player_id'] is String && data['token'] is String &&
            (data['player_id'] as String).trim().isNotEmpty && (data['token'] as String).trim().isNotEmpty) {
          return Session(data['player_id'], data['token']);
        }
      } on FormatException {
        // Повреждённую запись не считаю входом
      }
      await _put(folder, null);
      return null;
    }
    // Переношу только полную пару из прежнего хранилища
    final id = File('${folder.path}/player_id.txt');
    final token = File('${folder.path}/token.txt');
    Session? session;
    if (await id.exists() && await token.exists()) {
      final playerId = await id.readAsString();
      final jwt = await token.readAsString();
      if (playerId.trim().isNotEmpty && jwt.trim().isNotEmpty) session = Session(playerId, jwt);
    }
    await _put(folder, session);
    return session;
  }

  Future<Session?> load() => _serial(() async => _read(await directory()));

  Future<void> save(Session session) => _serial(() async {
    if (session.playerId.trim().isEmpty || session.token.trim().isEmpty) {
      throw ArgumentError('Сервер не вернул полную сессию');
    }
    await _put(await directory(), session);
  });

  // Записываю выход одним действием, чтобы старые файлы не вернули сессию
  Future<void> clear() => _serial(() async => _put(await directory(), null));

  Future<bool> clearIfCurrent(Session session) => _serial(() async {
    final folder = await directory();
    final current = await _read(folder);
    if (current?.token != session.token || current?.playerId != session.playerId) return false;
    await _put(folder, null);
    return true;
  });

  Future<void> notifyMissing() => _serial(() async {
    if (await _read(await directory()) == null) {
      _expired.add('Сессия отсутствует. Войдите снова.');
    }
  });

  Future<void> invalidate(String token) => _serial(() async {
    final folder = await directory();
    final current = await _read(folder);
    if (current == null || current.token != token) return;
    try {
      await _put(folder, null);
      _expired.add('Сессия истекла. Войдите снова.');
    } catch (_) {
      _expired.add('Не удалось очистить сессию. Повторите выход из аккаунта.');
      rethrow;
    }
  });
}