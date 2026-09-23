// Класс Action (одно действие, происходит после выбора игрока)
class Action {
  final String type; // Тип действия
  final int? sceneId; // Id сцены
  final String? flagName; // Имя флага
  final bool? flagValue; // Значение флага
  final String? counterName; // Имя счётчика
  final int? counterValue; // Значение счётчика
  final String? soundPath; // Путь к звуку
  final String? imagePath; // Путь к картинке

  // Конструктор класса Action
  const Action({
    required this.type,
    this.sceneId,
    this.flagName,
    this.flagValue,
    this.counterName,
    this.counterValue,
    this.soundPath,
    this.imagePath,  
  });

  // Превращение объекта Action в Map, который можно записать в JSON
  Map<String, dynamic> toJson() => {
    'type': type,
    if (sceneId != null) 'sceneId': sceneId,
    if (flagName != null) 'flagName': flagName,
    if (flagValue != null) 'flagValue': flagValue,
    if (counterName != null) 'counterName': counterName,
    if (counterValue != null) 'counterValue': counterValue,
    if (soundPath != null) 'soundPath': soundPath,
    if (imagePath != null) 'imagePath': imagePath,
  };

  // Создание объекта Action из Map, который был прочитан из JSON
  factory Action.fromJson(Map<String, dynamic> json) => Action(
    type: json['type'],
    sceneId: json['sceneId'],
    flagName: json['flagName'],
    flagValue: json['flagValue'],
    counterName: json['counterName'],
    counterValue: json['counterValue'],
    soundPath: json['soundPath'],
    imagePath: json['imagePath'],
  );
}