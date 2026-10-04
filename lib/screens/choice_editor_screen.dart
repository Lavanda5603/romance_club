import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/choice.pb.dart'; // Импорт Protobuf-модели Choice
import 'action_editor_screen.dart'; // Импорт экрана редактора действия

// Экран редактирования выбора
class ChoiceEditorScreen extends StatefulWidget {
  final Choice? choice; // Выбор (null, если новый)
  final String defaultText; // Текст по умолчанию
  final Function(Choice) onSave; // Функция, вызывается при сохранении

  // Конструктор класса ChoiceEditorScreen
  const ChoiceEditorScreen({
    super.key,
    this.choice,
    this.defaultText = '',
    required this.onSave,
  });

  // Метод createState (создание объекта состояния)
  @override
  State<ChoiceEditorScreen> createState() => _ChoiceEditorScreenState();
}

class _ChoiceEditorScreenState extends State<ChoiceEditorScreen> {
  late TextEditingController _titleController; // Контроллер для поля ввода названия
  late TextEditingController _textController; // Контроллер для поля ввода текста
  late Choice _choice; // Локальный выбор (создаётся, если widget.choice == null)

  @override
  void initState() {
    super.initState();
    // Создаю локальный выбор (или беру существующий)
    _choice = widget.choice ?? Choice(); // Choice - Protobuf-модель

    // Если выбор новый - задаю текст по умолчанию
    if (_choice.text.isEmpty) {
      _choice.text = widget.defaultText;
    }

    // Если название пустое - задаю название по умолчанию
    if (_choice.title.isEmpty) {
      _choice.title = widget.defaultText;
    }

    // Создание контроллера названия
    _titleController = TextEditingController(text: _choice.title);

    // Создание контроллера текста выбора
    _textController = TextEditingController(text: _choice.text);
  }

  @override
  void dispose() {
    // Освобождение ресурса контроллера при закрытии экрана
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // Сохранение выбора
  void _saveChoice() {
    // Обновляю название и текст выбора
    _choice.title = _titleController.text;
    _choice.text = _textController.text;

    // Вызываю функцию onSave (передаю выбор родителю)
    widget.onSave(_choice);

    // Закрываю экран
    Navigator.pop(context);
  }

  // Добавление нового действия
  void _addAction() {
    // Открываю экран редактора действия с null (создание нового)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActionEditorScreen(
          action: null, // Новое действие
          defaultTitle: 'действие ${_choice.actions.length + 1}',
          onSave: (newAction) {
            setState(() {
              _choice.actions.add(newAction); // Добавляю действие в список
            });
          },
        ),
      ),
    );
  }

  // Редактирование существующего действия
  void _editAction(int index) {
    // Открываю экран редактора действия с существующим действием
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActionEditorScreen(
          action: _choice.actions[index], // Действие
          onSave: (newAction) {
            setState(() {
              _choice.actions[index] = newAction; // Заменяю действие в списке
            });
          },
        ),
      ),
    );
  }

  // Удаление действия
  Future<void> _deleteAction(int index) async {
    // Показываю диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog( // Всплывающее окно
          title: const Text('Удалить действие?'),
          content: const Text(
            'Вы точно уверены, что хотите удалить это действие?',
          ),
          actions: [
            TextButton( // Кнопка без фона
              onPressed: () => Navigator.pop(context, false), // Отмена
              child: const Text('Отмена'),
            ),
            TextButton( // Кнопка без фона
              onPressed: () => Navigator.pop(context, true), // Подтверждение
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    // Если пользователь подтвердил, удаляю действие
    if (confirmed == true) {
      setState(() {
        _choice.actions.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Каркас экрана
      backgroundColor: const Color(0xFF1A1A1A), // Фон экрана
      
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
                // Верхняя панель
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

                // Основной блок
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок
                        const Center(
                          child: Text(
                            'РЕДАКТИРОВАНИЕ\nВЫБОРА',
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
                        
                        // Поле ввода названия выбора (розовое)
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 18),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Подпись
                        const Text(
                          'текст выбора',
                          style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        
                        // Поле ввода текста выбора (белая рамка)
                        TextField(
                          controller: _textController,
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
                        const SizedBox(height: 24),
                        
                        // Надпись
                        const Text(
                          'действия',
                          style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        
                        // Список действий
                        if (_choice.actions.isEmpty)
                          const Text('нет действий', style: TextStyle(color: Colors.white))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _choice.actions.length,
                            itemBuilder: (context, index) {
                              final action = _choice.actions[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // Текст действия
                                    Expanded(
                                      child: Text(
                                        action.title.isNotEmpty ? action.title : 'действие',
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                    // Кнопка редактирования
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white),
                                      onPressed: () => _editAction(index),
                                    ),
                                    // Кнопка удаления (ИЗМЕНЕНО: белая)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                                      onPressed: () => _deleteAction(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        
                        // Плюсик для добавления действия
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFA0A0)),
                            onPressed: _addAction,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Кнопка сохранить
                        SizedBox(
                          width: 200, // Уже
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _saveChoice,
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