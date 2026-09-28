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
                controller: _textController, // Контроллер
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
              if (widget.choice == null || widget.choice!.actions.isEmpty)
                const Text('нет действий', style: TextStyle(color: Colors.white))
              else
                ListView.builder( // Список
                  shrinkWrap: true, // Чтобы ListView не занимал весь экран
                  physics: const NeverScrollableScrollPhysics(), // Отключаю скролл у ListView
                  itemCount: widget.choice!.actions.length,
                  itemBuilder: (context, index) {
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
                              'действие "..."',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                          // Кнопка редактирования
                          IconButton( // Кнопка с иконкой
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              // Редактировать действие
                            },
                          ),
                          // Кнопка удаления
                          IconButton( // Кнопка с иконкой
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () {
                              // Удалить действие
                            },
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
                  onPressed: () {
                    // Добавить действие
                  },
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