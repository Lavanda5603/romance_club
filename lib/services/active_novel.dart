import 'dart:convert'; // Импорт настроек выбранной истории
import 'dart:io'; // Импорт локального кэша звуков

import 'package:flutter/foundation.dart'; // Импорт обновления оформления
import 'package:path_provider/path_provider.dart'; // Импорт папки приложения

import '../generated/novel_api.pb.dart'; // Импорт новеллы
import '../src/core/relationships.dart'; // Импорт исходных карточек
import '../src/core/ending_gallery.dart'; // Импорт исходных финалов
import '../src/core/hidden_scene_cards.dart'; // Импорт исходных скрытых разговоров
import '../src/data/services/novel_grpc_service.dart'; // Импорт загрузки звуков
import '../src/data/services/asset_grpc_service.dart'; // Импорт загрузки фона
import 'app_audio.dart'; // Импорт общего управления громкостью

// Выбор новеллы меняет оформление и область истории, но не аккаунт и кошелёк.
class ActiveNovel extends ChangeNotifier {
  static final shared = ActiveNovel();
  static const legacyId = 'novel:ladybug';
  Novel current = Novel(id: legacyId, title: 'Леди Баг и Супер-Кот');
  Map<String, dynamic> config = {
    'relationships': relationshipCards,
    'endings': endingGalleryCards,
    'hidden': hiddenSceneCards,
    'legacy_rules': true,
    'final_episode_id': 5,
  };
  Uint8List? background;
  List<int> episodeIds = [];
  String get id => current.id.isEmpty ? legacyId : current.id;
  bool get legacyRules => config['legacy_rules'] == true;
  int get finalEpisodeId {
    final configured = config['final_episode_id'] as int? ?? 0;
    if (configured > 0) return configured;
    return episodeIds.isEmpty ? 0 : episodeIds.reduce((a, b) => a > b ? a : b);
  }

  List<Map<String, dynamic>> cards(String kind) => (config[kind] as List? ?? [])
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();

  List<Map<String, String>> textCards(String kind) => cards(kind)
      .map((row) => row.map((key, value) => MapEntry(key, value.toString())))
      .toList();

  Future<void> select(Novel item) async {
    final parsed = jsonDecode(item.configJson) as Map<String, dynamic>;
    final service = NovelGrpcService();
    final assets = AssetGrpcService();
    try {
      Uint8List? nextBackground;
      String? music;
      String? click;
      await Future.wait([
        if (item.backgroundId.isNotEmpty)
          assets
              .getAsset(
                id: item.backgroundId,
                variant: 'screen',
                targetWidth: 1080,
                targetHeight: 1920,
              )
              .then((a) {
                nextBackground = Uint8List.fromList(a.fileData);
              }),
        if (item.musicId.isNotEmpty)
          _audioFile(service, item.id, item.musicId).then((path) {
            music = path;
          }),
        if (item.clickId.isNotEmpty)
          _audioFile(service, item.id, item.clickId).then((path) {
            click = path;
          }),
      ]);
      await AppAudio.shared.configureNovel(
        music,
        click,
        defaults: item.id == legacyId,
      );
      current = item.deepCopy();
      config = parsed;
      background = nextBackground;
      episodeIds = [];
      notifyListeners();
    } finally {
      await service.close();
      await assets.close();
    }
  }

  Future<String> _audioFile(
    NovelGrpcService service,
    String novel,
    String id,
  ) async {
    final audio = await service.getAudio(novel, id);
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(audio.hash) ||
        audio.data.isEmpty ||
        audio.data.length > 15 * 1024 * 1024) {
      throw StateError('Не удалось загрузить звук');
    }
    final folder = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/novel_audio',
    );
    await folder.create(recursive: true);
    final file = File('${folder.path}/${audio.hash}.mp3');
    if (!await file.exists() || await file.length() != audio.data.length) {
      await file.writeAsBytes(audio.data, flush: true);
    }
    return file.path;
  }
}