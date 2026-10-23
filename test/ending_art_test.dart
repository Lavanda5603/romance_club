import 'package:flutter/services.dart'; // Импорт загрузки файлов приложения
import 'package:flutter_test/flutter_test.dart'; // Импорт Flutter-тестов
import 'package:romance_club/src/core/ending_art.dart'; // Импорт картинок концовок

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Старые ссылки сцен ведут на точные картинки пяти пар', () {
    expect(endingSceneArtwork('ep1/kiss_marinet_adrian'), endingArtwork['МариАдриан']);
    expect(endingSceneArtwork('ep1/kiss_marinet_catnoir'), endingArtwork['МариКот']);
    expect(endingSceneArtwork('ep1/kiss_ladybug_adrian'), endingArtwork['АдриБаг']);
    expect(endingSceneArtwork('ep1/kiss_ladybug_catnoir'), endingArtwork['СуперБаг']);
    expect(endingSceneArtwork('ep1/kiss_marinet_luka'), endingArtwork['Лука']);
    expect(endingSceneArtwork('неизвестный фон'), isNull);
  });

  test('Все пять концовок получают отдельный настоящий PNG из сборки', () async {
    expect(endingArtwork.length, 5);
    expect(endingArtwork.values.toSet().length, 5);
    for (final path in endingArtwork.values) {
      final bytes = (await rootBundle.load(path)).buffer.asUint8List();
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10], reason: path);
    }
  });
}