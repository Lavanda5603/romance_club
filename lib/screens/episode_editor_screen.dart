import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../generated/scene.pb.dart'; // Импорт Protobuf-модели Scene
import 'scene_editor_screen.dart'; // Импорт экрана редактирования сцены

// Экран редактирования эпизода
class EpisodeEditorScreen extends StatefulWidget {
  final Episode episode; // Эпизод
  final Function(Episode) onSave; // Функция, вызывается при сохранении

  // Конструктор класса EpisodeEditorScreen
  const EpisodeEditorScreen({
    super.key,
    required this.episode,
    required this.onSave,
  });

  // Метод createState
  @override
  State<EpisodeEditorScreen> createState() => _EpisodeEditorScreenState();
}

class _EpisodeEditorScreenState extends State<EpisodeEditorScreen> {
  late TextEditingController _titleController; // Контроллер названия

  @override
  void initState() {
    super.initState();
    // Создаю контроллер и заполняю текущим названием
    _titleController = TextEditingController(text: widget.episode.title);
  }

  @override
  void dispose() {
    // Освобождаю контроллер
    _titleController.dispose();
    super.dispose();
  }

  // Добавить новую сцену
  void _addScene() {
    setState(() {
      // Создаю Protobuf-модель Scene
      final newScene = Scene(
        id: widget.episode.scenes.length + 1, // ID новой сцены
        title: 'сцена ${widget.episode.scenes.length + 1}', // Название по умолчанию
        background: '', // Фон
        character: '', // Персонаж
        characterEmotion: '', // Эмоция
        condition: '', // Условие
        characterPosition: 'center', // Позиция персонажа
        textPosition: 'bottom_center', // Позиция текста
      );

      // Добавляю в список
      widget.episode.scenes.add(newScene);

      // Добавила сцену
      debugPrint('[FLUTTER] Добавлена сцена: ${newScene.title}, всего сцен: ${widget.episode.scenes.length}');
    });
  }

  // Удалить сцену
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

    // Если подтвердил — удаляю
    if (confirmed == true) {
      setState(() {
        widget.episode.scenes.removeAt(index);
      });
    }
  }

  // Сохранить эпизод
  void _saveEpisode() {
    // Обновляю название
    widget.episode.title = _titleController.text;

    // Сохраняю
    debugPrint('[FLUTTER] _saveEpisode: ${widget.episode.title}, сцен: ${widget.episode.scenes.length}');

    // Вызываю колбэк
    widget.onSave(widget.episode);

    // Показываю уведомление
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Эпизод сохранён')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1A1A),
              child: Image.asset(
                'assets/images/main_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'РЕДАКТИРОВАНИЕ\nЭПИЗОДА',
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
                        const Text(
                          'название эпизода',
                          style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 18),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'список сцен:',
                          style: TextStyle(
                            color: Color(0xFFFFA0A0),
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 10),
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
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.white, size: 24),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => SceneEditorScreen(
                                                    scene: scene,
                                                    episodeId: 'episode:${widget.episode.id}',
                                                    allScenes: widget.episode.scenes, // Передаю все сцены эпизода
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
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                                            onPressed: () => _deleteScene(index),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 4),
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