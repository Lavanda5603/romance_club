import 'choice.dart';

class Scene {
  final int id;
  final String background;
  final String character;
  final List<String> texts;
  final List<Choice> choices;
  final String? condition;

  const Scene({
    required this.id,
    required this.background,
    required this.character,
    required this.texts,
    required this.choices,
    this.condition,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'background': background,
    'character': character,
    'texts': texts,
    'choices': choices.map((c) => c.toJson()).toList(),
    if (condition != null) 'condition': condition,
  };

  factory Scene.fromJson(Map<String, dynamic> json) => Scene(
    id: json['id'],
    background: json['background'],
    character: json['character'],
    texts: List<String>.from(json['texts']),
    choices: (json['choices'] as List).map((c) => Choice.fromJson(c)).toList(),
    condition: json['condition'],
  );
}