// Доменная модель эпизода
class EpisodeModel {
  final int id; // ID эпизода
  final String title; // Название
  final int version; // Версия
  final List<SceneModel> scenes; // Сцены

  // Конструктор класса EpisodeModel
  const EpisodeModel({
    required this.id,
    required this.title,
    required this.version,
    required this.scenes,
  });
}

// Доменная модель сцены
class SceneModel {
  final int id; // ID сцены (номер)
  final String sceneKey; // Настоящий ID в SurrealDB
  final String title; // Название
  final String background; // Фон
  final String character; // Персонаж
  final String characterEmotion; // Эмоция персонажа
  final List<String> texts; // Тексты
  final List<ChoiceModel> choices; // Выборы
  final String condition; // Условие
  final String textPosition; // Позиция текста
  final String characterPosition; // Позиция персонажа

  // Конструктор класса SceneModel
  const SceneModel({
    required this.id,
    required this.sceneKey,
    required this.title,
    required this.background,
    required this.character,
    required this.characterEmotion,
    required this.texts,
    required this.choices,
    required this.condition,
    required this.textPosition,
    required this.characterPosition,
  });
}

// Доменная модель выбора
class ChoiceModel {
  final String text; // Текст выбора
  final String title; // Название
  final List<ActionModel> actions; // Действия

  // Конструктор класса ChoiceModel
  const ChoiceModel({
    required this.text,
    required this.title,
    required this.actions,
  });
}

// Доменная модель действия
class ActionModel {
  final String type; // Тип действия
  final int sceneId; // ID сцены
  final String flagName; // Имя флага
  final bool flagValue; // Значение флага
  final String counterName; // Имя счётчика
  final int counterValue; // Значение счётчика
  final String soundPath; // Путь к звуку
  final String imagePath; // Путь к картинке
  final String title; // Название

  // Конструктор класса ActionModel
  const ActionModel({
    required this.type,
    required this.sceneId,
    required this.flagName,
    required this.flagValue,
    required this.counterName,
    required this.counterValue,
    required this.soundPath,
    required this.imagePath,
    required this.title,
  });
}