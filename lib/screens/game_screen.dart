import 'package:flutter/material.dart'; // Импорт Material UI
import 'dart:typed_data'; // Импорт Uint8List
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../src/data/repositories/episode_repository_remote.dart'; // Импорт репозитория эпизодов
import '../src/data/repositories/progress_repository_remote.dart'; // Импорт репозитория прогресса
import '../src/data/repositories/achievement_repository_remote.dart'; // Импорт репозитория достижений
import '../src/data/repositories/asset_repository_remote.dart'; // Импорт репозитория ассетов
import '../src/data/services/episode_grpc_service.dart'; // Импорт gRPC-сервиса эпизодов
import '../src/data/services/progress_grpc_service.dart'; // Импорт gRPC-сервиса прогресса
import '../src/data/services/achievement_grpc_service.dart'; // Импорт gRPC-сервиса достижений
import '../src/data/services/asset_grpc_service.dart'; // Импорт gRPC-сервиса ассетов
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

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameViewModel _viewModel; // ViewModel
  late EpisodeGrpcService _episodeService; // gRPC-сервис эпизодов
  late ProgressGrpcService _progressService; // gRPC-сервис прогресса
  late AchievementGrpcService _achievementService; // gRPC-сервис достижений
  late AssetGrpcService _assetService; // gRPC-сервис ассетов
  late EpisodeRepositoryRemote _episodeRepository; // Репозиторий эпизодов
  late ProgressRepositoryRemote _progressRepository; // Репозиторий прогресса
  late AchievementRepositoryRemote _achievementRepository; // Репозиторий достижений
  late AssetRepositoryRemote _assetRepository; // Репозиторий ассетов

  // Кэш картинок
  final Map<String, Uint8List> _backgroundsCache = {};
  final Map<String, Uint8List> _charactersCache = {};

  bool _assetsLoaded = false;

  @override
  void initState() {
    super.initState();
    _episodeService = EpisodeGrpcService();
    _progressService = ProgressGrpcService();
    _achievementService = AchievementGrpcService();
    _assetService = AssetGrpcService();
    _episodeRepository = EpisodeRepositoryRemote(_episodeService);
    _progressRepository = ProgressRepositoryRemote(_progressService);
    _achievementRepository = AchievementRepositoryRemote(_achievementService);
    _assetRepository = AssetRepositoryRemote(_assetService);
    _viewModel = GameViewModel(_episodeRepository, _progressRepository, _achievementRepository);
    _viewModel.loadEpisode(widget.episode.id, startFromBeginning: widget.startFromBeginning);
    _loadAssets();
  }

  @override
  void dispose() {
    _episodeService.close();
    _progressService.close();
    _achievementService.close();
    _assetService.close();
    _viewModel.dispose();
    super.dispose();
  }

  // Загрузка всех ассетов в кэш
  Future<void> _loadAssets() async {
    try {
      final backgrounds = await _assetRepository.getAssets('background');
      for (final a in backgrounds) {
        if (a.fileData.isNotEmpty) {
          _backgroundsCache[a.name] = Uint8List.fromList(a.fileData);
        }
      }

      final characters = await _assetRepository.getAssets('character');
      for (final a in characters) {
        if (a.fileData.isNotEmpty) {
          final key = a.emotion.isEmpty ? a.name : '${a.name}_${a.emotion}';
          _charactersCache[key] = Uint8List.fromList(a.fileData);
        }
      }

      if (!mounted) return;
      setState(() {
        _assetsLoaded = true;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки ассетов: $e');
      if (!mounted) return;
      setState(() {
        _assetsLoaded = true;
      });
    }
  }

  // Получаю Alignment для позиции
  Alignment _getAlignment(String position) {
    switch (position) {
      case 'top_left': return Alignment.topLeft;
      case 'top_center':
      case 'top': return Alignment.topCenter;
      case 'top_right': return Alignment.topRight;
      case 'center_left':
      case 'left': return Alignment.centerLeft;
      case 'center_right':
      case 'right': return Alignment.centerRight;
      case 'bottom_left': return Alignment.bottomLeft;
      case 'bottom_center':
      case 'bottom': return Alignment.bottomCenter;
      case 'bottom_right': return Alignment.bottomRight;
      case 'center':
      default: return Alignment.center;
    }
  }

  // Отступы для текста (чтобы не пересекаться с кнопками)
  EdgeInsets _getTextPadding(String position) {
    if (position.startsWith('top')) {
      return const EdgeInsets.only(top: 70, left: 16, right: 16, bottom: 16);
    }
    if (position.startsWith('bottom')) {
      return const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 90);
    }
    return const EdgeInsets.all(16);
  }

  Uint8List? _getBackgroundBytes(String background) {
    if (background.isEmpty) return null;
    return _backgroundsCache[background];
  }

  Uint8List? _getCharacterBytes(String character, String emotion) {
    if (character.isEmpty) return null;
    final keyWithEmotion = emotion.isEmpty ? character : '${character}_$emotion';
    if (_charactersCache.containsKey(keyWithEmotion)) {
      return _charactersCache[keyWithEmotion];
    }
    return _charactersCache[character];
  }

  String _getCharacterName(String character) {
    switch (character) {
      case 'marinet': return 'Маринетт';
      case 'adrian': return 'Адриан';
      case 'cat': return 'Супер-Кот';
      case 'ladybug': return 'Леди Баг';
      case 'luka': return 'Лука';
      case 'mama': return 'Мама';
      case 'grandpa': return 'Дедушка';
      default: return character;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;

          if (state.isLoading || !_assetsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Text(
                'Ошибка: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final scene = _viewModel.currentScene;

          if (scene == null) {
            return const Center(
              child: Text(
                'Нет сцены',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final bgBytes = _getBackgroundBytes(scene.background);
          final charBytes = _getCharacterBytes(scene.character, scene.characterEmotion);
          final charName = _getCharacterName(scene.character);

          return GestureDetector(
            onTap: () {
              if (_viewModel.hasMoreTexts) {
                _viewModel.nextText();
              }
            },
            child: Stack(
              children: [
                // Фон сцены
                Positioned.fill(
                  child: bgBytes == null
                      ? Container(color: const Color(0xFF333333))
                      : Image.memory(
                          bgBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: const Color(0xFF333333));
                          },
                        ),
                ),
                // Затемнение снизу
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
                // Персонаж
                if (charBytes != null)
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    bottom: 200,
                    child: Align(
                      alignment: _getAlignment(
                        scene.characterPosition.isNotEmpty
                            ? scene.characterPosition
                            : 'center',
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 0.55,
                        heightFactor: 0.55,
                        child: Image.memory(
                          charBytes,
                          fit: BoxFit.contain,
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
                // Текст (с отступами)
                Align(
                  alignment: _getAlignment(
                    scene.textPosition.isNotEmpty
                        ? scene.textPosition
                        : 'bottom_center',
                  ),
                  child: Padding(
                    padding: _getTextPadding(
                      scene.textPosition.isNotEmpty
                          ? scene.textPosition
                          : 'bottom_center',
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                // Выборы - внизу экрана
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
                // Кнопка дальше - внизу экрана
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