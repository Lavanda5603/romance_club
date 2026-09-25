import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/scene.pb.dart'; // Импорт Protobuf-модели

// Экран редактирования сцены
class SceneEditorScreen extends StatefulWidget {
  final Scene scene; // Сцена

  // Конструктор класса SceneEditorScreen
  const SceneEditorScreen({
    super.key,
    required this.scene,
  });

  // Метод createState (создание объекта состояния)
  @override
  State<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _SceneEditorScreenState extends State<SceneEditorScreen> {
  late TextEditingController _idController; // Контроллер для поля ввода Id
  late TextEditingController _backgroundController; // Контроллер для поля ввода фона
  late TextEditingController _characterController; // Контроллер для поля ввода персонажа
  late TextEditingController _textController; // Контроллер для поля ввода текста
  late TextEditingController _conditionController; // Контроллер для поля ввода условия сцены

  @override
  void initState() {
    super.initState();
    // Создание контроллеров и заполнение их текущими данными сцены
    _idController = TextEditingController(text: widget.scene.id.toString());
    _backgroundController = TextEditingController(text: widget.scene.background);
    _characterController = TextEditingController(text: widget.scene.character);
    _textController = TextEditingController(
      text: widget.scene.texts.join('\n'), // Тексты (объединяю через перенос строки)
    );
    _conditionController = TextEditingController(text: widget.scene.condition);
  }

  @override
  void dispose() {
    // Освобождение ресурсов всех контроллеров при закрытии экрана
    _idController.dispose();
    _backgroundController.dispose();
    _characterController.dispose();
    _textController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  // Сохранение сцены
  void _saveScene() {
    // Protobuf-модели мутабельные (можно менять поля напрямую)
    widget.scene.id = int.parse(_idController.text);
    widget.scene.background = _backgroundController.text;
    widget.scene.character = _characterController.text;
    widget.scene.condition = _conditionController.text;
    
    // texts, repeated string (очищаю и заполняю заново)
    widget.scene.texts.clear();
    widget.scene.texts.addAll(_textController.text.split('\n'));

    // Показываю уведомление о сохранении
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сцена сохранена')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сцена ${widget.scene.id}'), // Заголовок (Id сцены)
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Поле ввода Id сцены
              TextField(
                controller: _idController,
                keyboardType: TextInputType.number, // Только цифры
                decoration: const InputDecoration(
                  labelText: 'ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Поле ввода фона
              TextField(
                controller: _backgroundController,
                decoration: const InputDecoration(
                  labelText: 'Фон',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Поле ввода персонажа
              TextField(
                controller: _characterController,
                decoration: const InputDecoration(
                  labelText: 'Персонаж',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Поле ввода текста
              TextField(
                controller: _textController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Текст (каждая строка — отдельный текст)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              // Поле ввода условия
              TextField(
                controller: _conditionController,
                decoration: const InputDecoration(
                  labelText: 'Условие (опционально)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Кнопка сохранения
              ElevatedButton(
                onPressed: _saveScene,
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}