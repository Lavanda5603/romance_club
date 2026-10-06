import 'package:flutter/material.dart'; // Импорт Material UI
import 'dart:typed_data'; // Импорт Uint8List
import '../generated/scene.pb.dart'; // Импорт Protobuf-модели Scene
import '../src/data/repositories/asset_repository_remote.dart'; // Импорт репозитория ассетов
import '../src/data/services/asset_grpc_service.dart'; // Импорт gRPC-сервиса ассетов
import '../src/domain/models/asset_model.dart'; // Импорт доменной модели
import 'choice_editor_screen.dart'; // Импорт экрана редактора выбора
import 'asset_picker_screen.dart'; // Импорт экрана выбора ассета

// Экран редактирования сцены
class SceneEditorScreen extends StatefulWidget {
  final Scene scene; // Сцена
  final Function(Scene) onSave; // Функция, вызывается при сохранении
  final String episodeId; // ID эпизода (для фильтра ассетов)

  // Конструктор класса SceneEditorScreen
  const SceneEditorScreen({
    super.key,
    required this.scene,
    required this.onSave,
    this.episodeId = '',
  });

  // Метод createState (создание объекта состояния)
  @override
  State<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _SceneEditorScreenState extends State<SceneEditorScreen> {
  late TextEditingController _titleController; // Контроллер названия
  late TextEditingController _conditionController; // Контроллер условия
  late TextEditingController _musicController; // Контроллер музыки

  // Список контроллеров для каждого текста
  late List<TextEditingController> _textControllers;

  // gRPC-сервис и репозиторий ассетов
  late AssetGrpcService _assetService;
  late AssetRepositoryRemote _assetRepository;

  // Выбранный фон и персонаж (плюс байты для предпросмотра)
  String _selectedBackground = '';
  Uint8List? _selectedBackgroundBytes;
  String _selectedCharacter = '';
  String _selectedEmotion = '';
  Uint8List? _selectedCharacterBytes;

  // Позиции
  String _selectedCharacterPosition = 'center';
  String _selectedTextPosition = 'bottom_center';

  // Список позиций (английские значения — для БД)
  final List<String> _positions = [
    'top_left', 'top_center', 'top_right',
    'center_left', 'center', 'center_right',
    'bottom_left', 'bottom_center', 'bottom_right',
  ];

  // Русские названия позиций (для отображения)
  final Map<String, String> _positionNames = {
    'top_left': 'Сверху слева',
    'top_center': 'Сверху по центру',
    'top_right': 'Сверху справа',
    'center_left': 'По центру слева',
    'center': 'По центру',
    'center_right': 'По центру справа',
    'bottom_left': 'Снизу слева',
    'bottom_center': 'Снизу по центру',
    'bottom_right': 'Снизу справа',
  };

  @override
  void initState() {
    super.initState();

    // Создаю контроллеры
    _titleController = TextEditingController(text: widget.scene.title);
    _conditionController = TextEditingController(text: widget.scene.condition);
    _musicController = TextEditingController();

    // Создаю контроллеры для каждого существующего текста
    _textControllers = widget.scene.texts
        .map((t) => TextEditingController(text: t))
        .toList();

    if (_textControllers.isEmpty) {
      _textControllers.add(TextEditingController());
    }

    // Инициализирую выбранные значения
    _selectedBackground = widget.scene.background;
    _selectedCharacter = widget.scene.character;
    _selectedEmotion = widget.scene.characterEmotion;
    _selectedCharacterPosition = widget.scene.characterPosition.isNotEmpty
        ? widget.scene.characterPosition
        : 'center';
    _selectedTextPosition = widget.scene.textPosition.isNotEmpty
        ? widget.scene.textPosition
        : 'bottom_center';

    // Создаю сервис и репозиторий
    _assetService = AssetGrpcService();
    _assetRepository = AssetRepositoryRemote(_assetService);

    // Загружаю байты для уже выбранных фона и персонажа
    _loadSelectedAssets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _conditionController.dispose();
    _musicController.dispose();
    for (final c in _textControllers) {
      c.dispose();
    }
    _assetService.close();
    super.dispose();
  }

  // Загрузка байтов для уже выбранных фона и персонажа
  Future<void> _loadSelectedAssets() async {
    try {
      // Загружаю фоны
      final backgrounds = await _assetRepository.getAssets('background');
      for (final a in backgrounds) {
        if (a.name == _selectedBackground && a.fileData.isNotEmpty) {
          _selectedBackgroundBytes = Uint8List.fromList(a.fileData);
          break;
        }
      }

      // Загружаю персонажей
      final characters = await _assetRepository.getAssets('character');
      for (final a in characters) {
        if (a.name == _selectedCharacter &&
            a.emotion == _selectedEmotion &&
            a.fileData.isNotEmpty) {
          _selectedCharacterBytes = Uint8List.fromList(a.fileData);
          break;
        }
      }

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Ошибка загрузки ассетов: $e');
    }
  }

  // Добавить новое поле текста
  void _addTextField() {
    setState(() {
      _textControllers.add(TextEditingController());
    });
  }

  // Удалить поле текста по индексу
  void _removeTextField(int index) {
    setState(() {
      _textControllers[index].dispose();
      _textControllers.removeAt(index);
    });
  }

  // Открыть экран выбора фона
  Future<void> _pickBackground() async {
    final result = await Navigator.push<AssetModel>(
      context,
      MaterialPageRoute(
        builder: (context) => AssetPickerScreen(
          type: 'background',
          title: 'Выбор фона',
          episodeId: widget.episodeId,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedBackground = result.name;
        _selectedBackgroundBytes = result.fileData.isNotEmpty
            ? Uint8List.fromList(result.fileData)
            : null;
      });
    }
  }

  // Открыть экран выбора персонажа
  Future<void> _pickCharacter() async {
    final result = await Navigator.push<AssetModel>(
      context,
      MaterialPageRoute(
        builder: (context) => AssetPickerScreen(
          type: 'character',
          title: 'Выбор персонажа',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCharacter = result.name;
        _selectedEmotion = result.emotion;
        _selectedCharacterBytes = result.fileData.isNotEmpty
            ? Uint8List.fromList(result.fileData)
            : null;
      });
    }
  }

  // Убрать персонажа из сцены
  void _removeCharacter() {
    setState(() {
      _selectedCharacter = '';
      _selectedEmotion = '';
      _selectedCharacterBytes = null;
    });
  }

  // Сохранение сцены
  void _saveScene() {
    final newScene = Scene(
      id: widget.scene.id,
      title: _titleController.text,
      background: _selectedBackground,
      character: _selectedCharacter,
      characterEmotion: _selectedEmotion,
      condition: _conditionController.text,
      sceneKey: widget.scene.sceneKey,
      characterPosition: _selectedCharacterPosition,
      textPosition: _selectedTextPosition,
    );

    for (final c in _textControllers) {
      if (c.text.trim().isNotEmpty) {
        newScene.texts.add(c.text.trim());
      }
    }

    newScene.choices.addAll(widget.scene.choices);

    widget.onSave(newScene);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сцена сохранена')),
    );

    Navigator.pop(context);
  }

