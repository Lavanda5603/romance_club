import 'package:flutter/material.dart' hide Action; // Импорт Material UI (скрываю Action из Flutter)
import '../generated/action.pb.dart'; // Импорт Protobuf-модели Action

// Экран редактирования действия
class ActionEditorScreen extends StatefulWidget {
  final Action? action; // Действие (null, если новое)
  final String defaultTitle; // Название по умолчанию
  final Function(Action) onSave; // Функция, вызывается при сохранении

  // Конструктор класса ActionEditorScreen
  const ActionEditorScreen({
    super.key,
    this.action,
    this.defaultTitle = '',
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
  late TextEditingController _titleController; // Контроллер для поля названия
  late TextEditingController _counterNameController; // Контроллер для поля имени счётчика
  late TextEditingController _counterValueController; // Контроллер для поля значения счётчика
  late TextEditingController _flagNameController; // Контроллер для поля имени флага

  @override
  void initState() {
    super.initState();
    // Если редактирую существующее действие, то беру его тип
    if (widget.action != null) {
      _selectedType = widget.action!.type;
    }

    // Создание контроллеров
    _titleController = TextEditingController(
      text: widget.action?.title ?? widget.defaultTitle,
    );
    _sceneIdController = TextEditingController(
      text: widget.action?.sceneId.toString() ?? '',
    );
    _counterNameController = TextEditingController(
      text: widget.action?.counterName ?? '',
    );
    _counterValueController = TextEditingController(
      text: widget.action?.counterValue.toString() ?? '',
    );
    _flagNameController = TextEditingController(
      text: widget.action?.flagName ?? '',
    );
  }

  @override
  void dispose() {
    // Освобождение ресурсов всех контроллеров при закрытии экрана
    _sceneIdController.dispose();
    _titleController.dispose();
    _counterNameController.dispose();
    _counterValueController.dispose();
    _flagNameController.dispose();
    super.dispose();
  }

  // Сохранение действия
  void _saveAction() {
    // Создаю Protobuf-модель Action
    final newAction = Action(
      type: _selectedType,
      title: _titleController.text,
    );

    // В зависимости от типа заполняю нужные поля
    if (_selectedType == 'nextScene') {
      newAction.sceneId = int.tryParse(_sceneIdController.text) ?? 0;
    } else if (_selectedType == 'changeCounter') {
      newAction.counterName = _counterNameController.text;
      newAction.counterValue = int.tryParse(_counterValueController.text) ?? 0;
    } else if (_selectedType == 'changeFlag') {
      newAction.flagName = _flagNameController.text;
    }

    // Вызываю функцию onSave
    widget.onSave(newAction);

    // Закрываю экран
    Navigator.pop(context);
  }

  // Виджет поля ввода с рамкой (вспомогательный метод)
  Widget _buildField(TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField( // Поле ввода
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
    );
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
                        // Заголовок в стиле других экранов
                        const Center(
                          child: Text(
                            'РЕДАКТИРОВАНИЕ\nДЕЙСТВИЯ',
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

                        // Поле ввода названия действия (розовое)
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
                          'тип действия',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),

                        // Выпадающий список типа действия
                        DropdownButtonFormField<String>(
                          initialValue: _selectedType,
                          dropdownColor: const Color(0xFF1A1A1A),
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
                            suffixIcon: const Icon(Icons.radio_button_unchecked, color: Colors.white),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'nextScene', child: Text('перейти к сцене')),
                            DropdownMenuItem(value: 'changeCounter', child: Text('баллы')),
                            DropdownMenuItem(value: 'changeFlag', child: Text('флаг')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Надпись
                        const Text(
                          'параметры',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 16),

                        // Поля в зависимости от типа действия
                        if (_selectedType == 'nextScene') ...[
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'перейти к сцене',
                                  style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 14),
                                ),
                              ),
                              Expanded(child: _buildField(_sceneIdController, keyboardType: TextInputType.number)),
                            ],
                          ),
                        ] else if (_selectedType == 'changeCounter') ...[
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'баллы (кол-во, счётчик',
                                  style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 14),
                                ),
                              ),
                              Expanded(child: _buildField(_counterNameController)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildField(_counterValueController, keyboardType: TextInputType.number)),
                            ],
                          ),
                        ] else if (_selectedType == 'changeFlag') ...[
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'флаг',
                                  style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 14),
                                ),
                              ),
                              Expanded(child: _buildField(_flagNameController)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Кнопка сохранить
                        SizedBox(
                          width: 200, // Уже
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _saveAction,
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