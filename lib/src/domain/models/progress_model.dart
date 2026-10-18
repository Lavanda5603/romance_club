// Доменная модель прогресса
class ProgressModel {
  final String playerId; // ID игрока
  final int episodeId; // ID эпизода
  final String ending; // Концовка завершённого прохождения
  final bool completed; // Эпизод завершён
  final int revision; // Версия сохранения
  final String sceneId; // ID сцены
  final Map<String, bool> flags; // Флаги
  final Map<String, int> counters; // Счётчики (баллы)

  // Конструктор
  const ProgressModel({
    required this.playerId,
    required this.episodeId,
    required this.sceneId,
    this.revision = 0,
    this.completed = false,
    this.ending = '',
    required this.flags,
    required this.counters,
  });

  // Пустой прогресс (когда ничего нет)
  factory ProgressModel.empty() => const ProgressModel(
        playerId: '',
        episodeId: 0,
        sceneId: '',
        flags: {},
        counters: {},
      );
}