import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/episode.dart';

class StorageService {
  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/game_data.json');
  }

  static Future<void> saveEpisodes(List<Episode> episodes) async {
    final file = await _getFile();
    final json = {
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
    await file.writeAsString(jsonEncode(json));
  }

  static Future<List<Episode>> loadEpisodes() async {
    final file = await _getFile();
    if (!await file.exists()) {
      return [];
    }
    final jsonString = await file.readAsString();
    final json = jsonDecode(jsonString);
    return (json['episodes'] as List).map((e) => Episode.fromJson(e)).toList();
  }
}