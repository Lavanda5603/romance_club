import 'package:flutter/material.dart'; // Импорт бордовой галереи
import '../services/storage_service.dart'; // Импорт текущего игрока
import '../src/core/ending_art.dart'; // Импорт пяти авторских картинок
import '../src/core/ending_gallery.dart'; // Импорт подписей и подсказок
import '../src/data/services/progress_grpc_service.dart'; // Импорт истории прохождений
import '../src/data/services/rpc_policy.dart'; // Импорт ошибок сети
import '../widgets/button_sound.dart'; // Импорт звука открытия карточки

class EndingGalleryScreen extends StatefulWidget {
  final Future<Set<String>> Function()? loadEndings; // Подменяю историю в тестах
  const EndingGalleryScreen({super.key, this.loadEndings});
  @override
  State<EndingGalleryScreen> createState() => _EndingGalleryScreenState();
}

class _EndingGalleryScreenState extends State<EndingGalleryScreen> {
  final _service = ProgressGrpcService();
  Set<String>? _seen;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _service.close(); super.dispose(); }

  Future<Set<String>> _read() async {
    final player = await StorageService.loadPlayerId();
    if (player.isEmpty) throw StateError('Сначала войди в аккаунт');
    final summary = await _service.getProgressSummary(player);
    if (!summary.endingsAvailable) throw StateError('Обнови и перезапусти сервер для галереи концовок');
    return summary.seenEndings.toSet();
  }

  Future<void> _load() async {
    setState(() { _seen = null; _error = null; });
    try {
      final seen = await (widget.loadEndings?.call() ?? _read());
      if (mounted) setState(() => _seen = knownGalleryEndings(seen));
    } catch (error) {
      if (mounted) setState(() => _error = 'Не удалось загрузить коллекцию. ${networkError(error)}');
    }
  }

  void _open(Map<String, String> card) {
    if (_seen?.contains(card['key']) != true) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => _EndingDetail(card: card)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF1A1A1A),
    appBar: AppBar(title: const Text('Галерея концовок'), backgroundColor: const Color(0xFF3F0404), foregroundColor: Colors.white),
    body: _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
      TextButton(onPressed: withButtonSound(_load), child: const Text('Повторить', style: TextStyle(color: Color(0xFFFFA0A0)))),
    ])) : _seen == null ? const Center(child: CircularProgressIndicator(color: Color(0xFFD30010)))
      : ListView(padding: const EdgeInsets.all(20), children: [
        Text('Открыто ${_seen!.length} из ${endingGalleryCards.length}',
          style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 24)),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text(
          'Коллекция сохраняется при переигрывании и сбросе прогресса. Дружеский финал имеет приоритет перед романтическими.',
          style: TextStyle(color: Colors.white70))),
        for (final card in endingGalleryCards) Card(color: const Color(0xFF3F0404),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(contentPadding: const EdgeInsets.all(16),
            leading: SizedBox(width: 68, height: 80, child: _seen!.contains(card['key'])
              ? _endingPicture(card, small: true) : const Icon(Icons.lock_outline, color: Color(0xFFAAA0A0), size: 40)),
            title: Text(card['title']!, style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 18)),
            subtitle: Text(_seen!.contains(card['key']) ? 'Открыто · Посмотреть' : 'Подсказка: ${card['hint']}',
              style: const TextStyle(color: Colors.white70)),
            onTap: _seen!.contains(card['key']) ? withButtonSound(() => _open(card)) : null,
          )),
      ]),
  );
}

// Не выдаю общий фон за отдельную авторскую картинку особого финала.
Widget _endingPicture(Map<String, String> card, {bool small = false}) {
  final path = endingArtwork[card['key']];
  if (path == null) {
    return Icon(card['key'] == 'Команда вместе' ? Icons.groups : Icons.auto_awesome,
      size: small ? 48 : 120, color: const Color(0xFFFFA0A0));
  }
  return Image.asset(path, fit: BoxFit.contain, cacheWidth: small ? 160 : 1080,
    errorBuilder: (_, error, stack) => const Icon(Icons.image_not_supported, color: Colors.white70));
}

class _EndingDetail extends StatelessWidget {
  final Map<String, String> card;
  const _EndingDetail({required this.card});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF1A1A1A),
    appBar: AppBar(title: Text(card['title']!), backgroundColor: const Color(0xFF3F0404), foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      SizedBox(height: MediaQuery.sizeOf(context).height * 0.5, child: _endingPicture(card)),
      const SizedBox(height: 20),
      Text(card['description']!, style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 19, height: 1.5)),
      const SizedBox(height: 12),
      const Text('Коллекционная карточка · просмотр не меняет прохождение', style: TextStyle(color: Colors.white70)),
    ]),
  );
}