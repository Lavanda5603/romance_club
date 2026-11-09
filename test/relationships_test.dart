import 'package:flutter_test/flutter_test.dart'; // Импорт проверки баллов
import 'package:romance_club/generated/progress.pb.dart'; // Импорт снимков прогресса
import 'package:romance_club/src/core/relationships.dart'; // Импорт расчёта карточек

void main() {
  test('Не складываю накопленные баллы двух эпизодов', () {
    final scores = relationshipScores([
      Progress(episodeId: 1, sceneId: 'scene:1', counters: {'romance_luka': 3}.entries, updatedAt: '2026-11-02T10:00:00Z'),
      Progress(episodeId: 2, sceneId: 'scene:2', counters: {'romance_luka': 5}.entries, updatedAt: '2026-11-02T11:00:00Z'),
    ]);
    expect(scores['romance_luka'], 5);
  });
  test('Повторное прохождение раннего эпизода показывает его свежий снимок', () {
    expect(relationshipScores([
      Progress(episodeId: 1, sceneId: 'scene:1', counters: {'friendship': 1}.entries, updatedAt: '2026-11-02T12:00:00Z'),
      Progress(episodeId: 4, sceneId: 'scene:4', counters: {'friendship': 8}.entries, updatedAt: '2026-11-02T11:00:00Z'),
    ])['friendship'], 1);
  });
  test('После полного сброса не восстанавливаю старое поколение', () {
    expect(relationshipScores([
      Progress(generation: 0, episodeId: 5, sceneId: 'scene:5', counters: {'friendship': 20}.entries),
      Progress(generation: 1, episodeId: 1),
    ]), isEmpty);
  });
  test('Показываю точные границы уровней и отрицательные отношения', () {
    final tiers = [{'points': 0, 'title': 'Знакомство'}, {'points': 3, 'title': 'Симпатия'}, {'points': 7, 'title': 'Близость'}];
    expect(relationshipLevel(0, tiers), 'Знакомство');
    expect(relationshipLevel(2, tiers), 'Знакомство');
    expect(relationshipLevel(3, tiers), 'Симпатия');
    expect(relationshipLevel(7, tiers), 'Близость');
    expect(relationshipLevel(-1, tiers), 'Напряжённые отношения');
  });
}