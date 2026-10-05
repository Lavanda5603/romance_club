// Доменная модель достижения
class AchievementModel {
  final String name; // Ключ достижения (all_episodes, all_endings, ...)
  final String unlockedAt; // Дата открытия (пусто, если не открыто)

  // Конструктор класса AchievementModel
  const AchievementModel({
    required this.name,
    required this.unlockedAt,
  });

  // Открыто ли достижение
  bool get isUnlocked => unlockedAt.isNotEmpty;
}