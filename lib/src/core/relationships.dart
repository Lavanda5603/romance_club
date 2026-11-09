import '../../generated/progress.pb.dart'; // Импорт снимка сохранённого прогресса

// Не складываю накопленные снимки: выбираю последний в текущем поколении сброса.
Map<String, int> relationshipScores(Iterable<Progress> snapshots) {
  final all = snapshots.toList();
  if (all.isEmpty) return {};
  final generation = all.map((p) => p.generation).reduce((a, b) => a > b ? a : b);
  final active = all.where((p) => p.generation == generation && p.sceneId.isNotEmpty).toList();
  active.sort((a, b) {
    final time = (DateTime.tryParse(a.updatedAt)?.millisecondsSinceEpoch ?? 0)
      .compareTo(DateTime.tryParse(b.updatedAt)?.millisecondsSinceEpoch ?? 0);
    return time != 0 ? time : a.episodeId.compareTo(b.episodeId);
  });
  return active.isEmpty ? {} : Map.of(active.last.counters);
}

// Отрицательные баллы показываю честно, отдельно от положительной шкалы.
String relationshipLevel(int points, List<dynamic> tiers) {
  if (points < 0) return 'Напряжённые отношения';
  var title = tiers.first['title'] as String;
  for (final tier in tiers) {
    if (points >= (tier['points'] as int)) title = tier['title'] as String;
  }
  return title;
}

const relationshipCards = <Map<String, String>>[
  {'counter':'romance_adrian','title':'Маринетт + Адриан','character':'adrian','emotion':'smile','kind':'romance'},
  {'counter':'romance_cat','title':'Маринетт + Супер-Кот','character':'catnoir','emotion':'smile','kind':'romance'},
  {'counter':'romance_ladybug_adrian','title':'Леди Баг + Адриан','character':'adrian','emotion':'smile','kind':'romance'},
  {'counter':'romance_ladybug_cat','title':'Леди Баг + Супер-Кот','character':'catnoir','emotion':'smile','kind':'romance'},
  {'counter':'romance_luka','title':'Маринетт + Лука','character':'luka','emotion':'smile','kind':'romance'},
  {'counter':'friendship_alya','title':'Дружба с Альей','character':'alya','emotion':'happy','kind':'friendship'},
  {'counter':'friendship_nino','title':'Дружба с Нино','character':'nino','emotion':'normal','kind':'friendship'},
  {'counter':'friendship_kagami','title':'Дружба с Кагами','character':'kagami','emotion':'surprised','kind':'friendship'},
  {'counter':'friendship_chloe','title':'Дружба с Хлоей','character':'chloe','emotion':'smirk','kind':'friendship'},
];