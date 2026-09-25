import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели
import 'episode_editor_screen.dart'; // ЭИмпорт экрана редактора
import '../services/storage_service.dart'; // Испорт сервиса хранения

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

  @override
  void initState() {
    super.initState();
    // Загружаю эпизоды при открытии экрана
    _loadEpisodes();
  }

  // Загрузка эпизодов из файла
  Future<void> _loadEpisodes() async {
    final episodes = await StorageService.loadEpisodes();
    setState(() {
      _episodes.clear(); // Очищаю текущий список
      _episodes.addAll(episodes); // Добавляю загруженные эпизоды
    });
  }

  // Добавление нового эпизода
  Future<void> _addEpisode() async {
    // Protobuf-модель создаётся так
    final newEpisode = Episode(
      id: _episodes.length + 1, // Id нового эпизода
      title: 'Эпизод ${_episodes.length + 1}', // Название
      version: 1, // Версия
    );
    
    setState(() {
      _episodes.add(newEpisode);
    });
    
    await StorageService.saveEpisodes(_episodes); // Сохраняю
  }

  // Удаление эпизода
  Future<void> _deleteEpisode(int index) async {
    // Показываю диалог подтверждения
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
              onPressed: () => Navigator.pop(context, false), // Отмена
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Подтверждение
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    // Если пользователь подтвердил, удаляю эпизод
    if (confirmed == true) {
      setState(() {
        _episodes.removeAt(index);
      });
      await StorageService.saveEpisodes(_episodes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Режим разработчика'), // Заголовок экрана
      ),
      body: Column(
        children: [
          // Кнопка создания эпизода
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _addEpisode,
              child: const Text('Создать эпизод'),
            ),
          ),
          // Список эпизодов
          Expanded(
            child: _episodes.isEmpty
                ? const Center(child: Text('Нет эпизодов')) // Если эпизодов нет
                : ListView.builder(
                    itemCount: _episodes.length,
                    itemBuilder: (context, index) {
                      final episode = _episodes[index];
                      return ListTile(
                        title: Text(episode.title), // Название эпизода
                        subtitle: Text('Сцен: ${episode.scenes.length}'), // Количество сцен
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Кнопка редактирования эпизода
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EpisodeEditorScreen(
                                      episode: episode,
                                      onSave: (newEpisode) async {
                                        setState(() {
                                          _episodes[index] = newEpisode; // Обновляю эпизод в списке
                                        });
                                        await StorageService.saveEpisodes(_episodes); // Сохраняю
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Кнопка удаления эпизода
                            IconButton(
                              icon: const Icon(Icons.delete),
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
        ],
      ),
    );
  }
}