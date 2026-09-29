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
      appBar: AppBar( // Верхняя панель
        backgroundColor: Colors.transparent, // Прозрачный фон
        elevation: 0, // Без тени
        leading: IconButton( // Кнопка с иконкой
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD30010)), // Кнопка назад
          onPressed: () {
            Navigator.pop(context); // Закрыть экран
          },
        ),
        title: const Text( // Текст (маленький, в AppBar)
          'Клуб романтики',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true, // По центру
      ),
      body: SingleChildScrollView( // Прокрутка
        child: Padding( // Отступы
          padding: const EdgeInsets.all(16),
          child: Column( // Вертикальный список
            children: [
              const Text( // Большой заголовок
                'РЕДАКТИРОВАНИЕ ВЫБОРА',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              // Поле ввода названия выбора (розовое)
              TextField( // Поле ввода
                controller: _titleController, // Название
                style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 18), // Розовый текст
                decoration: const InputDecoration( // Оформление поля
                  border: InputBorder.none, // Без рамки
                  isDense: true, // Компактнее
                ),
              ),
              const SizedBox(height: 16),
              // Подпись (розовая)
              const Align( // Выравнивание
                alignment: Alignment.centerLeft,
                child: Text(
                  'текст выбора',
                  style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                ),
              ),
              const SizedBox(height: 4),
              // Поле ввода текста выбора (белая рамка, белый текст)
              TextField( // Поле ввода
                controller: _textController, // Контроллер
                style: const TextStyle(color: Colors.white, fontSize: 16), // Белый текст
                decoration: InputDecoration( // Оформление поля
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // Круглые углы
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white), // Белая рамка
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD30010)), // Красная при фокусе
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Надпись (розовая)
              const Align( // Выравнивание
                alignment: Alignment.centerLeft,
                child: Text(
                  'действия',
                  style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              // Список действий
              if (_choice.actions.isEmpty)
                const Text('нет действий', style: TextStyle(color: Colors.white))
              else
                ListView.builder( // Список
                  shrinkWrap: true, // Чтобы ListView не занимал весь экран
                  physics: const NeverScrollableScrollPhysics(), // Отключаю скролл у ListView
                  itemCount: _choice.actions.length,
                  itemBuilder: (context, index) {
                    final action = _choice.actions[index]; // Действие
                    return Container( // Контейнер (блок действия)
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration( // Оформление
                        border: Border.all(color: Colors.white), // Белая рамка
                        borderRadius: BorderRadius.circular(12), // Круглые углы
                      ),
                      child: Row( // Горизонтальный список
                        children: [
                          // Текст действия (белое)
                          Expanded(
                            child: Text(
                              action.title.isNotEmpty ? action.title : 'действие',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                          // Кнопка редактирования
                          IconButton( // Кнопка с иконкой
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () => _editAction(index), // Редактировать действие
                          ),
                          // Кнопка удаления
                          IconButton( // Кнопка с иконкой
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () => _deleteAction(index), // Удалить действие
                          ),
                        ],
                      ),
                    );
                  },
                ),
              // Иконка плюсика (под действиями)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton( // Кнопка с иконкой
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFA0A0)), // Розовый плюсик
                  onPressed: _addAction, // Добавить действие
                ),
              ),
              const SizedBox(height: 16),
              // Кнопка сохранения
              SizedBox( // Контейнер
                width: double.infinity, // На всю ширину
                child: ElevatedButton( // Кнопка с фоном
                  onPressed: _saveChoice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD30010),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'сохранить',
                    style: TextStyle(color: Color(0xFF3F0404), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}