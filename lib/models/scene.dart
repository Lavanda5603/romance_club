import 'choice.dart'; // Импорт класса Choice

// Класс Scene (одна сцена, тексты и выборы)
class Scene {
  final int id; // Id сцены
  final String background; // Фон
  final String character; // Персонаж
  final List<String> texts; // Список текстов
  final List<Choice> choices; // Список выборов
  final String? condition; // Условие показа

  // Конструктор класса Scene
  const Scene({
    required this.id,
    required this.background,
    required this.character,
    required this.texts,
    required this.choices,
    this.condition,
  });

  // Превращение объекта Scene в Map, который можно записать в JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'background': background,
    'character': character,
    'texts': texts,
    'choices': choices.map((c) => c.toJson()).toList(),
    if (condition != null) 'condition': condition,
  };

  // Создание объекта Scene из Map, который был прочитан из JSON
  factory Scene.fromJson(Map<String, dynamic> json) => Scene(
    id: json['id'],
    background: json['background'],
    character: json['character'],
    texts: List<String>.from(json['texts']),
    choices: (json['choices'] as List).map((c) => Choice.fromJson(c)).toList(),
    condition: json['condition'],
  );
}