import 'package:flutter/material.dart'; // Импорт экрана альбома
import '../services/storage_service.dart'; // Импорт текущего игрока
import '../src/core/hidden_scene_cards.dart'; // Импорт списка скрытых разговоров
import '../src/data/services/progress_grpc_service.dart'; // Импорт загрузки отметок чтения
import '../src/data/repositories/progress_repository_remote.dart'; // Импорт прогресса
import '../src/data/services/episode_grpc_service.dart'; // Импорт полного эпизода
import '../widgets/button_sound.dart'; // Импорт звука кнопок

// Перечитываю разговоры отдельно от прохождения и ничего не записываю в прогресс.
class HiddenSceneAlbumScreen extends StatefulWidget {
  final Future<Set<String>> Function()? loadFlags; // Подменяю чтение прогресса в проверках
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
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _service.close(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (widget.loadFlags != null) {
        final seen = await widget.loadFlags!();
        if (mounted) setState(() { _seen = seen; _loading = false; });
        return;
      }
      final player = await StorageService.loadPlayerId();
      if (player.isEmpty) throw StateError('Сначала войди в аккаунт');
      final repository = ProgressRepositoryRemote(_service);
      final progress = await Future.wait([for (var id = 1; id <= 5; id++) repository.getProgress(player, id)]);
      final seen = <String>{};
      for (final item in progress) {
        for (final entry in item.flags.entries) {
          if (entry.value) seen.add(entry.key);
        }
      }
      if (mounted) setState(() { _seen = seen; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Не удалось загрузить альбом. Проверь подключение и повтори.'; });
    }
  }

  Future<void> _read(Map<String, dynamic> card) async {
    if (!_seen.contains(card['flag'])) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _HiddenReader(card: card)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Скрытые сцены')),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, textAlign: TextAlign.center),
        TextButton(onPressed: withButtonSound(_load), child: const Text('Повторить')),
      ])) : ListView(padding: const EdgeInsets.all(16), children: [
        Text('Открыто ${hiddenSceneCards.where((c) => _seen.contains(c['flag'])).length} из ${hiddenSceneCards.length}'),
        const Text('Открываю разговоры в истории, а здесь перечитываю их без изменения баллов. Полный сброс очищает отметки альбома.'),
        for (final card in hiddenSceneCards) Card(child: ListTile(
          leading: Icon(_seen.contains(card['flag']) ? Icons.menu_book : Icons.lock_outline),
          title: Text(card['title'] as String),
          subtitle: Text(_seen.contains(card['flag']) ? 'Эпизод ${card['episode']} · Перечитать'
            : 'Эпизод ${card['episode']} · Подсказка: ${card['hint']}'),
          onTap: _seen.contains(card['flag']) ? withButtonSound(() => _read(card)) : null,
        )),
      ]),
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
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _service.close(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _texts = null; _error = null; });
    try {
      final episode = await _service.getEpisode(widget.card['episode'] as int);
      final scene = episode.scenes.firstWhere((s) => s.sceneKey == widget.card['key']);
      if (mounted) setState(() => _texts = List<String>.from(scene.texts));
    } catch (_) {
      if (mounted) setState(() => _error = 'Не удалось загрузить разговор');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.card['title'] as String)),
    body: _error != null ? Center(child: TextButton(onPressed: withButtonSound(_load), child: Text('$_error. Повторить')))
      : _texts == null ? const Center(child: CircularProgressIndicator())
      : ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Повторное чтение · прогресс и баллы не изменяются'),
        for (final text in _texts!) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(text, style: const TextStyle(fontSize: 18, height: 1.5))),
      ]),
  );
}