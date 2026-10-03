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
      // Запрашиваю эпизоды с сервера
      final episodes = await _service.getAllEpisodes();
      setState(() {
        _episodes.clear(); // Очищаю текущий список
        _episodes.addAll(episodes); // Добавляю загруженные эпизоды
        _isLoading = false; // Загрузка завершена
      });
    } catch (e) {
      setState(() {
        _error = e.toString(); // Сохраняю ошибку
        _isLoading = false; // Загрузка завершена
      });
    }
  }

  // Добавление нового эпизода
  Future<void> _addEpisode() async {
    // Создаю Protobuf-модель Episode
    final newEpisode = Episode(
      id: _episodes.length + 1, // Id нового эпизода
      title: 'эпизод ${_episodes.length + 1}', // Название
      version: 1, // Версия
    );

    // Добавляю в список
    setState(() {
      _episodes.add(newEpisode);
    });

    // Сохраняю на сервер
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

  // Удаление эпизода
  Future<void> _deleteEpisode(int index) async {
    // Показываю диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog( // Всплывающее окно
          title: const Text('Удалить эпизод?'),
          content: Text(
            'Вы точно уверены, что хотите удалить "${_episodes[index].title}"?',
          ),
          actions: [
            TextButton( // Кнопка без фона
              onPressed: () => Navigator.pop(context, false), // Отмена
              child: const Text('Отмена'),
            ),
            TextButton( // Кнопка без фона
              onPressed: () => Navigator.pop(context, true), // Подтверждение
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    // Если пользователь подтвердил, удаляю эпизод
    if (confirmed == true) {
      final episodeId = _episodes[index].id; // ID эпизода

      try {
        // Удаляю с сервера
        await _service.deleteEpisode(episodeId);

        if (!mounted) return;
        setState(() {
          _episodes.removeAt(index); // Удаляю из локального списка
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
    return Scaffold( // Каркас экрана
      backgroundColor: const Color(0xFF1A1A1A), // Фон экрана
      appBar: AppBar( // Верхняя панель
        backgroundColor: Colors.transparent, // Прозрачный фон
        elevation: 0, // Без тени
        leading: IconButton( // Кнопка с иконкой
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD30010)), // Кнопка назад
          onPressed: () {
            Navigator.pop(context); // Закрыть экран
          },
        ),
        title: const Text( // Текст (маленький, в AppBar)
          'Клуб романтики',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true, // По центру
      ),
      body: Padding( // Отступы
        padding: const EdgeInsets.all(16),
        child: Column( // Вертикальный список
          children: [
            const Text( // Большой заголовок
              'РЕЖИМ РАЗРАБОТЧИКА',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24), // Отступ
            const Align( // Выравнивание
              alignment: Alignment.centerLeft, // По левому краю
              child: Text( // Текст
                'список эпизодов:',
                style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
              ),
            ),
            const SizedBox(height: 8), // Отступ
            Expanded( // Растягивание
              child: _isLoading
                  // Загрузка
                  ? const Center(child: CircularProgressIndicator())
                  // Ошибка
                  : _error != null
                      ? Center(
                          child: Text(
                            'Ошибка: $_error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      // Пустой список
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
                                return ListTile( // Строка списка
                                  title: Text(episode.title, style: const TextStyle(color: Colors.white)),
                                  subtitle: Text('сцен: ${episode.scenes.length}', style: const TextStyle(color: Color(0xFFFFA0A0))),
                                  trailing: Row( // Горизонтальный список (справа)
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Кнопка редактирования эпизода
                                      IconButton( // Кнопка с иконкой
                                        icon: const Icon(Icons.edit, color: Colors.white),
                                        onPressed: () {
                                          Navigator.push( // Открыть экран
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EpisodeEditorScreen(
                                                episode: episode,
                                                onSave: (newEpisode) async {
                                                  setState(() {
                                                    _episodes[index] = newEpisode; // Обновляю эпизод в списке
                                                  });
                                                  // Сохраняю на сервер
                                                  try {
                                                    await _service.saveEpisode(newEpisode);
                                                    if (!context.mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Эпизод сохранён на сервере')),
                                                    );
                                                  } catch (e) {
                                                    if (!context.mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Ошибка: $e')),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Кнопка удаления эпизода
                                      IconButton( // Кнопка с иконкой
                                        icon: const Icon(Icons.delete, color: Colors.white),
                                        onPressed: () {
                                          _deleteEpisode(index);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
            const SizedBox(height: 16), // Отступ
            SizedBox( // Контейнер
              width: double.infinity, // На всю ширину
              child: ElevatedButton( // Кнопка с фоном
                onPressed: _addEpisode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD30010),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'создать эпизод',
                  style: TextStyle(color: Color(0xFF3F0404), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}