import '../widgets/editor_save_button.dart'; // Импорт общей кнопки сохранения
import '../widgets/story_header.dart'; // Импорт общей шапки и тонкого заголовка
import '../src/data/services/rpc_policy.dart'; // Импорт понятных ошибок подключения
import '../widgets/button_sound.dart'; // Импорт щелчка новых кнопок
import '../services/active_novel.dart'; // Импорт применения сохранённого оформления

import 'dart:convert'; // Импорт настроек карточек
import 'dart:typed_data'; // Импорт загруженной картинки

import 'package:flutter/material.dart'; // Импорт формы новеллы
import 'package:file_picker/file_picker.dart'; // Импорт выбора файлов на телефоне

import '../generated/novel_api.pb.dart'; // Импорт модели новеллы
import '../src/data/services/novel_grpc_service.dart'; // Импорт сохранения новеллы
import '../src/data/services/asset_grpc_service.dart'; // Импорт загрузки картинок
import '../widgets/novel_background.dart'; // Импорт предпросмотра

class NovelEditorScreen extends StatefulWidget {
  final Novel? novel;
  const NovelEditorScreen({super.key, this.novel});
  @override
  State<NovelEditorScreen> createState() => _NovelEditorScreenState();
}

class _NovelEditorScreenState extends State<NovelEditorScreen> {
  final _service = NovelGrpcService();
  final _assets = AssetGrpcService();
  final _title = TextEditingController();
  late Novel _draft;
  late Map<String, dynamic> _config;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _draft =
        widget.novel?.deepCopy() ??
        Novel(
          configJson: jsonEncode({
            'relationships': [],
            'endings': [],
            'hidden': [],
            'final_episode_id': 0,
            'legacy_rules': false,
          }),
        );
    _title.text = _draft.title;
    _config = jsonDecode(_draft.configJson) as Map<String, dynamic>;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Не удалось сохранить: ${error is StateError ? error.message : networkError(error)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _save() => _run(() async {
    if (_title.text.trim().isEmpty) throw StateError('Укажи название');
    final next = _draft.deepCopy()
      ..title = _title.text.trim()
      ..configJson = jsonEncode(_config);
    _draft = await _service.saveNovel(next);
    if (ActiveNovel.shared.id == _draft.id) {
      await ActiveNovel.shared.select(_draft);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Новелла сохранена')));
  });
  Future<void> _picture(String field) => _run(() async {
    final files = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (files == null) return;
    final file = files.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.length > 5 * 1024 * 1024) {
      throw StateError('Картинка должна быть до 5 МБ');
    }
    final response = await _assets.uploadAsset(
      type: 'background',
      name: 'novel_${DateTime.now().microsecondsSinceEpoch}',
      emotion: '',
      displayName: _title.text,
      episodeId: '',
      fileData: Uint8List.fromList(bytes),
      fileName: file.name,
    );
    if (!response.success || response.asset.id.isEmpty) {
      throw StateError(response.message);
    }
    if (!mounted) return;
    setState(() {
      if (field == 'cover') {
        _draft.coverId = response.asset.id;
      } else {
        _draft.backgroundId = response.asset.id;
      }
    });
  });
  Future<void> _audio(String kind) => _run(() async {
    final files = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      withData: true,
    );
    if (files == null) return;
    final bytes = files.files.single.bytes;
    if (bytes == null || bytes.length > 15 * 1024 * 1024) {
      throw StateError('MP3 должен быть до 15 МБ');
    }
    final result = await _service.uploadAudio(_draft.id, kind, bytes);
    if (!mounted) return;
    setState(() {
      if (kind == 'music') {
        _draft.musicId = result.id;
      } else {
        _draft.clickId = result.id;
      }
    });
  });
  // Карточки редактирую в черновике, родителю передаю только после сохранения.
  Future<void> _editCard(String group, int? index) async {
    final rows = _config[group] as List;
    final row = index == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(rows[index] as Map);
    final keyName = group == 'relationships' ? 'counter' : 'key';
    final key = TextEditingController(text: row[keyName]?.toString() ?? '');
    final title = TextEditingController(text: row['title']?.toString() ?? '');
    final hint = TextEditingController(text: row['hint']?.toString() ?? '');
    final flag = TextEditingController(text: row['flag']?.toString() ?? '');
    final episode = TextEditingController(
      text: row['episode']?.toString() ?? '',
    );
    var kind = row['kind']?.toString() ?? 'romance';
    var imageId = row['image_id']?.toString() ?? '';
    var uploading = false;
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => Theme(
        // Задаю светлый текст и подписи прямо для окна карточки.
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFA0A0),
            surface: Color(0xFF3F0404),
            onSurface: Colors.white,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            labelStyle: TextStyle(color: Colors.white),
            floatingLabelStyle: TextStyle(color: Colors.white),
            hintStyle: TextStyle(color: Colors.white70),
            counterStyle: TextStyle(color: Colors.white),
          ),
        ),
        child: StatefulBuilder(
          builder: (dialog, change) => AlertDialog(
            backgroundColor: const Color(0xFF3F0404),
            title: const Text(
              'Карточка',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      controller: title,
                      maxLength: 100,
                      decoration: const InputDecoration(labelText: 'Название'),
                    ),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      controller: key,
                      maxLength: 128,
                      decoration: InputDecoration(
                        labelText: group == 'relationships'
                            ? 'Счётчик отношений'
                            : group == 'hidden'
                            ? 'Ключ сцены'
                            : 'Название финала в действии',
                      ),
                    ),
                    if (group == 'relationships')
                      DropdownButton<String>(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        dropdownColor: const Color(0xFF3F0404),
                        iconEnabledColor: Colors.white,
                        value: kind,
                        items: const [
                          DropdownMenuItem(
                            value: 'romance',
                            child: Text('Романтическая линия'),
                          ),
                          DropdownMenuItem(
                            value: 'friendship',
                            child: Text('Дружба'),
                          ),
                        ],
                        onChanged: withSelectionSound(
                          (value) => change(() {
                            kind = value!;
                          }),
                        ),
                      ),
                    if (group != 'relationships')
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        controller: hint,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          labelText: 'Подсказка для закрытой карточки',
                        ),
                      ),
                    if (group == 'hidden') ...[
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        controller: episode,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Номер эпизода',
                        ),
                      ),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        controller: flag,
                        decoration: const InputDecoration(
                          labelText: 'Флаг прочитанной сцены',
                        ),
                      ),
                    ],
                    if (group != 'hidden') ...[
                      SizedBox(height: 120, child: NovelImage(id: imageId)),
                      ElevatedButton(
                        onPressed: withButtonSound(
                          uploading
                              ? null
                              : () async {
                                  change(() {
                                    uploading = true;
                                    error = null;
                                  });
                                  try {
                                    final files = await FilePicker.platform
                                        .pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: [
                                            'png',
                                            'jpg',
                                            'jpeg',
                                            'webp',
                                          ],
                                          withData: true,
                                        );
                                    if (files != null) {
                                      final file = files.files.single;
                                      final bytes = file.bytes;
                                      if (bytes == null ||
                                          bytes.length > 5 * 1024 * 1024) {
                                        throw StateError(
                                          'Картинка должна быть до 5 МБ',
                                        );
                                      }
                                      final response = await _assets.uploadAsset(
                                        type: 'background',
                                        name:
                                            'novel_card_${DateTime.now().microsecondsSinceEpoch}',
                                        emotion: '',
                                        displayName: title.text,
                                        episodeId: '',
                                        fileData: bytes,
                                        fileName: file.name,
                                      );
                                      if (!response.success) {
                                        throw StateError(response.message);
                                      }
                                      if (dialog.mounted) {
                                        change(() {
                                          imageId = response.asset.id;
                                        });
                                      }
                                    }
                                  } catch (_) {
                                    if (dialog.mounted) {
                                      change(() {
                                        error = 'Не удалось загрузить картинку';
                                      });
                                    }
                                  } finally {
                                    if (dialog.mounted) {
                                      change(() {
                                        uploading = false;
                                      });
                                    }
                                  }
                                },
                        ),
                        child: Text(
                          uploading ? 'Загрузка…' : 'Загрузить картинку',
                        ),
                      ),
                    ],
                    if (error != null)
                      Text(error!, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: withButtonSound(
                  uploading ? null : () => Navigator.pop(dialog, false),
                ),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: withButtonSound(
                  uploading
                      ? null
                      : () {
                          if (title.text.trim().isEmpty ||
                              key.text.trim().isEmpty ||
                              (group == 'hidden' &&
                                  ((int.tryParse(episode.text) ?? 0) <= 0 ||
                                      flag.text.trim().isEmpty))) {
                            change(() {
                              error = 'Заполни название и поля карточки';
                            });
                            return;
                          }
                          row[keyName] = key.text.trim();
                          row['title'] = title.text.trim();
                          if (group == 'relationships') row['kind'] = kind;
                          if (group != 'relationships') {
                            row['hint'] = hint.text.trim();
                          }
                          if (group == 'hidden') {
                            row['episode'] = int.parse(episode.text);
                            row['flag'] = flag.text.trim();
                          } else {
                            row['image_id'] = imageId;
                          }
                          if (group == 'endings' &&
                              !row.containsKey('achievement')) {
                            row['achievement'] = true;
                          }
                          Navigator.pop(dialog, true);
                        },
                ),
                child: const Text('Готово'),
              ),
            ],
          ),
        ),
      ),
    );
    for (final controller in [key, title, hint, flag, episode]) {
      controller.dispose();
    }
    if (saved == true && mounted) {
      setState(() {
        if (index == null) {
          rows.add(row);
        } else {
          rows[index] = row;
        }
      });
    }
  }

  Widget _cards(String group, String title) {
    final rows = _config[group] as List;
    return ExpansionTile(
      title: Text(title, style: const TextStyle(color: Color(0xFFFFA0A0))),
      children: [
        for (var i = 0; i < rows.length; i++)
          ListTile(
            // Показываю загруженную картинку рядом с названием карточки.
            leading: group == 'hidden'
                ? null
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 48,
                      child: NovelImage(
                        id: rows[i]['image_id']?.toString() ?? '',
                        size: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
            title: Text(
              rows[i]['title'] as String,
              style: const TextStyle(color: Colors.white),
            ),
            onTap: withButtonSound(() => _editCard(group, i)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: withButtonSound(
                () => setState(() {
                  rows.removeAt(i);
                }),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ElevatedButton(
            onPressed: withButtonSound(() => _editCard(group, null)),
            child: const Text('Добавить карточку'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _service.close();
    _assets.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFA0A0),
        onPrimary: Color(0xFF3F0404),
        secondary: Color(0xFFD30010),
        onSecondary: Colors.white,
        surface: Color(0xFF1A1A1A),
        onSurface: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.white),
        counterStyle: TextStyle(color: Colors.white70),
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFA0A0),
          foregroundColor: const Color(0xFF3F0404),
          disabledBackgroundColor: const Color(0xFF534F50),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 3,
          shadowColor: const Color(0xFF3F0404),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: const StoryHeader(
        title: 'Настройки новеллы',
        color: Color(0xFFD30010),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _title,
              maxLength: 100,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 160,
                    child: NovelImage(id: _draft.coverId),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 160,
                    child: NovelImage(id: _draft.backgroundId),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: withButtonSound(() => _picture('cover')),
              child: const Text('Загрузить обложку'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: withButtonSound(() => _picture('background')),
              child: const Text('Загрузить общий фон новеллы'),
            ),
            const SizedBox(height: 20),
            if (_draft.backgroundId.isNotEmpty)
              ElevatedButton(
                onPressed: withButtonSound(
                  () => setState(() {
                    _draft.backgroundId = '';
                  }),
                ),
                child: const Text('Убрать фон'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: withButtonSound(
                _draft.id.isEmpty ? null : () => _audio('music'),
              ),
              child: Text(
                _draft.musicId.isEmpty
                    ? 'Загрузить музыку MP3'
                    : 'Заменить музыку MP3',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: withButtonSound(
                _draft.id.isEmpty ? null : () => _audio('click'),
              ),
              child: Text(
                _draft.clickId.isEmpty
                    ? 'Загрузить звук кнопок MP3'
                    : 'Заменить звук кнопок MP3',
              ),
            ),
            if (_draft.id.isEmpty)
              const Text(
                'Сначала сохрани новеллу',
                style: TextStyle(color: Color(0xFFFFA0A0)),
              ),
            const SizedBox(height: 24),
            _cards('relationships', 'Карточки отношений'),
            _cards('endings', 'Галерея концовок'),
            _cards('hidden', 'Альбом скрытых сцен'),
            if (_busy) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 20),
            EditorSaveButton(onPressed: _save),
          ],
        ),
      ),
    ),
  );
}