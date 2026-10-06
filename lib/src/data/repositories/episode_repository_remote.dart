import '../../domain/models/episode_model.dart'; // Импорт доменных моделей
import '../../domain/repositories/episode_repository.dart'; // Импорт контракта
import '../services/episode_grpc_service.dart'; // Импорт gRPC-сервиса
import '../../../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../../../generated/scene.pb.dart'; // Импорт Protobuf-модели Scene
import '../../../generated/choice.pb.dart'; // Импорт Protobuf-модели Choice
import '../../../generated/action.pb.dart'; // Импорт Protobuf-модели Action

// Реализация репозитория через gRPC
class EpisodeRepositoryRemote implements EpisodeRepository {
  final EpisodeGrpcService _service; // gRPC-сервис

  // Конструктор класса EpisodeRepositoryRemote
  EpisodeRepositoryRemote(this._service);

  // Получить эпизод по ID
  @override
  Future<EpisodeModel> getEpisode(int id) async {
    // Запрашиваю эпизод у сервера
    final episode = await _service.getEpisode(id);

    // Преобразую Protobuf-модель в доменную
    return toDomain(episode);
  }

  // Получить все эпизоды
  @override
  Future<List<EpisodeModel>> getAllEpisodes() async {
    // Запрашиваю все эпизоды у сервера
    final episodes = await _service.getAllEpisodes();

    // Преобразую каждую Protobuf-модель в доменную
    return episodes.map(toDomain).toList();
  }

  // Сохранить эпизод
  @override
  Future<bool> saveEpisode(EpisodeModel episode) async {
    // Преобразую доменную модель в Protobuf
    final protoEpisode = toProto(episode);

    // Отправляю на сервер
    final response = await _service.saveEpisode(protoEpisode);

    // Возвращаю результат
    return response.success;
  }

  // Преобразование Protobuf-модели в доменную
  EpisodeModel toDomain(Episode episode) {
    return EpisodeModel(
      id: episode.id,
      title: episode.title,
      version: episode.version,
      scenes: episode.scenes.map((scene) {
        return SceneModel(
          id: scene.id,
          sceneKey: scene.sceneKey,
          title: scene.title,
          background: scene.background,
          character: scene.character,
          characterEmotion: scene.characterEmotion,
          texts: scene.texts,
          condition: scene.condition,
          textPosition: scene.textPosition,
          characterPosition: scene.characterPosition,
          choices: scene.choices.map((choice) {
            return ChoiceModel(
              text: choice.text,
              title: choice.title,
              actions: choice.actions.map((action) {
                return ActionModel(
                  type: action.type,
                  sceneId: action.sceneId,
                  flagName: action.flagName,
                  flagValue: action.flagValue,
                  counterName: action.counterName,
                  counterValue: action.counterValue,
                  soundPath: action.soundPath,
                  imagePath: action.imagePath,
                  title: action.title,
                );
              }).toList(),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  // Преобразование доменной модели в Protobuf
  Episode toProto(EpisodeModel episode) {
    final protoEpisode = Episode(
      id: episode.id,
      title: episode.title,
      version: episode.version,
    );

    // Добавляю сцены
    for (final scene in episode.scenes) {
      final protoScene = Scene(
        id: scene.id,
        sceneKey: scene.sceneKey,
        title: scene.title,
        background: scene.background,
        character: scene.character,
        characterEmotion: scene.characterEmotion,
        condition: scene.condition,
        textPosition: scene.textPosition,
        characterPosition: scene.characterPosition,
      );
      protoScene.texts.addAll(scene.texts);

      // Добавляю выборы
      for (final choice in scene.choices) {
        final protoChoice = Choice(
          text: choice.text,
          title: choice.title,
        );

        // Добавляю действия
        for (final action in choice.actions) {
          final protoAction = Action(
            type: action.type,
            sceneId: action.sceneId,
            flagName: action.flagName,
            flagValue: action.flagValue,
            counterName: action.counterName,
            counterValue: action.counterValue,
            soundPath: action.soundPath,
            imagePath: action.imagePath,
            title: action.title,
          );
          protoChoice.actions.add(protoAction);
        }
        protoScene.choices.add(protoChoice);
      }
      protoEpisode.scenes.add(protoScene);
    }

    return protoEpisode;
  }
}