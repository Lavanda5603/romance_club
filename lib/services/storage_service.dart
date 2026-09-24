import 'dart:convert'; // Импорт для работы с JSON
import 'dart:io'; // Импорт для работы с файлами
import 'package:path_provider/path_provider.dart'; // Импорт для пути к папке
import '../models/episode.dart'; // Импорт класса Episode

// Сервис для сохранения и загрузки эпизодов (локально)
class StorageService {
  // Получение файла для хранения данных
  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory(); // Папка приложения
    return File('${directory.path}/game_data.json'); // Файл game_data.json
  }

  // Сохранение эпизодов в файл
  static Future<void> saveEpisodes(List<Episode> episodes) async {
    final file = await _getFile(); // Получаю файл
    final json = {
      'episodes': episodes.map((e) => e.toJson()).toList(), // Превращаю эпизоды в JSON
    };
    await file.writeAsString(jsonEncode(json)); // Записываю в файл
  }

  // Загрузка эпизодов из файла
  static Future<List<Episode>> loadEpisodes() async {
    final file = await _getFile(); // Получаю файл
    if (!await file.exists()) {
      return []; // Если файла нет, возвращаю пустой список
    }
    final jsonString = await file.readAsString(); // Читаю файл
    final json = jsonDecode(jsonString); // Превращаю строку в JSON
    return (json['episodes'] as List).map((e) => Episode.fromJson(e)).toList(); // Превращаю JSON в эпизоды
  }
}