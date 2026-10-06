import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../src/data/repositories/episode_repository_remote.dart'; // Импорт репозитория эпизодов
import '../src/data/repositories/progress_repository_remote.dart'; // Импорт репозитория прогресса
import '../src/data/repositories/achievement_repository_remote.dart'; // Импорт репозитория достижений
import '../src/data/services/episode_grpc_service.dart'; // Импорт gRPC-сервиса эпизодов
import '../src/data/services/progress_grpc_service.dart'; // Импорт gRPC-сервиса прогресса
import '../src/data/services/achievement_grpc_service.dart'; // Импорт gRPC-сервиса достижений
import '../src/features/game/game_view_model.dart'; // Импорт ViewModel
import 'episode_end_screen.dart'; // Иморт экрана конца эпизода

// Игровой экран
class GameScreen extends StatefulWidget {
  final Episode episode; // Эпизод (Protobuf)
  final bool startFromBeginning;

  // Конструктор класса GameScreen
  const GameScreen({
    super.key,
    required this.episode,
    this.startFromBeginning = false,
  });

  // Метод createState (создание объекта состояния)
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameViewModel _viewModel; // ViewModel
  late EpisodeGrpcService _episodeService; // gRPC-сервис эпизодов
  late ProgressGrpcService _progressService; // gRPC-сервис прогресса
  late AchievementGrpcService _achievementService; // gRPC-сервис достижений
  late EpisodeRepositoryRemote _episodeRepository; // Репозиторий эпизодов
  late ProgressRepositoryRemote _progressRepository; // Репозиторий прогресса
  late AchievementRepositoryRemote _achievementRepository; // Репозиторий достижений

  @override
  void initState() {
    super.initState();
    // Создаю gRPC-сервисы
    _episodeService = EpisodeGrpcService();
    _progressService = ProgressGrpcService();
    _achievementService = AchievementGrpcService();
    // Создаю репозитории
    _episodeRepository = EpisodeRepositoryRemote(_episodeService);
    _progressRepository = ProgressRepositoryRemote(_progressService);
    _achievementRepository = AchievementRepositoryRemote(_achievementService);
    // Создаю ViewModel
    _viewModel = GameViewModel(_episodeRepository, _progressRepository, _achievementRepository);
    // Загружаю эпизод с сервера по ID
    _viewModel.loadEpisode(widget.episode.id, startFromBeginning: widget.startFromBeginning);
  }

  @override
  void dispose() {
    // Закрываю соединения
    _episodeService.close();
    _progressService.close();
    _achievementService.close();
    _viewModel.dispose();
    super.dispose();
  }

  // Получаю Alignment для позиции (9 вариантов)
  Alignment _getAlignment(String position) {
    switch (position) {
      // Верх
      case 'top_left':
        return Alignment.topLeft;
      case 'top_center':
      case 'top':
        return Alignment.topCenter;
      case 'top_right':
        return Alignment.topRight;

      // Середина
      case 'center_left':
      case 'left':
        return Alignment.centerLeft;
      case 'center_right':
      case 'right':
        return Alignment.centerRight;

      // Низ
      case 'bottom_left':
        return Alignment.bottomLeft;
      case 'bottom_center':
      case 'bottom':
        return Alignment.bottomCenter;
      case 'bottom_right':
        return Alignment.bottomRight;

      // По умолчанию
      case 'center':
      default:
        return Alignment.center;
    }
  }

  // Собираю путь к фону
  String _getBackgroundPath(String background) {
    if (background.isEmpty) return '';
    // Локально: assets/images/ep1/paris_morning.png
    return 'assets/images/$background.png';
  }

  // Собираю путь к персонажу
  String _getCharacterPath(String character, String emotion) {
    if (character.isEmpty) return '';
    final e = emotion.isEmpty ? 'default' : emotion;
    // Локально: assets/characters/marinet_sad.png
    return 'assets/characters/${character}_$e.png';
  }

