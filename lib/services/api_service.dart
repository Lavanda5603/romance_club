import 'package:flutter/foundation.dart'; // Импорт для debugPrint
import '../generated/action.pb.dart'; // Импорт Protobuf-модели Action

// Сервис для работы с сетью (отправка и получение данных)
class ApiService {
  // Отправка действия на сервер
  Future<void> sendAction(Action action) async {
    final bytes = action.writeToBuffer(); // Превращаю Action в байты 
    debugPrint('Отправляю ${bytes.length} байт на сервер'); // Вывод в консоль (debugPrint)
  }

  // Получение действия с сервера
  Future<Action> getAction() async {
    final action = Action(
      type: 'nextScene', // Тип действия
      sceneId: 5, // ID сцены
    );
    return action; // Возвращаю действие
  }
}