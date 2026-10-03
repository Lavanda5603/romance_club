import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import 'episode_editor_screen.dart'; // Импорт экрана редактирования эпизода
import '../src/data/services/episode_grpc_service.dart'; // Импорт gRPC-сервиса

// Экран режима разработчика
class ProgrammerScreen extends StatefulWidget {
  // Конструктор класса ProgrammerScreen
  const ProgrammerScreen({super.key});

  // Метод createState (создание объекта состояния)
  @override
  State<ProgrammerScreen> createState() => _ProgrammerScreenState();
}

class _ProgrammerScreenState extends State<ProgrammerScreen> {
  final List<Episode> _episodes = []; // Список эпизодов (Protobuf-модели)

  // gRPC-сервис
  late EpisodeGrpcService _service;

  // Флаг загрузки
  bool _isLoading = true;

  // Ошибка
  String? _error;

  @override
  void initState() {
    super.initState();
    // Создаю gRPC-сервис
    _service = EpisodeGrpcService();
    // Загружаю эпизоды при открытии экрана
    _loadEpisodes();
  }

  @override
  void dispose() {
    // Закрываю соединение
    _service.close();
    super.dispose();
  }

  // Загрузка эпизодов с сервера
  Future<void> _loadEpisodes() async {
    try {
      final episodes = await _service.getAllEpisodes();
      setState(() {
        _episodes.clear();
        _episodes.addAll(episodes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Добавление нового эпизода
  Future<void> _addEpisode() async {
    // ID нового эпизода = максимальный + 1
    final nextId = _episodes.isEmpty
        ? 1
        : _episodes.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;

    final newEpisode = Episode(
      id: nextId,
      title: 'эпизод $nextId',
      version: 1,
    );

    setState(() {
      _episodes.add(newEpisode);
    });

    try {
      await _service.saveEpisode(newEpisode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Эпизод создан на сервере')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  // Открыть редактор эпизода (с полной загрузкой)
  Future<void> _openEditor(int index) async {
    final episode = _episodes[index];

    try {
      // Загружаю полный эпизод со сценами
      final fullEpisode = await _service.getEpisode(episode.id);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EpisodeEditorScreen(
            episode: fullEpisode,
            onSave: (newEpisode) async {
              setState(() {
                _episodes[index] = newEpisode;
              });
              try {
                await _service.saveEpisode(newEpisode);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar( // ignore: use_build_context_synchronously
                  const SnackBar(content: Text('Эпизод сохранён на сервере')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar( // ignore: use_build_context_synchronously
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки эпизода: $e')),
      );
    }
  }

  // Удаление эпизода
  Future<void> _deleteEpisode(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить эпизод?'),
          content: Text(
            'Вы точно уверены, что хотите удалить "${_episodes[index].title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final episodeId = _episodes[index].id;

      try {
        await _service.deleteEpisode(episodeId);
        if (!mounted) return;
        setState(() {
          _episodes.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Эпизод удалён с сервера')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          Navigator.pop(context);
                        },
                      ),
                      
                      // Заголовок
                      const Text(
                        'Клуб романтики',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      
                      // Пустой контейнер для симметрии (чтобы заголовок был по центру)
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Основной блок
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20), // Отступы по бокам
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Прижимаю всё влево
                      children: [
                        // Заголовок
                        const Center( // Центрирую только заголовок
                          child: Text(
                            'РЕЖИМ\nРАЗРАБОТЧИКА',
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
                        
                        // Подзаголовок
                        const Text(
                          'список эпизодов:',
                          style: TextStyle(
                            color: Color(0xFFFFA0A0), 
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Список эпизодов
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD30010)))
                              : _error != null
                                  ? Center(
                                      child: Text(
                                        'Ошибка: $_error',
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    )
                                  : _episodes.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'нет эпизодов',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: _episodes.length,
                                          itemBuilder: (context, index) {
                                            final episode = _episodes[index];
                                            // Кастомный виджет для строки эпизода
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              child: Row(
                                                children: [
                                                  // Название и ID
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          episode.title,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        // ID с отступом слева
                                                        Padding(
                                                          padding: const EdgeInsets.only(left: 8),
                                                          child: Text(
                                                            'ID: ${episode.id}',
                                                            style: const TextStyle(
                                                              color: Color(0xFFFFA0A0),
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Кнопка редактирования
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.white, size: 24),
                                                    onPressed: () => _openEditor(index),
                                                  ),
                                                  // Кнопка удаления
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                                                    onPressed: () => _deleteEpisode(index),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                        ),
                        
                        const SizedBox(height: 4),

                        // Кнопка создать эпизод
                        SizedBox(
                          width: 260,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _addEpisode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD30010),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'создать эпизод',
                              style: TextStyle(
                                color: Color(0xFF3F0404),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),

                        // Кнопка сохранить
                        SizedBox(
                          width: 200,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              // Логика сохранения
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Сохранено!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD30010),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'сохранить',
                              style: TextStyle(
                                color: Color(0xFF3F0404),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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