  // Получаю имя персонажа для отображения
  String _getCharacterName(String character) {
    switch (character) {
      case 'marinet':
        return 'Маринетт';
      case 'adrian':
        return 'Адриан';
      case 'cat':
        return 'Супер-Кот';
      case 'ladybug':
        return 'Леди Баг';
      case 'luka':
        return 'Лука';
      case 'mama':
        return 'Мама';
      case 'grandpa':
        return 'Дедушка';
      default:
        return character;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Каркас экрана
      backgroundColor: const Color(0xFF1A1A1A), // Фон экрана
      body: ListenableBuilder(
        listenable: _viewModel, // Слушаю ViewModel
        builder: (context, _) {
          final state = _viewModel.state; // Текущее состояние

          // Если загрузка
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Если ошибка
          if (state.error != null) {
            return Center(
              child: Text(
                'Ошибка: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // Если эпизод загружен
          final scene = _viewModel.currentScene;

          // Если сцены нет
          if (scene == null) {
            return const Center(
              child: Text(
                'Нет сцены',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Собираю пути к картинкам
          final bgPath = _getBackgroundPath(scene.background);
          final charPath = _getCharacterPath(scene.character, scene.characterEmotion);
          final charName = _getCharacterName(scene.character);

          // Основной интерфейс
          return GestureDetector(
            // Клик по экрану - следующая реплика
            onTap: () {
              if (_viewModel.hasMoreTexts) {
                _viewModel.nextText();
              }
            },
            child: Stack( // Стопка виджетов
              children: [
                // Фон сцены
                Positioned.fill(
                  child: bgPath.isEmpty
                      ? Container(color: const Color(0xFF333333))
                      : Image.asset(
                          bgPath,
                          fit: BoxFit.cover,
                          // Заглушка, если файла нет
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: const Color(0xFF333333));
                          },
                        ),
                ),
                // Затемнение снизу (чтоб текст читался)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Персонаж (если есть) — сдвинут вверх, чтобы не пересекаться с текстом
                if (charPath.isNotEmpty)
                  Positioned(
                    top: 60, // Отступ сверху, чтобы не перекрывать кнопки
                    left: 0,
                    right: 0,
                    bottom: 200, // Отступ снизу, чтобы не пересекаться с текстом
                    child: Align(
                      alignment: _getAlignment(
                        scene.characterPosition.isNotEmpty
                            ? scene.characterPosition
                            : 'center',
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 0.55,
                        heightFactor: 0.55,
                        child: Image.asset(
                          charPath,
                          fit: BoxFit.contain,
                          // Заглушка, если файла нет
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 250,
                              color: Colors.red[300],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                // Верхняя панель: баллы и кнопка выхода
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      // Кнопка выхода
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F0404).withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFFD30010),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Баллы
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3F0404).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Баллы: ${_viewModel.points}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Текст (облачко) — в позиции text_position
                Align(
                  alignment: _getAlignment(
                    scene.textPosition.isNotEmpty
                        ? scene.textPosition
                        : 'bottom_center',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Имя персонажа над текстом
                        if (charName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFA0A0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                charName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        // Текст сцены (розовое облачко)
                        GestureDetector(
                          onTap: () {
                            if (_viewModel.hasMoreTexts) {
                              _viewModel.nextText();
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA0A0),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _viewModel.currentText.isNotEmpty
                                  ? _viewModel.currentText
                                  : 'нет текста',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Выборы — внизу экрана
                if (_viewModel.isTextFinished && scene.choices.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: scene.choices.asMap().entries.map((entry) {
                        final index = entry.key;
                        final choice = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => _viewModel.onChoiceSelected(index),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFA0A0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      choice.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                // Кнопка дальше
                else if (_viewModel.isTextFinished && scene.choices.isEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Center(
                      child: SizedBox(
                        width: 200,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_viewModel.isLastScene) {
                              // Определяю концовку
                              final ending = _viewModel.determineEnding();

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EpisodeEndScreen(
                                    currentEpisode: widget.episode,
                                    ending: ending,
                                  ),
                                ),
                              );
                              return;
                            }
                            _viewModel.nextScene();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD30010),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _viewModel.isLastScene ? 'конец эпизода' : 'дальше',
                            style: const TextStyle(
                              color: Color(0xFF3F0404),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}