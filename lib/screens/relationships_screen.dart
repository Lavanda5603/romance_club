import '../widgets/editor_save_button.dart'; // Импорт общей кнопки сохранения
import '../widgets/story_header.dart'; // Импорт общей шапки и тонкого заголовка
import '../services/active_novel.dart'; // Импорт карточек выбранной истории

import 'dart:convert'; // Импорт формата уровней
import 'dart:typed_data'; // Импорт картинок персонажей

import 'package:flutter/material.dart'; // Импорт бордовых карточек

import '../generated/episode_api.pb.dart'; // Импорт настроек с версией
import '../services/storage_service.dart'; // Импорт текущего игрока
import '../src/core/relationships.dart'; // Импорт расчёта уровней
import '../src/data/services/episode_grpc_service.dart'; // Импорт общих настроек
import '../src/data/services/progress_grpc_service.dart'; // Импорт снимков баллов
import '../src/data/services/asset_grpc_service.dart'; // Импорт превью персонажей
import '../src/data/services/rpc_policy.dart'; // Импорт ошибок подключения
import '../widgets/button_sound.dart'; // Импорт щелчка

// Из профиля читаю отношения, из редактора меняю только подписи и пороги.
class RelationshipsScreen extends StatefulWidget {
  final bool edit;
  final EpisodeGrpcService?
  episodeService; // Подменяю настройки в проверках редактора
  const RelationshipsScreen({
    super.key,
    this.edit = false,
    this.episodeService,
  });
  @override
  State<RelationshipsScreen> createState() => _RelationshipsScreenState();
}

