import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../generated/scene.pb.dart'; // Импорт Protobuf-модели Scene
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
  late TextEditingController _titleController;

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
      // Создаю Protobuf-модель Scene
      final newScene = Scene(
        id: widget.episode.scenes.length + 1, // Id новой сцены
        background: '', // Фон
        character: '', // Персонаж
        condition: '', // Условие
      );

      // Добавляю в список (repeated)
      widget.episode.scenes.add(newScene);
    });
  }

  // Удаление сцены
  Future<void> _deleteScene(int index) async {
    // Показываю диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog( // Всплывающее окно
          title: const Text('Удалить сцену?'),
          content: Text(
            'Вы точно уверены, что хотите удалить "Сцена ${widget.episode.scenes[index].id}"?',
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

    // Если пользователь подтвердил, удаляю сцену
    if (confirmed == true) {
      setState(() {
        widget.episode.scenes.removeAt(index);
      });
    }
  }

  // Сохранение эпизода
  void _saveEpisode() {
    // Обновляю название
    widget.episode.title = _titleController.text;

    // Вызываю функцию onSave
    widget.onSave(widget.episode);

    // Показываю уведомление о сохранении
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Эпизод сохранён')),
    );
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
              'РЕДАКТИРОВАНИЕ ЭПИЗОДА',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            // Подпись (серая)
            const Align( // Выравнивание
              alignment: Alignment.centerLeft,
              child: Text(
                'название эпизода',
                style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 16),
              ),
            ),
            const SizedBox(height: 4),
            // Поле ввода названия эпизода (розовая)
            TextField( // Поле ввода
              controller: _titleController, // Контроллер
              style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 18), // Розовый текст
              decoration: const InputDecoration( // Оформление поля
                border: InputBorder.none, // Без рамки
                isDense: true, // Компактнее
              ),
            ),
            const SizedBox(height: 24),
            // Надпись (розовая)
            const Align( // Выравнивание
              alignment: Alignment.centerLeft,
              child: Text(
                'список сцен:',
                style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            // Список сцен
            Expanded( // Растягивание
              child: widget.episode.scenes.isEmpty
                  ? const Center(child: Text('нет сцен', style: TextStyle(color: Colors.white))) // Если сцен нет
                  : ListView.builder( // Список
                      itemCount: widget.episode.scenes.length,
                      itemBuilder: (context, index) {
                        final scene = widget.episode.scenes[index];
                        return ListTile( // Строка списка
                          title: Text('сцена ${scene.id} "..."', style: const TextStyle(color: Colors.white)), // Название сцены
                          subtitle: Text('текстов: ${scene.texts.length}', style: const TextStyle(color: Color(0xFFFFA0A0))), // Количество текстов
                          trailing: Row( // Горизонтальный список (справа)
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Кнопка редактирования сцены
                              IconButton( // Кнопка с иконкой
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: () {
                                  Navigator.push( // Открыть экран
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SceneEditorScreen(
                                        scene: scene,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Кнопка удаления сцены
                              IconButton( // Кнопка с иконкой
                                icon: const Icon(Icons.delete, color: Colors.white),
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
            const SizedBox(height: 16),
            // Кнопка создания сцены
            SizedBox( // Контейнер
              width: double.infinity, // На всю ширину
              child: ElevatedButton( // Кнопка с фоном
                onPressed: _addScene,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD30010),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'создать сцену',
                  style: TextStyle(color: Color(0xFF3F0404), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Кнопка сохранения
            SizedBox( // Контейнер
              width: double.infinity, // На всю ширину
              child: ElevatedButton( // Кнопка с фоном
                onPressed: _saveEpisode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'сохранить',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}