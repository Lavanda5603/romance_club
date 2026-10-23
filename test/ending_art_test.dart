import 'package:flutter/services.dart'; // Импорт загрузки файлов приложения
import 'package:flutter_test/flutter_test.dart'; // Импорт Flutter-тестов
import 'package:romance_club/src/core/ending_art.dart'; // Импорт картинок концовок

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Все пять концовок получают отдельный настоящий PNG из сборки', () async {
    expect(endingArtwork.length, 5);
    expect(endingArtwork.values.toSet().length, 5);
    for (final path in endingArtwork.values) {
      final bytes = (await rootBundle.load(path)).buffer.asUint8List();
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10], reason: path);
    }
  });
}