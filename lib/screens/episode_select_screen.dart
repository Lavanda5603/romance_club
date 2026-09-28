import 'package:flutter/material.dart'; // Импорт Material UI

// Экран выбора эпизода
class EpisodeSelectScreen extends StatefulWidget {
  // Конструктор класса EpisodeSelectScreen
  const EpisodeSelectScreen({super.key});

  // Метод createState (создание объекта состояния)
  @override
  State<EpisodeSelectScreen> createState() => _EpisodeSelectScreenState();
}

class _EpisodeSelectScreenState extends State<EpisodeSelectScreen> {
  // Список эпизодов
  final List<String> _episodes = [];

  // Выбранный эпизод
  int _selectedIndex = 0;

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
      body: Padding( // Отступы
        padding: const EdgeInsets.all(16),
        child: Column( // Вертикальный список
          children: [
            const Text( // Большой заголовок
              'ВЫБОР ЭПИЗОДА',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            // Список эпизодов
            Expanded( // Растягивание
              child: _episodes.isEmpty
                  ? const Center(child: Text('нет эпизодов', style: TextStyle(color: Colors.white))) // Если эпизодов нет
                  : ListView.builder( // Список
                      itemCount: _episodes.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedIndex; // Выбран ли эпизод
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton( // Кнопка с фоном
                            onPressed: () {
                              setState(() {
                                _selectedIndex = index; // Выбираю эпизод
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? const Color(0xFFD30010) : const Color(0xFF333333),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _episodes[index], // Название эпизода
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            // Кнопка продолжить
            SizedBox( // Контейнер
              width: double.infinity, // На всю ширину
              child: ElevatedButton( // Кнопка с фоном
                onPressed: () {
                  // Переход на игровой экран
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD30010),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ПРОДОЛЖИТЬ',
                  style: TextStyle(color: Color(0xFF3F0404), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Кнопка сбросить прогресс
            SizedBox( // Контейнер
              width: double.infinity, // На всю ширину
              child: ElevatedButton( // Кнопка с фоном
                onPressed: () {
                  // Сброс прогресса
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'СБРОСИТЬ ПРОГРЕСС',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}