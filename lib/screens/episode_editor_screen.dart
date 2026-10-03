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
        title: 'сцена ${widget.episode.scenes.length + 1}', // Название по умолчанию
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
                      
                      // Пустой контейнер для симметрии
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Основноц блок
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20), // Отступы по бокам
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Прижимаю всё влево
                      children: [
                        // Заголовок
                        const Center(
                          child: Text(
                            'РЕДАКТИРОВАНИЕ\nЭПИЗОДА',
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
                        
                        // Подпись
                        const Text(
                          'название эпизода',
                          style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        
                        // Поле ввода названия эпизода (розовый текст)
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 18),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Подзаголовок
                        const Text(
                          'список сцен:',
                          style: TextStyle(
                            color: Color(0xFFFFA0A0), 
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Список сцен
                        Expanded(
                          child: widget.episode.scenes.isEmpty
                              ? const Center(
                                  child: Text(
                                    'нет сцен', 
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: widget.episode.scenes.length,
                                  itemBuilder: (context, index) {
                                    final scene = widget.episode.scenes[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          // Название сцены
                                          Expanded(
                                            child: Text(
                                              scene.title.isNotEmpty
                                                  ? scene.title
                                                  : 'сцена ${scene.id}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          // Кнопка редактирования
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.white, size: 24),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => SceneEditorScreen(
                                                    scene: scene,
                                                    onSave: (newScene) {
                                                      setState(() {
                                                        widget.episode.scenes[index] = newScene;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          // Кнопка удаления
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
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
                        
                        const SizedBox(height: 4),

                        // Кнопка создать сцену
                        SizedBox(
                          width: 260,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _addScene,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD30010),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'создать сцену',
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
                            onPressed: _saveEpisode,
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