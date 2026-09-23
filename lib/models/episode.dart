import 'scene.dart'; // Импорт класса Scene

// Класс Episode (один эпизод, глава истории)
class Episode {
  final int id; // Id эпизода
  final String title; // Название
  final List<Scene> scenes; // Список сцен

  // Конструктор класса Episode
  const Episode({
    required this.id,
    required this.title,
    required this.scenes,
  });

  // Превращение объекта Episode в Map, который можно записать в JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'scenes': scenes.map((s) => s.toJson()).toList(),
  };

  // Создание объекта Episode из Map, который был прочитан из JSON
  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    id: json['id'],
    title: json['title'],
    scenes: (json['scenes'] as List).map((s) => Scene.fromJson(s)).toList(),
  );
}