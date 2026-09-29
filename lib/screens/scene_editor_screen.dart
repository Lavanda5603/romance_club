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
  late TextEditingController _idController; // Контроллер для поля ввода Id
  late TextEditingController _backgroundController; // Контроллер для поля ввода фона
  late TextEditingController _characterController; // Контроллер для поля ввода персонажа
  late TextEditingController _textController; // Контроллер для поля ввода текста
  late TextEditingController _conditionController; // Контроллер для поля ввода условия сцены
  late TextEditingController _musicController; // Контроллер для поля ввода музыки

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
    _musicController = TextEditingController(); // Пустой
  }

  @override
  void dispose() {
    // Освобождение ресурсов всех контроллеров при закрытии экрана
    _idController.dispose();
    _backgroundController.dispose();
    _characterController.dispose();
    _textController.dispose();
    _conditionController.dispose();
    _musicController.dispose();
    super.dispose();
  }

  // Сохранение сцены
  void _saveScene() {
    // Создаю новую сцену с данными из полей
    final newScene = Scene( // Scene - Protobuf-модель
      id: int.tryParse(_idController.text) ?? widget.scene.id, // Id из поля
      background: _backgroundController.text, // Фон
      character: _characterController.text, // Персонаж
      condition: _conditionController.text, // Условие
    );

    // Добавляю тексты (repeated string)
    newScene.texts.addAll(_textController.text.split('\n'));

    // Копирую выборы из старой сцены
    newScene.choices.addAll(widget.scene.choices);

    // Вызываю колбэк onSave (сообщаю эпизоду о сохранении)
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
    // Открываю экран редактора выбора с null (создание нового)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChoiceEditorScreen(
          choice: null, // Новый выбор
          onSave: (newChoice) {
            setState(() {
              widget.scene.choices.add(newChoice); // Добавляю выбор в список
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
              widget.scene.choices[index] = newChoice; // Заменяю выбор в списке
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
        return AlertDialog( // Всплывающее окно
          title: const Text('Удалить выбор?'),
          content: Text(
            'Вы точно уверены, что хотите удалить "${widget.scene.choices[index].text}"?',
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

    // Если пользователь подтвердил, удаляю выбор
    if (confirmed == true) {
      setState(() {
        widget.scene.choices.removeAt(index);
      });
    }
  }

  // Виджет поля ввода с рамкой (вспомогательный метод)
  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column( // Column - вертикальный список
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Подпись (розовая)
        Text(
          label,
          style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
        ),
        const SizedBox(height: 4), // Отступ
        // Поле ввода с белой рамкой
        TextField( // Поле ввода
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
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
              borderSide: const BorderSide(color: Color(0xFFD30010)), // Красная рамка при фокусе
            ),
          ),
        ),
        const SizedBox(height: 16), // Отступ
      ],
    );
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
                'РЕДАКТИРОВАНИЕ СЦЕНЫ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              // Поле ввода названия сцены (розовая)
              TextField( // Поле ввода
                controller: _idController, // Контроллер
                style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 18), // Розовый текст
                decoration: const InputDecoration( // Оформление поля
                  border: InputBorder.none, // Без рамки
                  isDense: true, // Компактнее
                ),
              ),
              const SizedBox(height: 16),
              // Поля с рамкой (ID, фон, персонаж, текст, условие)
              _buildField('ID', _idController, keyboardType: TextInputType.number),
              _buildField('фон', _backgroundController),
              _buildField('персонаж', _characterController),
              _buildField('текст', _textController, maxLines: 5),
              // Иконка плюсика (под полем текст)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton( // Кнопка с иконкой
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFA0A0)), // Розовый плюсик
                  onPressed: () {
                    // Tекст
                  },
                ),
              ),
              _buildField('условие', _conditionController),
              const SizedBox(height: 8),
              // Надпись выбор (розовая)
              const Align( // Выравнивание
                alignment: Alignment.centerLeft,
                child: Text(
                  'выбор',
                  style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              // Список выборов
              if (widget.scene.choices.isEmpty)
                const Text('нет выборов', style: TextStyle(color: Colors.white))
              else
                ListView.builder( // Список
                  shrinkWrap: true, // Чтобы ListView не занимал весь экран
                  physics: const NeverScrollableScrollPhysics(), // Отключаю скролл у ListView
                  itemCount: widget.scene.choices.length,
                  itemBuilder: (context, index) {
                    final choice = widget.scene.choices[index];
                    return Container( // Контейнер (блок выбора)
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration( // Оформление
                        border: Border.all(color: Colors.white), // Белая рамка
                        borderRadius: BorderRadius.circular(12), // Круглые углы
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Название выбора (белое)
                          Text(
                            choice.text.isEmpty ? 'выбор ${index + 1} "..."' : choice.text,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          // Подпись действия (серая)
                          const Text(
                            'действия:',
                            style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          // Список действий (белые)
                          ...choice.actions.map((action) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 4),
                              child: Text(
                                'действие "..."',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          // Кнопки редактирования и удаления (справа)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row( // Горизонтальный список
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton( // Кнопка редактирования
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  onPressed: () => _editChoice(index),
                                ),
                                IconButton( // Кнопка удаления
                                  icon: const Icon(Icons.delete, color: Colors.white),
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
              // Иконка плюсика (под выборами)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton( // Кнопка с иконкой
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFA0A0)), // Розовый плюсик
                  onPressed: _addChoice,
                ),
              ),
              const SizedBox(height: 8),
              // Поле ввода музыки
              _buildField('музыка', _musicController),
              const SizedBox(height: 8),
              // Кнопка сохранения
              SizedBox( // Контейнер
                width: double.infinity, // На всю ширину
                child: ElevatedButton( // Кнопка с фоном
                  onPressed: _saveScene,
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