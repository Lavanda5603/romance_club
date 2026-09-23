import '../generated/action.pb.dart';

class ApiService {
  Future<void> sendAction(Action action) async {
    final bytes = action.writeToBuffer();
    print('Отправляю ${bytes.length} байт на сервер');
  }
  Future<Action> getAction() async {
    final action = Action(
      type: 'nextScene',
      sceneId: 5,
    );

    return action;
  }
}