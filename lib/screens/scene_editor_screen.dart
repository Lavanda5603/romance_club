import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/scene.pb.dart'; // Импорт Protobuf-модели Scene
import 'choice_editor_screen.dart'; // Импорт экрана редактора выбора

// Экран редактирования сцены
class SceneEditorScreen extends StatefulWidget {
  final Scene scene; // Сцена
  final Function(Scene) onSave; // Функция, вызывается при сохранении

  // Конструктор класса SceneEditorScreen
  const SceneEditorScreen({
    super.key,
    required this.scene,
    required this.onSave,
  });

  // Метод createState (создание объекта состояния)
  @override
  State<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _SceneEditorScreenState extends State<SceneEditorScreen> {
  late TextEditingController _titleController; // Контроллер для поля ввода названия
  late TextEditingController _backgroundController; // Контроллер для поля ввода фона
  late TextEditingController _characterController; // Контроллер для поля ввода персонажа
  late TextEditingController _conditionController; // Контроллер для поля ввода условия сцены
  late TextEditingController _musicController; // Контроллер для поля ввода музыки

  // Список контроллеров для каждого текста
  late List<TextEditingController> _textControllers;

  @override
  void initState() {
    super.initState();
    // Создание контроллеров
    _titleController = TextEditingController(text: widget.scene.title);
    _backgroundController = TextEditingController(text: widget.scene.background);
    _characterController = TextEditingController(text: widget.scene.character);
    _conditionController = TextEditingController(text: widget.scene.condition);
    _musicController = TextEditingController();

    // Создаю контроллеры для каждого существующего текста
    _textControllers = widget.scene.texts
        .map((t) => TextEditingController(text: t))
        .toList();

    // Если текстов нет — создаю один пустой
    if (_textControllers.isEmpty) {
      _textControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    // Освобождение ресурсов всех контроллеров
    _titleController.dispose();
    _backgroundController.dispose();
    _characterController.dispose();
    _conditionController.dispose();
    _musicController.dispose();
    for (final c in _textControllers) {
      c.dispose();
    }
    super.dispose();
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

  // Сохранение сцены
  void _saveScene() {
    // Создаю новую сцену с данными из полей
    final newScene = Scene(
      id: widget.scene.id, // ID оставляю прежним (SurrealDB генерирует)
      title: _titleController.text,
      background: _backgroundController.text,
      character: _characterController.text,
      condition: _conditionController.text,
      sceneKey: widget.scene.sceneKey, // Настоящий ID
    );

    // Добавляю тексты (только непустые)
    for (final c in _textControllers) {
      if (c.text.trim().isNotEmpty) {
        newScene.texts.add(c.text.trim());
      }
    }

    // Копирую выборы из старой сцены
    newScene.choices.addAll(widget.scene.choices);

    // Вызываю колбэк onSave
    widget.onSave(newScene);

    // Показываю уведомление
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сцена сохранена')),
    );

    // Закрываю экран
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      
      // Использую Stack, чтобы наложить контент на фон
      body: Stack(
        children: [
          // Слой для фона
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1A1A), // Цвет фона-заглушки
              // Картинка фона
              child: Image.asset(
                'assets/images/main_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Основной контент
          SafeArea(
            child: Column(
              children: [
                // --- ВЕРХНЯЯ ПАНЕЛЬ (AppBar) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Кнопка назад
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFFD30010), size: 28),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      
                      // Заголовок
                      const Text(
                        'Клуб романтики',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      
                      // Пустой контейнер для симметрии
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // --- ОСНОВНОЙ БЛОК (скроллится) ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок в стиле других экранов
                        const Center(
                          child: Text(
                            'РЕДАКТИРОВАНИЕ\nСЦЕНЫ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w300, // Тонкий шрифт
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Название сцены
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

                        // Фон, персонаж
                        _buildField('фон', _backgroundController),
                        _buildField('персонаж', _characterController),

                        // Тексты (динамические поля)
                        const Text(
                          'тексты сцены:',
                          style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        
                        // Список текстов (рамка как у других полей)
                        ..._textControllers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final controller = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              // Рамка как у остальных полей
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  // Поле ввода (без своей рамки, т.к. рамка у контейнера)
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
                                  // Кнопка удаления (розовая, внутри блока)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Color(0xFFFFA0A0)),
                                    onPressed: () => _removeTextField(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        
                        // Плюсик для добавления текста (поднят выше)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFA0A0)),
                            onPressed: _addTextField,
                          ),
                        ),

                        _buildField('условие', _conditionController),
                        const SizedBox(height: 8),

                        // Выборы
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
                                            icon: const Icon(Icons.delete_outline, color: Color(0xFFFFA0A0)), // Розовая корзина
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
                        
                        // Плюсик для добавления выбора (поднят выше)
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

                        // Кнопка сохранить (поднята выше)
                        SizedBox(
                          width: 200, // Уже, как на других экранах
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

                        // Пустое пространство снизу, чтобы поднять кнопку выше
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