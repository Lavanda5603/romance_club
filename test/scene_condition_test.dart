import 'dart:io'; // Читаю настоящие правила переноса старого сюжета
import 'package:flutter_test/flutter_test.dart'; // Подключаю проверки выражений
import 'package:romance_club/src/core/scene_condition.dart'; // Подключаю разбор условий

void main() {
  final counters = {'points': 8, 'friendship': 5, 'romance_adrian': 9, 'romance_cat': 3, 'custom_score': -2};
  final flags = {'met': true, 'secret': false};
  for (final expression in [
    '', '  ', 'friendship>=5', 'romance_adrian > romance_cat', 'points <= 8',
    'custom_score = -2', 'new_counter == 0', 'flag:met=true', 'flag:secret=false',
    'flag:met != false', 'friendship>=5 И points>0', 'points<0 ИЛИ flag:met=true',
    'points<0 OR friendship>=5 AND romance_cat<4', '(points<0 || friendship>=5) && flag:met=true',
    'points!=9',
  ]) {
    test('Условие выполнено: $expression', () {
      expect(SceneCondition.parse(expression).evaluate(counters, flags), isTrue);
    });
  }
  for (final expression in ['points>8', 'friendship<5', 'flag:met=false',
    'flag:missing=true', 'points<0 AND flag:met=true', '(points<0 OR friendship>5) AND flag:met=true']) {
    test('Условие не выполнено: $expression', () {
      expect(SceneCondition.parse(expression).evaluate(counters, flags), isFalse);
    });
  }
  for (final expression in ['points>=abc!', 'points>=', 'points>=five words', 'points=>5',
    'flag:met=yes', 'flag:met>5', 'flag:=true', 'points>=5 AND', 'friendship',
    '(points>0', 'points>0)', 'points>0 OR (flag:met=true &&)', 'true', 'points>=1;DELETE scene']) {
    test('Ошибку не принимаю за выполненное условие: $expression', () {
      expect(() => SceneCondition.parse(expression), throwsFormatException);
      expect(SceneCondition.error(expression), isNotNull);
    });
  }
  test('Ограничиваю длину и вложенность условия', () {
    expect(SceneCondition.error(' ' * 2049), isNotNull);
    expect(SceneCondition.error('${'(' * 33}points>0${')' * 33}'), isNotNull);
  });
  test('Перенесённые ветки сохраняют прежний выбор по максимуму и порядок при равенстве', () {
    final sql=File('server/migrations/026_story_route_rules.surql').readAsStringSync();
    final rules=RegExp("condition:'([^']+)',scene_key:'([^']+)'").allMatches(sql).toList();
    expect(rules.length,9);
    for (final group in [rules.take(4).toList(),rules.skip(4).toList()]) {
      for (final rule in group) {
        final counter=rule.group(1)!.split('>')[0];
        final values={counter:5};
        final winner=group.firstWhere((r)=>SceneCondition.parse(r.group(1)!).evaluate(values,{}));
        expect(winner.group(2),rule.group(2));
      }
      final tied={for(final r in group) r.group(1)!.split('>')[0]:5};
      expect(group.firstWhere((r)=>SceneCondition.parse(r.group(1)!).evaluate(tied,{})),group.first);
      expect(group.any((r)=>SceneCondition.parse(r.group(1)!).evaluate({},{})),isFalse);
    }
  });

  test('Русские флаги из рабочей истории доступны в условиях с И и ИЛИ', () {
    final condition = SceneCondition.parse('flag:помог_дедушке=true И (flag:взяла_зонт=true ИЛИ points>9)');
    expect(condition.evaluate({}, {'помог_дедушке': true, 'взяла_зонт': true}), true);
    expect(condition.evaluate({}, {'помог_дедушке': false, 'взяла_зонт': true}), false);
  });

}