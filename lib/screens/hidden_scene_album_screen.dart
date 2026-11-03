import '../widgets/story_header.dart'; // Импорт общей шапки и тонкого заголовка

import 'package:flutter/material.dart'; // Импорт экрана альбома

import '../services/storage_service.dart'; // Импорт текущего игрока
import '../services/active_novel.dart'; // Импорт разговоров выбранной истории
import '../src/data/services/progress_grpc_service.dart'; // Импорт загрузки отметок чтения
import '../src/data/repositories/progress_repository_remote.dart'; // Импорт прогресса
import '../src/data/services/episode_grpc_service.dart'; // Импорт полного эпизода
import '../widgets/button_sound.dart'; // Импорт звука кнопок

// Перечитываю разговоры отдельно от прохождения и ничего не записываю в прогресс.
class HiddenSceneAlbumScreen extends StatefulWidget {
  final Future<Set<String>> Function()?
  loadFlags; // Подменяю чтение прогресса в проверках
  const HiddenSceneAlbumScreen({super.key, this.loadFlags});
  @override
  State<HiddenSceneAlbumScreen> createState() => _HiddenSceneAlbumScreenState();
}

class _HiddenSceneAlbumScreenState extends State<HiddenSceneAlbumScreen> {
  final _service = ProgressGrpcService();
  Set<String> _seen = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.loadFlags != null) {
        final seen = await widget.loadFlags!();
        if (mounted) {
          setState(() {
            _seen = seen;
            _loading = false;
          });
        }
        return;
      }
      final player = await StorageService.loadPlayerId();
      if (player.isEmpty) throw StateError('Сначала войди в аккаунт');
      final repository = ProgressRepositoryRemote(_service);
      final episodes = EpisodeGrpcService();
      late final List<int> ids;
      try {
        ids = (await episodes.getAllEpisodes()).map((e) => e.id).toList();
      } finally {
        await episodes.close();
      }
      final progress = await Future.wait([
        for (final id in ids) repository.getProgress(player, id),
      ]);
      final seen = <String>{};
      for (final item in progress) {
        for (final entry in item.flags.entries) {
          if (entry.value) seen.add(entry.key);
        }
      }
      if (mounted) {
        setState(() {
          _seen = seen;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Не удалось загрузить альбом. Проверь подключение и повтори.';
        });
      }
    }
  }

  Future<void> _read(Map<String, dynamic> card) async {
    if (!_seen.contains(card['flag'])) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _HiddenReader(card: card)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const StoryHeader(title: 'Скрытые сцены'),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: withButtonSound(_load),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Открыто ${ActiveNovel.shared.cards('hidden').where((c) => _seen.contains(c['flag'])).length} из ${ActiveNovel.shared.cards('hidden').length}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              for (final card in ActiveNovel.shared.cards('hidden'))
                Card(
                  child: ListTile(
                    leading: Icon(
                      _seen.contains(card['flag'])
                          ? Icons.menu_book
                          : Icons.lock_outline,
                    ),
                    title: Text(card['title'] as String),
                    subtitle: Text(
                      _seen.contains(card['flag'])
                          ? 'Эпизод ${card['episode']} · Перечитать'
                          : 'Эпизод ${card['episode']} · Подсказка: ${card['hint']}',
                    ),
                    onTap: _seen.contains(card['flag'])
                        ? withButtonSound(() => _read(card))
                        : null,
                  ),
                ),
            ],
          ),
  );
}

class _HiddenReader extends StatefulWidget {
  final Map<String, dynamic> card;
  const _HiddenReader({required this.card});
  @override
  State<_HiddenReader> createState() => _HiddenReaderState();
}

class _HiddenReaderState extends State<_HiddenReader> {
  final _service = EpisodeGrpcService();
  List<String>? _texts;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _texts = null;
      _error = null;
    });
    try {
      final episode = await _service.getEpisode(widget.card['episode'] as int);
      final scene = episode.scenes.firstWhere(
        (s) => s.sceneKey == widget.card['key'],
      );
      if (mounted) setState(() => _texts = List<String>.from(scene.texts));
    } catch (_) {
      if (mounted) setState(() => _error = 'Не удалось загрузить разговор');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: StoryHeader(title: widget.card['title'] as String),
    body: _error != null
        ? Center(
            child: TextButton(
              onPressed: withButtonSound(_load),
              child: Text(
                '$_error. Повторить',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
        : _texts == null
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final text in _texts!)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                ),
            ],
          ),
  );
}