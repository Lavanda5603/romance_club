import 'package:flutter/material.dart';
import '../models/episode.dart';
import '../models/scene.dart';
import 'scene_editor_screen.dart';

class EpisodeEditorScreen extends StatefulWidget {
  final Episode episode;
  final Function(Episode) onSave;

  const EpisodeEditorScreen({
    super.key,
    required this.episode,
    required this.onSave,
  });

  @override
  State<EpisodeEditorScreen> createState() => _EpisodeEditorScreenState();
}

class _EpisodeEditorScreenState extends State<EpisodeEditorScreen> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.episode.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addScene() {
    setState(() {
      widget.episode.scenes.add(
        Scene(
          id: widget.episode.scenes.length + 1,
          background: '',
          character: '',
          texts: [],
          choices: [],
        ),
      );
    });
  }

  Future<void> _deleteScene(int index) async {
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
      setState(() {
        widget.episode.scenes.removeAt(index);
      });
    }
  }

  void _saveEpisode() {
    final newEpisode = Episode(
      id: widget.episode.id,
      title: _titleController.text,
      scenes: widget.episode.scenes,
    );

    widget.onSave(newEpisode);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Эпизод сохранен')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.episode.title),
      ),
      body: Column(
        children: [
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _addScene,
              child: const Text('Создать сцену'),
            ),
          ),
          Expanded(
            child: widget.episode.scenes.isEmpty
                ? const Center(
                    child: Text('Нет сцен'),
                  )
                : ListView.builder(
                    itemCount: widget.episode.scenes.length,
                    itemBuilder: (context, index) {
                      final scene = widget.episode.scenes[index];
                      return ListTile(
                        title: Text('Сцена ${scene.id}'),
                        subtitle: Text('Текстов: ${scene.texts.length}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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