  // Добавление нового выбора
  void _addChoice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChoiceEditorScreen(
          choice: null,
          defaultText: 'выбор ${widget.scene.choices.length + 1}',
          onSave: (newChoice) {
            setState(() {
              widget.scene.choices.add(newChoice);
            });
          },
        ),
      ),
    );
  }

  // Редактирование выбора
  void _editChoice(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChoiceEditorScreen(
          choice: widget.scene.choices[index],
          onSave: (newChoice) {
            setState(() {
              widget.scene.choices[index] = newChoice;
            });
          },
        ),
      ),
    );
  }

  // Удаление выбора
  Future<void> _deleteChoice(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить выбор?'),
          content: Text(
            'Вы точно уверены, что хотите удалить "${widget.scene.choices[index].text}"?',
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
        widget.scene.choices.removeAt(index);
      });
    }
  }

  // Виджет поля ввода с рамкой
  Widget _buildField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD30010)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Виджет выпадающего списка (с русскими названиями)
  Widget _buildDropdown(String label, String value, Function(String?) onChanged) {
    final safeItems = _positions.contains(value) ? _positions : [value, ..._positions];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF3F0404),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            underline: const SizedBox(),
            items: safeItems.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(_positionNames[item] ?? item), // Русское название
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Виджет предпросмотра (картинки из байтов)
  Widget _buildPreview() {
    Alignment getAlign(String pos) {
      switch (pos) {
        case 'top_left': return Alignment.topLeft;
        case 'top_center': return Alignment.topCenter;
        case 'top_right': return Alignment.topRight;
        case 'center_left': return Alignment.centerLeft;
        case 'center_right': return Alignment.centerRight;
        case 'bottom_left': return Alignment.bottomLeft;
        case 'bottom_center': return Alignment.bottomCenter;
        case 'bottom_right': return Alignment.bottomRight;
        default: return Alignment.center;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'предпросмотр:',
          style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
        ),
        const SizedBox(height: 4),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              children: [
                // Фон
                Positioned.fill(
                  child: _selectedBackgroundBytes == null
                      ? Container(color: const Color(0xFF333333))
                      : Image.memory(
                          _selectedBackgroundBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: const Color(0xFF333333));
                          },
                        ),
                ),
                // Персонаж
                if (_selectedCharacterBytes != null)
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    bottom: 80,
                    child: Align(
                      alignment: getAlign(_selectedCharacterPosition),
                      child: FractionallySizedBox(
                        widthFactor: 0.4,
                        heightFactor: 0.7,
                        child: Image.memory(
                          _selectedCharacterBytes!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.red,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                // Текст
                Align(
                  alignment: getAlign(_selectedTextPosition),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA0A0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _textControllers.isNotEmpty && _textControllers[0].text.isNotEmpty
                            ? _textControllers[0].text
                            : 'текст сцены...',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),

      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1A1A),
              child: Image.asset(
                'assets/images/main_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFFD30010), size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Клуб романтики',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'РЕДАКТИРОВАНИЕ\nСЦЕНЫ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'название сцены',
                          style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 18),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'фон',
                          style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _pickBackground,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedBackground.isEmpty
                                        ? 'не выбран'
                                        : _selectedBackground,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'персонаж',
                          style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickCharacter,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedCharacter.isEmpty
                                              ? 'не выбран'
                                              : '$_selectedCharacter ($_selectedEmotion)',
                                          style: const TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedCharacter.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Color(0xFFD30010)),
                                  onPressed: _removeCharacter,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          'позиция персонажа',
                          _selectedCharacterPosition,
                          (value) {
                            if (value != null) {
                              setState(() => _selectedCharacterPosition = value);
                            }
                          },
                        ),

                        _buildDropdown(
                          'позиция текста',
                          _selectedTextPosition,
                          (value) {
                            if (value != null) {
                              setState(() => _selectedTextPosition = value);
                            }
                          },
                        ),

                        _buildPreview(),

                        const Text(
                          'тексты сцены:',
                          style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                        ),
                        const SizedBox(height: 8),

                        ..._textControllers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final controller = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      maxLines: 3,
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Color(0xFFFFA0A0)),
                                    onPressed: () => _removeTextField(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFA0A0)),
                            onPressed: _addTextField,
                          ),
                        ),

                        _buildField('условие', _conditionController),
                        const SizedBox(height: 8),

                        const Text(
                          'выбор',
                          style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        if (widget.scene.choices.isEmpty)
                          const Text('нет выборов', style: TextStyle(color: Colors.white))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.scene.choices.length,
                            itemBuilder: (context, index) {
                              final choice = widget.scene.choices[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      choice.title.isNotEmpty ? choice.title : 'выбор ${index + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'действия:',
                                      style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    ...choice.actions.map((action) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                                        child: Text(
                                          action.title.isNotEmpty ? action.title : 'действие',
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.white),
                                            onPressed: () => _editChoice(index),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Color(0xFFFFA0A0)),
                                            onPressed: () => _deleteChoice(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFA0A0)),
                            onPressed: _addChoice,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _buildField('музыка', _musicController),
                        const SizedBox(height: 8),

                        SizedBox(
                          width: 200,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _saveScene,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD30010),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'сохранить',
                              style: TextStyle(
                                color: Color(0xFF3F0404),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}