class _RelationshipsScreenState extends State<RelationshipsScreen> {
  late final EpisodeGrpcService _episodes;
  final _progress = ProgressGrpcService();
  final _assets = AssetGrpcService();
  final _names = <String, List<TextEditingController>>{};
  final _thresholds = <String, List<TextEditingController>>{};
  final _photos = <String, Future<Uint8List?>>{};
  Map<String, dynamic>? _rules;
  Map<String, int> _scores = {};
  int _revision = 0;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _episodes = widget.episodeService ?? EpisodeGrpcService();
    _load();
  }

  @override
  void dispose() {
    for (final group in [..._names.values, ..._thresholds.values]) {
      for (final controller in group) {
        controller.dispose();
      }
    }
    if (widget.episodeService == null) _episodes.close();
    _progress.close();
    _assets.close();
    super.dispose();
  }

  Future<Uint8List?> _photo(Map<String, String> card) async {
    try {
      final imageId = card['image_id'] ?? '';
      if (imageId.isNotEmpty) {
        final image = await _assets.getAsset(
          id: imageId,
          variant: 'screen',
          targetWidth: 480,
          targetHeight: 320,
        );
        return Uint8List.fromList(image.fileData);
      }
      if (card['kind'] == 'romance') {
        final name = card['image_name'];
        if (name == null || name.isEmpty) return null;
        final image = await _assets.getAsset(
          type: 'background',
          name: name,
          variant: 'screen',
          targetWidth: 480,
          targetHeight: 320,
        );
        return Uint8List.fromList(image.fileData);
      }
      final asset = await _assets.getAsset(
        type: 'character',
        name: card['character'] ?? '',
        emotion: card['emotion'] ?? '',
        variant: 'screen',
        targetWidth: 160,
        targetHeight: 160,
      );
      return Uint8List.fromList(
        asset.previewData.isNotEmpty ? asset.previewData : asset.fileData,
      );
    } catch (_) {
      return null;
    } // Отсутствие портрета не скрывает баллы
  }

  Future<void> _load() async {
    setState(() {
      _rules = null;
      _error = null;
    });
    try {
      final settings = await _episodes.getRelationshipRules();
      final rules = jsonDecode(settings.json) as Map<String, dynamic>;
      var scores = <String, int>{};
      if (!widget.edit) {
        final player = await StorageService.loadPlayerId();
        if (player.isEmpty) throw StateError('Войди в аккаунт');
        final episodes = await _episodes.getAllEpisodes();
        final snapshots = await Future.wait(
          episodes.map((e) => _progress.getProgress(player, e.id)),
        );
        scores = relationshipScores(snapshots);
      }
      if (!mounted) return;
      for (final kind in ['romance', 'friendship']) {
        for (final controller in [...?_names[kind], ...?_thresholds[kind]]) {
          controller.dispose();
        }
        final levels = rules[kind] as List<dynamic>;
        _names[kind] = [
          for (final level in levels)
            TextEditingController(text: level['title'] as String),
        ];
        _thresholds[kind] = [
          for (final level in levels)
            TextEditingController(text: '${level['points']}'),
        ];
      }
      if (!widget.edit) {
        for (final card in ActiveNovel.shared.textCards('relationships')) {
          final key = card['counter']!;
          _photos.putIfAbsent(key, () => _photo(card));
        }
      }
      setState(() {
        _rules = rules;
        _revision = settings.revision;
        _scores = scores;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _error = 'Не удалось загрузить отношения. ${networkError(error)}',
        );
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final rules = <String, dynamic>{};
    for (final kind in ['romance', 'friendship']) {
      final levels = <Map<String, dynamic>>[];
      var previous = -1;
      for (var i = 0; i < 3; i++) {
        final points = int.tryParse(_thresholds[kind]![i].text.trim());
        final title = _names[kind]![i].text.trim();
        if (points == null ||
            points <= previous ||
            points > 100000 ||
            (i == 0 && points != 0) ||
            title.isEmpty ||
            title.runes.length > 60) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Проверь названия и возрастающие пороги: первый — 0, максимум — 100000',
              ),
            ),
          );
          return;
        }
        previous = points;
        levels.add({'points': points, 'title': title});
      }
      rules[kind] = levels;
    }
    setState(() => _saving = true);
    try {
      final saved = await _episodes.saveRelationshipRules(
        RelationshipRules(json: jsonEncode(rules), revision: _revision),
      );
      if (!mounted) return;
      _revision = saved.revision;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Уровни сохранены для всех игроков')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${networkError(error)}. При конфликте версий открой редактор заново.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _card(Map<String, String> card) {
    final points = _scores[card['counter']] ?? 0;
    final levels = _rules![card['kind']] as List<dynamic>;
    return Card(
      color: const Color(0xFF3F0404),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: card['kind'] == 'romance' ? 120 : 72,
              height: card['kind'] == 'romance' ? 80 : 96,
              child: FutureBuilder<Uint8List?>(
                future: _photos[card['counter']!],
                builder: (_, snapshot) =>
                    snapshot.data != null && snapshot.data!.isNotEmpty
                    ? Image.memory(
                        snapshot.data!,
                        fit: BoxFit.contain,
                        cacheWidth: card['kind'] == 'romance' ? 400 : 160,
                        errorBuilder: (_, error, stack) =>
                            const Icon(Icons.person, color: Colors.white70),
                      )
                    : Icon(
                        card['kind'] == 'romance'
                            ? Icons.people_outline
                            : Icons.person,
                        color: const Color(0xFFFFA0A0),
                        size: 48,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['title']!,
                    style: const TextStyle(color: Colors.white, fontSize: 17),
                  ),
                  Text(
                    relationshipLevel(points, levels),
                    style: const TextStyle(color: Color(0xFFFFA0A0)),
                  ),
                  Text(
                    'Баллы: $points',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: StoryHeader(
        title: widget.edit ? 'Уровни отношений' : 'Мои отношения',
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
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            )
          : _rules == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD30010)),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: widget.edit
                  ? [
                      for (final kind in ['romance', 'friendship']) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            kind == 'romance' ? 'Романтика' : 'Дружба',
                            style: const TextStyle(
                              color: Color(0xFFFFA0A0),
                              fontSize: 22,
                            ),
                          ),
                        ),
                        for (var i = 0; i < 3; i++)
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _names[kind]![i],
                                  enabled: !_saving,
                                  maxLength: 60,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Название',
                                    labelStyle: TextStyle(
                                      color: Color(0xFFFFA0A0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _thresholds[kind]![i],
                                  enabled: !_saving && i > 0,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'От баллов',
                                    labelStyle: TextStyle(
                                      color: Color(0xFFFFA0A0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                      EditorSaveButton(
                        onPressed: _saving ? null : _save,
                        label: _saving ? 'сохраняю…' : 'сохранить',
                      ),
                    ]
                  : [
                      for (final kind in ['romance', 'friendship']) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            kind == 'romance'
                                ? 'Романтические линии'
                                : 'Дружба',
                            style: const TextStyle(
                              color: Color(0xFFFFA0A0),
                              fontSize: 22,
                            ),
                          ),
                        ),
                        for (final card
                            in ActiveNovel.shared
                                .textCards('relationships')
                                .where((c) => c['kind'] == kind))
                          _card(card),
                      ],
                      Text(
                        'Общая дружба: ${_scores['friendship'] ?? 0}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
            ),
    ),
  );
}