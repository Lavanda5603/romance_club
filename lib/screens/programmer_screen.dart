import 'package:flutter/material.dart';
import '../models/episode.dart';
import 'episode_editor_screen.dart';
import '../services/storage_service.dart';

class ProgrammerScreen extends StatefulWidget {
  const ProgrammerScreen({super.key});

  @override
  State<ProgrammerScreen> createState() => _ProgrammerScreenState();
}

class _ProgrammerScreenState extends State<ProgrammerScreen> {
  final List<Episode> _episodes = [];

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    final episodes = await StorageService.loadEpisodes();
    setState(() {
      _episodes.clear();
      _episodes.addAll(episodes);
    });
  }

  Future<void> _addEpisode() async {
    setState(() {
      _episodes.add(
        Episode(
          id: _episodes.length + 1,
          title: 'Эпизод ${_episodes.length + 1}',
          scenes: [],
        ),
      );
    });
    await StorageService.saveEpisodes(_episodes);
  }

  Future<void> _deleteEpisode(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить эпизод?'),
          content: Text('Вы точно уверены, что хотите удалить "${_episodes[index].title}"?'),
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
        _episodes.removeAt(index);
      });
      await StorageService.saveEpisodes(_episodes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Режим разработчика'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _addEpisode,
              child: const Text('Создать эпизод'),
            ),
          ),
          Expanded(
            child: _episodes.isEmpty
                ? const Center(
                    child: Text('Нет эпизодов'),
                  )
                : ListView.builder(
                    itemCount: _episodes.length,
                    itemBuilder: (context, index) {
                      final episode = _episodes[index];
                      return ListTile(
                        title: Text(episode.title),
                        subtitle: Text('Сцен: ${episode.scenes.length}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                                          _episodes[index] = newEpisode;
                                        });
                                        await StorageService.saveEpisodes(_episodes);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _deleteEpisode(index);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EpisodeEditorScreen(
                                episode: episode,
                                onSave: (newEpisode) async {
                                  setState(() {
                                    _episodes[index] = newEpisode;
                                  });
                                  await StorageService.saveEpisodes(_episodes);
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}