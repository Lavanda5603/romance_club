import 'package:flutter/material.dart' hide Action; // Импорт Material UI
import '../generated/action.pb.dart'; // Импорт Protobuf-модели Action

// Экран редактирования действия
class ActionEditorScreen extends StatefulWidget {
  final Action? action; // Действие (null, если новое)
  final Function(Action) onSave; // Функция, вызывается при сохранении

  // Конструктор класса ActionEditorScreen
  const ActionEditorScreen({
    super.key,
    this.action,
    required this.onSave,
  });

  // Метод createState (создание объекта состояния)
  @override
  State<ActionEditorScreen> createState() => _ActionEditorScreenState();
}

class _ActionEditorScreenState extends State<ActionEditorScreen> {
  // Выбранный тип действия (по умолчанию nextScene)
  String _selectedType = 'nextScene';

  late TextEditingController _sceneIdController; // Контроллер для поля сцены
  late TextEditingController _flagNameController; // Контроллер для поля имени флага
  late TextEditingController _counterNameController; // Контроллер для поля имени счётчика
  late TextEditingController _counterValueController; // Контроллер для поля значения счётчика
  late TextEditingController _soundPathController; // Контроллер для поля пути к звуку
  late TextEditingController _imagePathController; // Контроллер для поля пути к картинке

  // Состояние флага
  bool _flagValue = false;

  @override
  void initState() {
    super.initState();
    // Если редактирую существующее действие, то беру его тип
    if (widget.action != null) {
      _selectedType = widget.action!.type;
      _flagValue = widget.action!.flagValue;
    }

    // Создание контроллеров и заполнение их текущими данными действия
    _sceneIdController = TextEditingController(
      text: widget.action?.sceneId.toString() ?? '',
    );
    _flagNameController = TextEditingController(
      text: widget.action?.flagName ?? '',
    );
    _counterNameController = TextEditingController(
      text: widget.action?.counterName ?? '',
    );
    _counterValueController = TextEditingController(
      text: widget.action?.counterValue.toString() ?? '',
    );
    _soundPathController = TextEditingController(
      text: widget.action?.soundPath ?? '',
    );
    _imagePathController = TextEditingController(
      text: widget.action?.imagePath ?? '',
    );
  }

  @override
  void dispose() {
    // Освобождение ресурсов всех контроллеров при закрытии экрана
    _sceneIdController.dispose();
    _flagNameController.dispose();
    _counterNameController.dispose();
    _counterValueController.dispose();
    _soundPathController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }

  // Сохранение действия
  void _saveAction() {
    // Создаю Protobuf-модель Action
    final newAction = Action(
      type: _selectedType,
    );

    // В зависимости от типа заполняю нужные поля
    if (_selectedType == 'nextScene') {
      newAction.sceneId = int.tryParse(_sceneIdController.text) ?? 0;
    } else if (_selectedType == 'changeFlag') {
      newAction.flagName = _flagNameController.text;
      newAction.flagValue = _flagValue;
    } else if (_selectedType == 'changeCounter') {
      newAction.counterName = _counterNameController.text;
      newAction.counterValue = int.tryParse(_counterValueController.text) ?? 0;
    } else if (_selectedType == 'playSound') {
      newAction.soundPath = _soundPathController.text;
    } else if (_selectedType == 'showImage') {
      newAction.imagePath = _imagePathController.text;
    }

    // Вызываю функцию onSave
    widget.onSave(newAction);

    // Закрываю экран
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.action == null ? 'Новое действие' : 'Редактирование действия'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Выпадающий список типа действия
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип действия',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'nextScene', child: Text('Переход к сцене')),
                  DropdownMenuItem(value: 'changeFlag', child: Text('Установка флага')),
                  DropdownMenuItem(value: 'changeCounter', child: Text('Изменение счётчика (баллы)')),
                  DropdownMenuItem(value: 'playSound', child: Text('Проигрывание звука')),
                  DropdownMenuItem(value: 'showImage', child: Text('Показ картинки')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Поля в зависимости от типа действия
              if (_selectedType == 'nextScene') ...[
                TextField(
                  controller: _sceneIdController,
                  keyboardType: TextInputType.number, // Только цифры
                  decoration: const InputDecoration(
                    labelText: 'ID сцены (куда перейти)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else if (_selectedType == 'changeFlag') ...[
                TextField(
                  controller: _flagNameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя флага (например, helpedGrandpa)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Переключатель значения флага
                Row(
                  children: [
                    const Text('Значение флага:'),
                    const SizedBox(width: 16),
                    Switch(
                      value: _flagValue,
                      onChanged: (value) {
                        setState(() {
                          _flagValue = value;
                        });
                      },
                    ),
                    Text(_flagValue ? 'true' : 'false'),
                  ],
                ),
              ] else if (_selectedType == 'changeCounter') ...[
                TextField(
                  controller: _counterNameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя счётчика (например, adrianPoints)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _counterValueController,
                  keyboardType: TextInputType.number, // Только цифры
                  decoration: const InputDecoration(
                    labelText: 'Значение (например, 1 или -1)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else if (_selectedType == 'playSound') ...[
                TextField(
                  controller: _soundPathController,
                  decoration: const InputDecoration(
                    labelText: 'Путь к звуку (например, click.mp3)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else if (_selectedType == 'showImage') ...[
                TextField(
                  controller: _imagePathController,
                  decoration: const InputDecoration(
                    labelText: 'Путь к картинке (например, heart.png)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Кнопка сохранения
              ElevatedButton(
                onPressed: _saveAction,
                child: const Text('Сохранить действие'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}