import 'dart:io'; // Иморт для работы с файлами
import 'dart:typed_data'; // Имопрт для работы с байтами
import 'package:path_provider/path_provider.dart'; // Импорт для пути к папке
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../generated/settings.pb.dart'; // Импорт Protobuf-модели Settings

// Сервис для сохранения и загрузки эпизодов (локально)
class StorageService {
  
  // Получение файла для хранения данных
  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory(); // Папка приложения
    return File('${directory.path}/episodes.pb'); /// Файл episodes.pb
  }

  // Сохранение списка эпизодов в файл (эпизод в байты)
  static Future<void> saveEpisodes(List<Episode> episodes) async {
    final file = await _getFile(); // Получаю файл
    
    // Создаю буфер для всех эпизодов
    final buffer = BytesBuilder();
    
    for (final episode in episodes) {
      // Эпизод в байты
      final bytes = episode.writeToBuffer();
      
      // Записываю длину эпизода
      final lengthBytes = ByteData(4)..setInt32(0, bytes.length);
      buffer.add(lengthBytes.buffer.asUint8List());
      
      // Записываю сам эпизод
      buffer.add(bytes);
    }
    
    await file.writeAsBytes(buffer.toBytes()); // Записываем в файл
  }

  // Загрузка эпизодов из файла
  static Future<List<Episode>> loadEpisodes() async {
    final file = await _getFile(); // Получаю файл
    
    if (!await file.exists()) {
      return []; // Если файла нет, то возвращаю пустой список
    }
    
    // Читаю все байты из файла
    final allBytes = await file.readAsBytes();
    final episodes = <Episode>[];
    
    int offset = 0;
    
    // Читаю эпизоды один за другим
    while (offset < allBytes.length) {
      // Читаю длину эпизода
      final lengthBytes = allBytes.sublist(offset, offset + 4);
      final length = ByteData.sublistView(
        Uint8List.fromList(lengthBytes),
      ).getInt32(0);
      
      offset += 4;
      
      // Читаю байты эпизода
      final episodeBytes = allBytes.sublist(offset, offset + length);
      offset += length;
      
      // Превращаю байты в объект Episode
      final episode = Episode.fromBuffer(episodeBytes);
      episodes.add(episode);
    }
    
    return episodes;
  }

  // Получение файла настроек
  static Future<File> _getSettingsFile() async {
    final directory = await getApplicationDocumentsDirectory(); // Папка приложения
    return File('${directory.path}/settings.pb'); /// Файл settings.pb
  }

  // Сохранение настроек в файл (настройки в байты)
  static Future<void> saveSettings(Settings settings) async {
    final file = await _getSettingsFile(); // Получаю файл
    await file.writeAsBytes(settings.writeToBuffer()); // Записываю байты
  }

  // Загрузка настроек из файла
  static Future<Settings> loadSettings() async {
    final file = await _getSettingsFile(); // Получаю файл

    if (!await file.exists()) {
      // Если файла нет, возвращаю настройки по умолчанию
      return Settings(
        musicVolume: 0.6, // Громкость музыки по умолчанию
        soundVolume: 0.3, // Громкость звуков по умолчанию
      );
    }

    // Читаю байты из файла
    final bytes = await file.readAsBytes();

    // Превращаю байты в объект Settings
    return Settings.fromBuffer(bytes);
  }
}