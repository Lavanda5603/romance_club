import 'package:flutter/material.dart'; // Импорт Material UI (для debugPrint)
import 'package:surrealdb/surrealdb.dart'; // Импорт SurrealDB

// Сервис для работы с SurrealDB
class SurrealService {
  // Создаю клиент (класс SurrealDB; адрес сервера - WebSocket на локальном порту 8000)
  static final SurrealDB _db = SurrealDB('ws://10.0.2.2:8000/rpc');

  // Подключение к базе
  static Future<void> connect() async {
    // Подключаюсь к локальному серверу
    _db.connect();

    // Жду, пока соединение установится
    await _db.wait();

    // Использую namespace (папка проекта) и database (файл внутри папки)
    await _db.use('romance_club', 'main');

    // Авторизуюсь (root/root - по умолчанию)
    await _db.signin(user: 'root', pass: 'root');

    debugPrint('Подключение к SurrealDB установлено');
  }

  // Создать запись (общий метод; table - название таблицы; data - данные записи)
  static Future<void> create(String table, Map<String, dynamic> data) async {
    await _db.create(table, data);
  }

  // Получить все записи из таблицы
  static Future<List<Map<String, dynamic>>> getAll(String table) async {
    // Читаю все записи из таблицы
    final results = await _db.select(table); // List<dynamic>

    // Преобразую тип: List<dynamic> - List<Map<String, dynamic>>
    return results.cast<Map<String, dynamic>>();
  }

  // Получить одну запись по ID
  static Future<Map<String, dynamic>?> getById(String id) async {
    // Читаю запись по ID
    final results = await _db.select(id); // List<dynamic>

    // Если запись найдена - возвращаю первую
    if (results.isNotEmpty) {
      return results.first as Map<String, dynamic>;
    }

    // Если не найдена - возвращаю null
    return null;
  }

  // Обновить запись
  static Future<void> update(String id, Map<String, dynamic> data) async {
    // id - ID записи; data - новые данные
    await _db.update(id, data);
  }

  // Удалить запись
  static Future<void> delete(String id) async {
    // id - ID записи
    await _db.delete(id);
  }

  // Закрыть соединение
  static void close() {
    // Закрываю клиент, когда приложение закрывается
    _db.close();
  }

  // Сохранить эпизод в базу
  static Future<void> saveEpisode(Map<String, dynamic> episodeData) async {
    //  Создаю запись в таблице  episode (episodeData - данные эпизода)
    await _db.create('episode', episodeData);
  }

  // Загрузить все эпизоды из базы
  static Future<List<Map<String, dynamic>>> loadEpisodes() async {
    // Читаю все записи из таблицы episode
    final results = await _db.select('episode');

    // Преобразую тип
    return results.cast<Map<String, dynamic>>();
  }
}