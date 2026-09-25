import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/choice.pb.dart'; // Импорт Protobuf-модели Choice

// Экран редактирования выбора
class ChoiceEditorScreen extends StatefulWidget {
  final Choice? choice; // Выбор (null, если новый)
  final Function(Choice) onSave; // Функция, вызывается при сохранении

  // Конструктор класса ChoiceEditorScreen
  const ChoiceEditorScreen({
    super.key,
    this.choice,
    required this.onSave,
  });

  // Метод createState (создание объекта состояния)
  @override
  State<ChoiceEditorScreen> createState() => _ChoiceEditorScreenState();
}

class _ChoiceEditorScreenState extends State<ChoiceEditorScreen> {
  late TextEditingController _textController; // Контроллер для поля ввода текста

  @override
  void initState() {
    super.initState();
    // Создание контроллера и заполнение его текущим текстом выбора (или пустой строкой)
    _textController = TextEditingController(
      text: widget.choice?.text ?? '',
    );
  }

  @override
  void dispose() {
    // Освобождение ресурса контроллера при закрытии экрана
    _textController.dispose();
    super.dispose();
  }

  // Сохранение выбора
  void _saveChoice() {
    // Создаю Protobuf-модель Choice
    final newChoice = Choice(
      text: _textController.text, // Текст выбора
    );

    // Если редактирую существующий, то копирую действия
    if (widget.choice != null) {
      newChoice.actions.addAll(widget.choice!.actions);
    }

    // Вызываю функцию onSave
    widget.onSave(newChoice);

    // Закрываю экран
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.choice == null ? 'Новый выбор' : 'Редактирование выбора'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Поле ввода текста выбора
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Текст выбора',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Кнопка добавления действия
            ElevatedButton(
              onPressed: () {},
              child: const Text('+ Добавить действие'),
            ),
            const SizedBox(height: 16),
            // Кнопка сохранения
            ElevatedButton(
              onPressed: _saveChoice,
              child: const Text('Сохранить выбор'),
            ),
          ],
        ),
      ),
    );
  }
}