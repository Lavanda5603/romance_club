import 'package:flutter/material.dart'; // Импорт Material UI

// Игровой экран
class GameScreen extends StatefulWidget {
  // Конструктор класса GameScreen
  const GameScreen({super.key});

  // Метод createState (создание объекта состояния)
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String _sceneText = ''; // Текст сцены
  final List<String> _choices = []; // Выборы
  int _points = 0; // Баллы
  String _characterPosition = 'center'; // Позиция персонажа
  String _textPosition = 'bottom'; // Позиция текста
  bool _hasCharacter = false; // Есть ли персонаж

  // Обработка выбора
  void _onChoiceSelected(int index) {
    setState(() {
      // Логика выбора
      _choices.clear(); // Убираю выборы
    });
  }

  // Получаю Alignment для позиции
  Alignment _getAlignment(String position) {
    switch (position) {
      case 'top':
        return Alignment.topCenter;
      case 'bottom':
        return Alignment.bottomCenter;
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Каркас экрана
      backgroundColor: const Color(0xFF1A1A1A), // Фон экрана
      appBar: AppBar( // Верхняя панель
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton( // Кнопка с иконкой
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD30010)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text( // Текст (маленький, в AppBar)
          'Клуб романтики',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: Stack( // Стопка виджетов
        children: [
          // Фон сцены
          Container(
            decoration: const BoxDecoration(color: Color(0xFF333333)),
          ),
          // Персонаж (если есть)
          if (_hasCharacter)
            Align( // Выравнивание
              alignment: _getAlignment(_characterPosition), // Позиция персонажа
              child: FractionallySizedBox( // Размер в долях
                widthFactor: 0.65, // 65% ширины
                heightFactor: 0.65, // 65% высоты
                // Image.asset('assets/images/персонаж.png')
                child: Icon(Icons.person, size: 300, color: Colors.red[300]), // Иконка
              ),
            ),
          // Текст и выборы
          Align( // Выравнивание
            alignment: _getAlignment(_textPosition), // Позиция текста
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Минимальная высота
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Текст сцены (розовое облачко)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA0A0), // Розовый
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _sceneText,
                      style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 16), // Серый текст
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Выборы (динамические)
                  ..._choices.asMap().entries.map((entry) {
                    final index = entry.key; // Индекс выбора
                    final choice = entry.value; // Текст выбора
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA0A0), // Розовый
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            // Текст выбора
                            Expanded(
                              child: Text(
                                choice,
                                style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 14), // Серый текст
                              ),
                            ),
                            // Кругляшок (серый)
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.grey, // Серый
                                shape: BoxShape.circle, // Круг
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}