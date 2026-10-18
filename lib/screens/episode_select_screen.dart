import 'package:grpc/grpc.dart';
import '../src/data/services/rpc_policy.dart';
import '../src/domain/repositories/progress_repository.dart';
import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../src/data/repositories/progress_repository_remote.dart'; // Импорт репозитория прогресса
import '../src/data/services/episode_grpc_service.dart'; // Импорт gRPC-сервиса эпизодов
import '../src/data/services/progress_grpc_service.dart'; // Импорт gRPC-сервиса прогресса
import '../services/storage_service.dart'; // Импорт сервиса хранения
import 'game_screen.dart'; // Импорт игрового экрана
import 'main_menu_screen.dart'; // Импорт главного меню

// Экран выбора эпизода
class EpisodeSelectScreen extends StatefulWidget {
  // Конструктор класса EpisodeSelectScreen
  final EpisodeGrpcService? episodeService;
  final ProgressRepository? progressRepository;
  final Future<String> Function()? loadPlayerId;
  const EpisodeSelectScreen({super.key, this.episodeService, this.progressRepository, this.loadPlayerId});

  // Метод createState (создание объекта состояния)
  @override
  State<EpisodeSelectScreen> createState() => _EpisodeSelectScreenState();
}

class _EpisodeSelectScreenState extends State<EpisodeSelectScreen> {
  // Список эпизодов (Protobuf-модели)
  final List<Episode> _episodes = [];

  // Эпизоды с сохранённым прогрессом (по ID)
  final Set<int> _passedEpisodes = {};

  // Выбранный эпизод
  int _selectedIndex = 0;

  // Флаг загрузки
  bool _isLoading = true;

  // Ошибка загрузки
  String? _error;

  // gRPC-сервис эпизодов
  late EpisodeGrpcService _episodeService;

  // gRPC-сервис прогресса
  late ProgressGrpcService _progressService;

  // Репозиторий прогресса
  late ProgressRepository _progressRepository;

  // ID игрока
  String _playerId = '';
  late Future<String> _player;
  bool _progressLoading = true;
  String? _progressError;
  bool _selectionTouched = false;
  int _summaryGeneration = 0;

  @override
  void initState() {
    super.initState();
    // Создаю gRPC-сервисы
    _episodeService = widget.episodeService ?? EpisodeGrpcService();
    _progressService = ProgressGrpcService();
    // Создаю репозиторий прогресса
    _progressRepository = widget.progressRepository ?? ProgressRepositoryRemote(_progressService);
    _player = (widget.loadPlayerId ?? StorageService.loadPlayerId)();
    _loadProgressSummary();
    // Загружаю эпизоды при открытии экрана
    _loadEpisodes();
  }

  @override
  void dispose() {
    // Закрываю соединения
    if (widget.episodeService == null) _episodeService.close();
    _progressService.close();
    super.dispose();
  }

  // Список показываю сразу, сводка загружается независимо
  Future<void> _loadEpisodes() async {
    try {
      final episodes = await _episodeService.getAllEpisodes();
      if (!mounted) return;
      setState(() {
        _episodes.clear();
        _episodes.addAll(episodes);
        _chooseDefaultEpisode();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = networkError(e); _isLoading = false; });
    }
  }

  void _chooseDefaultEpisode() {
    if (_selectionTouched) return;
    _selectedIndex = 0;
    for (var i = 0; i < _episodes.length; i++) {
      if (!_passedEpisodes.contains(_episodes[i].id)) { _selectedIndex = i; break; }
    }
  }

  Future<void> _loadProgressSummary() async {
    final generation = ++_summaryGeneration;
    setState(() { _progressLoading = true; _progressError = null; });
    try {
      final playerId = await _player;
      if (!mounted || generation != _summaryGeneration) return;
      setState(() => _playerId = playerId);
      final ids = playerId.isEmpty ? <int>{} : await _progressRepository.getProgressSummary(playerId);
      if (!mounted || generation != _summaryGeneration) return;
      setState(() {
        _passedEpisodes.clear();
        _passedEpisodes.addAll(ids);
        _progressLoading = false;
        _chooseDefaultEpisode();
      });
    } catch (e) {
      if (!mounted || generation != _summaryGeneration) return;
      setState(() { _progressLoading = false; _progressError = e is GrpcError ? networkError(e) : 'Не удалось загрузить статус эпизодов'; });
    }
  }

