import '../generated/action.pb.dart'; // Импорт класса Action (из Protobuf)

// Сервис для работы с сетью (отправка и получение данных)
class ApiService {
  // Отправка действия на сервер
  Future<void> sendAction(Action action) async {
    final bytes = action.writeToBuffer(); // Превращаю Action в байты
    print('Отправляю ${bytes.length} байт на сервер');
  }
  
  // Получение действия с сервера
  Future<Action> getAction() async {
    final action = Action(
      type: 'nextScene', // Тип действия
      sceneId: 5, // Id сцены
    );

    return action; // Возвращаю действие
  }
}