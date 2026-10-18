import '../src/data/services/rpc_policy.dart';
import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import 'episode_editor_screen.dart'; // Импорт экрана редактирования эпизода
import '../src/data/services/episode_grpc_service.dart'; // Импорт gRPC-сервиса эпизодов
import '../src/data/services/admin_grpc_service.dart'; // Импорт gRPC-сервиса админа
import '../src/data/repositories/admin_repository_remote.dart'; // Импорт админ-репозитория

// Экран режима разработчика
class ProgrammerScreen extends StatefulWidget {
  const ProgrammerScreen({super.key});

  @override
  State<ProgrammerScreen> createState() => _ProgrammerScreenState();
}

class _ProgrammerScreenState extends State<ProgrammerScreen> {
  List<Episode> _episodes = []; // Список эпизодов

  late EpisodeGrpcService _service; // gRPC-сервис эпизодов
  late AdminGrpcService _adminService; // gRPC-сервис админа
  late AdminRepositoryRemote _adminRepository; // Админ-репозиторий

  bool _isLoading = true; // Флаг загрузки
  String? _error; // Ошибка

  @override
  void initState() {
    super.initState();
    // Создаю сервисы
    _service = EpisodeGrpcService();
    _adminService = AdminGrpcService();
    _adminRepository = AdminRepositoryRemote(_adminService);
    // Загружаю эпизоды
    _loadEpisodes();
  }

  @override
  void dispose() {
    // Закрываю соединения
    _service.close();
    _adminService.close();
    super.dispose();
  }

  // Загрузка эпизодов с сервера
  Future<void> _loadEpisodes() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final episodes = await _service.getAllEpisodes();
      if (!mounted) return;
      setState(() {
        _episodes = List.from(episodes); // Создаю новый список
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = networkError(e);
        _isLoading = false;
      });
      // Показываю SnackBar с ошибкой
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки эпизодов: ${networkError(e)}')),
      );
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
      _episodes = List.from(_episodes)..add(newEpisode);
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
        SnackBar(content: Text('Ошибка: ${networkError(e)}')),
      );
    }
  }

  // Открыть редактор эпизода
  Future<void> _openEditor(int index) async {
    final episode = _episodes[index];

    try {
      // Загружаю полный эпизод
      final fullEpisode = await _service.getEpisode(episode.id);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EpisodeEditorScreen(
            episode: fullEpisode,
            onSave: (newEpisode) async {
              final response = await _service.saveEpisode(newEpisode);
              if (!response.success) throw StateError(response.message);
              final saved = await _service.getEpisode(newEpisode.id);
              if (mounted) {
                setState(() {
                  _episodes = _episodes.map((item) => item.id == saved.id ? saved : item).toList();
                });
              }
              return saved;
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки эпизода: ${networkError(e)}')),
      );
    }
  }

  // Удаление эпизода (через АДМИН-репозиторий)
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

      // Вызываю АДМИН-репозиторий (проверка прав на сервере)
      bool success;
      try {
        success = await _adminRepository.deleteEpisode(episodeId);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(networkError(e))));
        return;
      }

      if (!mounted) return;

      if (success) {
        setState(() {
          final newList = List<Episode>.from(_episodes);
          newList.removeAt(index);
          _episodes = newList;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Эпизод удалён с сервера')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет прав на удаление (только админ)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Фон
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1A1A),
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
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFFD30010), size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Клуб романтики',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
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
                            'РЕЖИМ\nРАЗРАБОТЧИКА',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
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
                                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                                        Text('Ошибка: $_error', style: const TextStyle(color: Colors.red)),
                                        TextButton(onPressed: _loadEpisodes, child: const Text('Повторить')),
                                      ]),
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