import 'action.dart'; // Импорт класса Action

// Класс Choice (один вариант выбора, видит игрок)
class Choice {
  final String text; // Текст
  final List<Action> actions; // Список действий

  // Конструктор класса Choice
  const Choice({
    required this.text,
    required this.actions,
  });

  // Превращение объекта Choice в Map, который можно записать в JSON
  Map<String, dynamic> toJson() => {
    'text': text,
    'actions': actions.map((a) => a.toJson()).toList(),
  };

  // Создание объекта Choice из Map, который был прочитан из JSON
  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
    text: json['text'],
    actions: (json['actions'] as List).map((a) => Action.fromJson(a)).toList(),
  );
}