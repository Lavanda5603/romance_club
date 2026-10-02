import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../src/data/repositories/episode_repository_remote.dart'; // Импорт репозитория
import '../src/data/services/episode_grpc_service.dart'; // Импорт gRPC-сервиса
import '../src/features/game/game_view_model.dart'; // Импорт ViewModel

// Игровой экран
class GameScreen extends StatefulWidget {
  final Episode episode; // Эпизод (Protobuf)

  // Конструктор класса GameScreen
  const GameScreen({
    super.key,
    required this.episode,
  });

  // Метод createState (создание объекта состояния)
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameViewModel _viewModel; // ViewModel
  late EpisodeGrpcService _service; // gRPC-сервис
  late EpisodeRepositoryRemote _repository; // Репозиторий

  @override
  void initState() {
    super.initState();
    // Создаю gRPC-сервис (пока не используется для локального режима)
    _service = EpisodeGrpcService();
    // Создаю репозиторий
    _repository = EpisodeRepositoryRemote(_service);
    // Создаю ViewModel
    _viewModel = GameViewModel(_repository);
    // Загружаю эпизод из Protobuf (локальный режим)
    final domainEpisode = _repository.toDomain(widget.episode);
    _viewModel.loadEpisodeFromProto(domainEpisode);
  }

  @override
  void dispose() {
    // Закрываю соединение и освобождаю ресурсы
    _service.close();
    _viewModel.dispose();
    super.dispose();
  }

  // Получаю Alignment для позиции
  Alignment _getAlignment(String position) {
    switch (position) {
      case 'top':
        return Alignment.topCenter;
      case 'bottom':
        return Alignment.bottomCenter;
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Каркас экрана
      backgroundColor: const Color(0xFF1A1A1A), // Фон экрана
      appBar: AppBar( // Верхняя панель
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton( // Кнопка с иконкой
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD30010)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text( // Текст (маленький, в AppBar)
          'Клуб романтики',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
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

          // Основной интерфейс
          return Stack( // Стопка виджетов
            children: [
              // Фон сцены
              Container(
                decoration: const BoxDecoration(color: Color(0xFF333333)),
              ),
              // Персонаж (если есть)
              if (scene.character.isNotEmpty)
                Align( // Выравнивание
                  alignment: _getAlignment(
                    scene.characterPosition.isNotEmpty
                        ? scene.characterPosition
                        : 'center',
                  ),
                  child: FractionallySizedBox( // Размер в долях
                    widthFactor: 0.65,
                    heightFactor: 0.65,
                    child: Icon(Icons.person, size: 300, color: Colors.red[300]),
                  ),
                ),
              // Текст и выборы
              Align( // Выравнивание
                alignment: _getAlignment(
                  scene.textPosition.isNotEmpty
                      ? scene.textPosition
                      : 'bottom',
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Текст сцены (розовое облачко)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA0A0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          scene.texts.isNotEmpty
                              ? scene.texts.first
                              : 'нет текста',
                          style: const TextStyle(
                            color: Color(0xFF7E7E7E),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Выборы (динамические)
                      ...scene.choices.asMap().entries.map((entry) {
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
                                        color: Color(0xFF7E7E7E),
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
                      }),
                    ],
                  ),
                ),
              ),
              // Баллы (вверху справа)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F0404),
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
              ),
            ],
          );
        },
      ),
    );
  }
}