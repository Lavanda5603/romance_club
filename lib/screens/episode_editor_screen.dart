import 'package:flutter/material.dart'; // Импорт Material UI
import '../models/episode.dart'; // Импорт класса Episode
import '../models/scene.dart'; // Импорт класса Scene
import 'scene_editor_screen.dart'; // Импорт экрана редактирования сцены

// Экран редактирования эпизода
class EpisodeEditorScreen extends StatefulWidget {
  final Episode episode; // Эпизод
  final Function(Episode) onSave; // Функция, вызывается при сохранении эпизода

  // Конструктор класса EpisodeEditorScreen
  const EpisodeEditorScreen({
    super.key,
    required this.episode,
    required this.onSave,
  });

  // Метод createState (создание объекта состояния)
  @override
  State<EpisodeEditorScreen> createState() => _EpisodeEditorScreenState();
}

class _EpisodeEditorScreenState extends State<EpisodeEditorScreen> {
  late TextEditingController _titleController; // Контроллер для поля ввода названия эпизода

  @override
  void initState() {
    super.initState();
    // Создание контроллера и заполнение его текущим названием эпизода
    _titleController = TextEditingController(text: widget.episode.title);
  }

  @override
  void dispose() {
    // Освобождение ресурса контроллера при закрытии экрана
    _titleController.dispose();
    super.dispose();
  }

  // Добавление новой сцены в эпизод
  void _addScene() {
    setState(() {
      widget.episode.scenes.add(
        Scene(
          id: widget.episode.scenes.length + 1, // Id новой сцены
          background: '', // Фон 
          character: '', // Персонаж
          texts: [], // Тексты
          choices: [], // Выборы
        ),
      );
    });
  }

  // Удаление сцены
  Future<void> _deleteScene(int index) async {
    // Показываю диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить сцену?'),
          content: Text(
            'Вы точно уверены, что хотите удалить "Сцена ${widget.episode.scenes[index].id}"?',
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

    // Если пользователь подтвердил, удаляю сцену
    if (confirmed == true) {
      setState(() {
        widget.episode.scenes.removeAt(index);
      });
    }
  }

  // Сохранение эпизода
  void _saveEpisode() {
    // Создаю новый объект Episode с обновлёнными данными
    final newEpisode = Episode(
      id: widget.episode.id,
      title: _titleController.text, // Беру название из поля ввода
      scenes: widget.episode.scenes, // Сцены беру из текущего эпизода
    );

    // Вызываю функцию onSave
    widget.onSave(newEpisode);

    // Показываю уведомление о сохранении
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Эпизод сохранен')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.episode.title), // Заголовок (название эпизода)
      ),
      body: Column(
        children: [
          // Поле ввода названия эпизода
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название эпизода',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Кнопка создания сцены
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _addScene,
              child: const Text('Создать сцену'),
            ),
          ),
          // Список сцен
          Expanded(
            child: widget.episode.scenes.isEmpty
                ? const Center(
                    child: Text('Нет сцен'), // Если сцен нет
                  )
                : ListView.builder(
                    itemCount: widget.episode.scenes.length,
                    itemBuilder: (context, index) {
                      final scene = widget.episode.scenes[index];
                      return ListTile(
                        title: Text('Сцена ${scene.id}'), // Название сцены
                        subtitle: Text('Текстов: ${scene.texts.length}'), // Количество текстов
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Кнопка редоктирования сцены
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SceneEditorScreen(
                                      episode: widget.episode,
                                      scene: scene,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Кнопка удаления сцены
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _deleteScene(index);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Кнопка сохранения
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveEpisode,
              child: const Text('Сохранить'),
            ),
          ),
        ],
      ),
    );
  }
}