  // Сброс прогресса
  Future<void> _resetProgress() async {
    // Показываю диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog( // Всплывающее окно
          title: const Text('Сбросить прогресс?'),
          content: const Text(
            'Вы точно уверены, что хотите сбросить весь прогресс? Это действие нельзя отменить.',
          ),
          actions: [
            TextButton( // Кнопка без фона
              onPressed: () => Navigator.pop(context, false), // Отмена
              child: const Text('Отмена'),
            ),
            TextButton( // Кнопка без фона
              onPressed: () => Navigator.pop(context, true), // Подтверждение
              child: const Text('Сбросить'),
            ),
          ],
        );
      },
    );

     // Если пользователь подтвердил - сбрасываю прогресс
    if (confirmed == true) {
      try {
        // Не применяю старую сводку после сброса
        ++_summaryGeneration;
        if (!await _progressRepository.resetProgress(_playerId)) throw StateError('Не удалось сбросить прогресс');

        if (!mounted) return;

        // После успешного сброса перечитываю состояние сервера
        await _loadProgressSummary();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Прогресс сброшен')),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() { _progressLoading = false; _progressError = 'Не удалось обновить статус эпизодов'; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${networkError(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Каркас экрана
      backgroundColor: const Color(0xFF1A1A1A), // Фон экрана
      
      // Использую Stack, чтобы наложить контент на фон
      body: Stack(
        children: [
          // Слой для фона
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1A1A), // Цвет фона-заглушки
              // Картинка фона
              child: Image.asset(
                'assets/images/main_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Основной контент
          SafeArea(
            child: Column(
              children: [
                // Верхняя панель
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Кнопка назад
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFFD30010), size: 28),
                        onPressed: () {
                          // Переход в главное меню
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const MainMenu()),
                          );
                        },
                      ),
                      
                      // Заголовок
                      const Text(
                        'Клуб романтики',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      
                      // Пустой контейнер для симметрии
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Основной блок
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок
                        const Center(
                          child: Text(
                            'ВЫБОР\nЭПИЗОДА',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w300, // Тонкий шрифт
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_progressLoading)
                          const Text('Статус эпизодов загружается...', style: TextStyle(color: Colors.white)),
                        if (_progressError != null)
                          TextButton(onPressed: _loadProgressSummary, child: Text('$_progressError. Повторить')),
                        // Список эпизодов
                        Expanded(
                          child: _isLoading
                              // Если идёт загрузка
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD30010)))
                              // Если ошибка
                              : _error != null
                                  ? Center(
                                      child: Text(
                                        'Ошибка: $_error',
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    )
                                  // Если эпизодов нет
                                  : _episodes.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'нет эпизодов',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        )
                                      // Список эпизодов
                                      : ListView.builder(
                                          itemCount: _episodes.length,
                                          itemBuilder: (context, index) {
                                            final episode = _episodes[index];
                                            // Эпизод пройден
                                            final isPassed = _passedEpisodes.contains(episode.id);
                                            
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: Center(
                                                child: SizedBox(
                                                  width: 220,
                                                  height: 55,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _selectionTouched = true;
                                                        _selectedIndex = index; // Выбираю эпизод
                                                      });
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      // Красный, если пройден, серый, если нет
                                                      backgroundColor: isPassed 
                                                          ? const Color(0xFFD30010) 
                                                          : const Color(0xFF534F50),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(30),
                                                      ),
                                                      elevation: 0,
                                                    ),
                                                    child: Text(
                                                      episode.title, // Название эпизода
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                        color: Color(0xFF3F0404), 
                                                        fontSize: 18, 
                                                        fontWeight: FontWeight.bold
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                        ),
                        
                        const SizedBox(height: 8),

                        // Кнопка продолжить
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                // Если эпизодов нет - не перехожу
                                if (_episodes.isEmpty) return;

                                _selectionTouched = true;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GameScreen(
                                      episode: _episodes[_selectedIndex], // Передаю выбранный эпизод
                                    ),
                                  )
                                ).then((_) { if (mounted) _loadProgressSummary(); });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD30010),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'продолжить',
                                style: TextStyle(
                                  color: Color(0xFF3F0404), 
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),

                        // Кнопка сбросить прогресс
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _playerId.isEmpty ? null : _resetProgress, // Сброс прогресса
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF534F50), // Серый
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'сбросить\nпрогресс',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF3F0404), // Тёмно-красный
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Пустое пространство снизу, чтобы поднять кнопки выше
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
