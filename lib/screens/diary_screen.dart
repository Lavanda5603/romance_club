import 'package:flutter/material.dart'; // Импорт оформления дневника

import '../services/storage_service.dart'; // Импорт текущего игрока
import '../src/data/services/episode_grpc_service.dart'; // Импорт текста записей из редактора
import '../src/data/services/progress_grpc_service.dart'; // Импорт сохранённых решений
import '../widgets/button_sound.dart'; // Импорт звука кнопок

// Читаю только решения из собственного сохранения каждого эпизода.
class DiaryScreen extends StatefulWidget {
  final Future<Map<String, List<String>>> Function()?
  loadEntries; // Подменяю сеть в тестах
  const DiaryScreen({super.key, this.loadEntries});
  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _episodes = EpisodeGrpcService();
  final _progress = ProgressGrpcService();
  Map<String, List<String>>? _entries;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _episodes.close();
    _progress.close();
    super.dispose();
  }

  Future<Map<String, List<String>>> _read() async {
    final player = await StorageService.loadPlayerId();
    if (player.isEmpty) throw StateError('Сначала войди в аккаунт');
    final episodes = await _episodes.getAllEpisodes();
    episodes.sort((a, b) => a.id.compareTo(b.id));
    final result = <String, List<String>>{};
    // Обрабатываю все ошибки сразу, чтобы параллельные запросы не оставались без обработчиков.
    final pages = await Future.wait(
      episodes.map((episode) async {
        final progress = await _progress.getProgress(player, episode.id);
        if (progress.sceneId.isEmpty) {
          return MapEntry('${episode.id}. ${episode.title}', <String>[]);
        }
        final full = await _episodes.getEpisode(episode.id);
        final seen = <String>{};
        final entries = <String>[];
        for (final scene in full.scenes) {
          for (final choice in scene.choices) {
            for (final action in choice.actions) {
              if (action.flagName.startsWith('diary_') &&
                  progress.flags[action.flagName] == true &&
                  action.title.trim().isNotEmpty &&
                  seen.add(action.flagName)) {
                entries.add(action.title);
              }
            }
          }
        }
        return MapEntry('${episode.id}. ${episode.title}', entries);
      }),
    );
    for (final page in pages) {
      if (page.value.isNotEmpty) result[page.key] = page.value;
    }
    return result;
  }

  Future<void> _load() async {
    setState(() {
      _entries = null;
      _error = null;
    });
    try {
      final entries = await (widget.loadEntries?.call() ?? _read());
      if (mounted) setState(() => _entries = entries);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Не удалось открыть дневник. Проверь подключение.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      title: const Text('Мой дневник'),
      backgroundColor: const Color(0xFF3F0404),
      foregroundColor: Colors.white,
    ),
    body: _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: withButtonSound(_load),
                  child: const Text(
                    'Повторить',
                    style: TextStyle(color: Color(0xFFFFA0A0)),
                  ),
                ),
              ],
            ),
          )
        : _entries == null
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFD30010)),
          )
        : _entries!.isEmpty
        ? const Center(
            child: Text(
              'Здесь появятся твои важные решения',
              style: TextStyle(color: Color(0xFFFFA0A0)),
              textAlign: TextAlign.center,
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final page in _entries!.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    page.key,
                    style: const TextStyle(
                      color: Color(0xFFFFA0A0),
                      fontSize: 20,
                    ),
                  ),
                ),
                for (final text in page.value)
                  Card(
                    color: const Color(0xFF3F0404),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
  );
}