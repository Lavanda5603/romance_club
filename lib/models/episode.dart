import 'scene.dart';

class Episode {
  final int id;
  final String title;
  final List<Scene> scenes;

  const Episode({
    required this.id,
    required this.title,
    required this.scenes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'scenes': scenes.map((s) => s.toJson()).toList(),
  };

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    id: json['id'],
    title: json['title'],
    scenes: (json['scenes'] as List).map((s) => Scene.fromJson(s)).toList(),
  );
}