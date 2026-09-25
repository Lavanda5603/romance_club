import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/scene.pb.dart'; // Импорт Protobuf-модели Scene
import '../generated/choice.pb.dart'; // Импорт Protobuf-модели Choice
import 'choice_editor_screen.dart'; // Импорт экрана редактора выбора

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

  // Добавление нового выбора
  void _addChoice() {
    // Открываю экран редактора выбора с null (создание нового)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChoiceEditorScreen(
          choice: null, // Новый выбор
          onSave: (newChoice) {
            setState(() {
              // Добавляю выбор в список (repeated)
              widget.scene.choices.add(newChoice);
            });
          },
        ),
      ),
    );
  }

  // Редактирование существующего выбора
  void _editChoice(int index) {
    // Открываю экран редактора выбора с существующим выбором
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChoiceEditorScreen(
          choice: widget.scene.choices[index], // Выбор
          onSave: (newChoice) {
            setState(() {
              // Заменяю выбор в списке
              widget.scene.choices[index] = newChoice;
            });
          },
        ),
      ),
    );
  }

  // Удаление выбора
  Future<void> _deleteChoice(int index) async {
    // Показываю диалог подтверждения
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
              onPressed: () => Navigator.pop(context, false), // Отмена
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Подтверждение
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    // Если пользователь подтвердил, удаляю выбор
    if (confirmed == true) {
      setState(() {
        widget.scene.choices.removeAt(index);
      });
    }
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
              const SizedBox(height: 24),
              // Блок выборов
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Выборы:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _addChoice,
                    child: const Text('+ Добавить выбор'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Список выборов
              if (widget.scene.choices.isEmpty)
                const Text('Нет выборов')
              else
                ListView.builder(
                  shrinkWrap: true, // Чтобы ListView не занимал весь экран
                  physics: const NeverScrollableScrollPhysics(), // Отключаю скролл у ListView
                  itemCount: widget.scene.choices.length,
                  itemBuilder: (context, index) {
                    final choice = widget.scene.choices[index];
                    return ListTile(
                      title: Text(choice.text), // Текст выбора
                      subtitle: Text('Действий: ${choice.actions.length}'), // Количество действий
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Кнопка редактирования выбора
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _editChoice(index);
                            },
                          ),
                          // Кнопка удаления выбора
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _deleteChoice(index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
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