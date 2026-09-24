import 'package:flutter/material.dart'; // Импорт Material UI
import '../models/episode.dart'; // Импорт класса Episode
import '../models/scene.dart'; // Импорт класса Scene

// Экран редактирования сцены
class SceneEditorScreen extends StatefulWidget {
  final Episode episode; // Эпизод (принадлежит сцена)
  final Scene scene; // Сцена

  // Конструктор класса SceneEditorScreen
  const SceneEditorScreen({
    super.key,
    required this.episode,
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
  }

  @override
  void dispose() {
    // Освобождение ресурсов всех контроллеров при закрытии экрана
    _idController.dispose();
    _backgroundController.dispose();
    _characterController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // Сохранение сцены
  void _saveScene() {
    // Создаю новый объект Scene с обновлёнными данными
    final newScene = Scene(
      id: int.parse(_idController.text), // Id беру из поля ввода
      background: _backgroundController.text, // Фон беру из поля ввода
      character: _characterController.text, // Персонажа беру из поля ввода
      texts: _textController.text.split('\n'), // Текст разбиваю по переносу строки
      choices: widget.scene.choices, // Выборы беру из текущей сцены
      condition: widget.scene.condition, // Условие беру из текущей сцены
    );

    // Нахожу индекс текущей сцены в списке сцен эпизода
    final index = widget.episode.scenes.indexOf(widget.scene);

    // Заменяю старую сцену на новую
    setState(() {
      widget.episode.scenes[index] = newScene;
    });

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
                labelText: 'Текст',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
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
    );
  }
}