import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../generated/scene.pb.dart'; // Импорт Protobuf-модели Scene

// Игровой экран
class GameScreen extends StatefulWidget {
  final Episode episode; // Эпизод

  // Конструктор класса GameScreen
  const GameScreen({
    super.key,
    required this.episode,
  });

  // Метод createState (создание объекта состояния)
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _currentSceneIndex = 0; // Индекс текущей сцены
  Scene? _currentScene; // Текущая сцена
  int _points = 0; // Баллы

  @override
  void initState() {
    super.initState();
    // Загружаю первую сцену при открытии экрана
    if (widget.episode.scenes.isNotEmpty) {
      _currentScene = widget.episode.scenes[0];
    }
  }

  // Переход к сцене по ID
  void _goToScene(int sceneId) {
    setState(() {
      // Ищу сцену с таким ID
      for (int i = 0; i < widget.episode.scenes.length; i++) {
        if (widget.episode.scenes[i].id == sceneId) {
          _currentSceneIndex = i; // Меняю индекс
          _currentScene = widget.episode.scenes[i]; // Меняю сцену
          return;
        }
      }
    });
  }

  // Обработка выбора
  void _onChoiceSelected(int index) {
    // Если сцены нет - выхожу
    if (_currentScene == null) return;

    // Беру выбор
    final choice = _currentScene!.choices[index];

    // Прохожу по всем действиям выбора
    for (final action in choice.actions) {
      if (action.type == 'nextScene') {
        // Переход к сцене
        _goToScene(action.sceneId);
      } else if (action.type == 'changeCounter') {
        // Изменение баллов
        setState(() {
          _points += action.counterValue;
        });
      } else if (action.type == 'changeFlag') {
        // Установка флага (потом)
      }
    }
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
          if (_currentScene != null && _currentScene!.character.isNotEmpty)
            Align( // Выравнивание
              alignment: _getAlignment(
                _currentScene!.characterPosition.isNotEmpty
                    ? _currentScene!.characterPosition
                    : 'center',
              ), // Позиция персонажа
              child: FractionallySizedBox( // Размер в долях
                widthFactor: 0.65, // 65% ширины
                heightFactor: 0.65, // 65% высоты
                // Image.asset('assets/images/персонаж.png')
                child: Icon(Icons.person, size: 300, color: Colors.red[300]), // Иконка
              ),
            ),
          // Текст и выборы
          Align( // Выравнивание
            alignment: _getAlignment(
              _currentScene?.textPosition.isNotEmpty == true
                  ? _currentScene!.textPosition
                  : 'bottom',
            ), // Позиция текста
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
                      _currentScene?.texts.isNotEmpty == true
                          ? _currentScene!.texts.first // Первый текст сцены
                          : 'нет текста',
                      style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 16), // Серый текст
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Выборы (динамические)
                  if (_currentScene != null)
                    ..._currentScene!.choices.asMap().entries.map((entry) {
                      final index = entry.key; // Индекс выбора
                      final choice = entry.value; // Выбор
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector( // Обработка нажатия
                          onTap: () => _onChoiceSelected(index), // Нажатие на выбор
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
                                    choice.text, // Текст выбора
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
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}