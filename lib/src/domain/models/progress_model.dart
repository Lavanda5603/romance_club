// Доменная модель прогресса
class ProgressModel {
  final int playerId; // ID игрока
  final int episodeId; // ID эпизода
  final String sceneId; // ID сцены (строка "scene:abc123")
  final Map<String, bool> flags; // Флаги
  final Map<String, int> counters; // Счётчики (баллы)

  // Конструктор класса ProgressModel
  const ProgressModel({
    required this.playerId,
    required this.episodeId,
    required this.sceneId,
    required this.flags,
    required this.counters,
  });

  // Пустой прогресс (когда ничего нет)
  factory ProgressModel.empty() => const ProgressModel(
        playerId: 0,
        episodeId: 0,
        sceneId: '',
        flags: {},
        counters: {},
      );
}