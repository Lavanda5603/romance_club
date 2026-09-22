import 'action.dart';

class Choice {
  final String text;
  final List<Action> actions;

  const Choice({
    required this.text,
    required this.actions,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'actions': actions.map((a) => a.toJson()).toList(),
  };

  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
    text: json['text'],
    actions: (json['actions'] as List).map((a) => Action.fromJson(a)).toList(),
  );
}