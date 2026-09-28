import 'package:surrealdb/surrealdb.dart'; // Импорт SurrealDB

// Сервис для работы с SurrealDB
class SurrealService {
  // Создаю клиент (класс SurrealDB)
  static final SurrealDB _db = SurrealDB('ws://127.0.0.1:8000/rpc');

  // Подключение к базе
  static Future<void> connect() async {
    // Подключаюсь к локальному серверу
    _db.connect();

    // Жду, пока соединение установится
    _db.wait();

    // Использую namespace и database
    await _db.use('romance_club', 'game');

    // Авторизуюсь (root/root - по умолчанию)
    await _db.signin(user: 'root', pass: 'root');

    print('Подключение к SurrealDB установлено');
  }

  // Создать запись
  static Future<void> create(String table, Map<String, dynamic> data) async {
    await _db.create(table, data);
  }

  // Получить все записи
  static Future<List<Map<String, dynamic>>> getAll(String table) async {
    final results = await _db.select(table); // List<dynamic>
    return results.cast<Map<String, dynamic>>(); // Преобразую тип
  }

  // Получить одну запись по ID
  static Future<Map<String, dynamic>?> getById(String id) async {
    final results = await _db.select(id); // List<dynamic>
    if (results.isNotEmpty) {
      return results.first as Map<String, dynamic>; // Первая запись
    }
    return null;
  }

  // Обновить запись
  static Future<void> update(String id, Map<String, dynamic> data) async {
    await _db.update(id, data);
  }

  // Удалить запись
  static Future<void> delete(String id) async {
    await _db.delete(id);
  }

  // Закрыть соединение
  static void close() {
    _db.close();
  }
}