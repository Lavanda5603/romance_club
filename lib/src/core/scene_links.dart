import 'dart:math';
import '../../generated/scene.pb.dart';
import '../../generated/action.pb.dart';

// Даю новой сцене временный ключ до сохранения на сервере
String newSceneKey() {
  final random = Random.secure();
  return 'draft:${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}

extension SceneLink on Scene {
  String get nextSceneTarget => nextSceneKey.isNotEmpty
      ? nextSceneKey
      : nextSceneId > 0 ? 'scene:$nextSceneId' : '';
}

extension ActionLink on Action {
  String get sceneTarget => sceneKey.isNotEmpty
      ? sceneKey
      : sceneId > 0 ? 'scene:$sceneId' : '';
}
