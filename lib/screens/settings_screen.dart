import 'package:flutter/material.dart'; // Импорт Material UI

// Экран настроек
class SettingsScreen extends StatefulWidget {
  // Конструктор класса SettingsScreen
  const SettingsScreen({super.key});

  // Метод createState (создание объекта состояния)
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _musicVolume = 0.6; // Громкость музыки (0.0 - 1.0)
  double _soundVolume = 0.3; // Громкость звуков (0.0 - 1.0)

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text( // Большой заголовок
              'НАСТРОЙКИ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            // Подпись (розовая)
            const Text(
              'Громкость музыки:',
              style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Слайдер музыки и процент
            Row( // Горизонтальный список
              children: [
                Expanded( // Растягивание
                  child: Slider( // Слайдер
                    value: _musicVolume,
                    onChanged: (value) {
                      setState(() {
                        _musicVolume = value; // Обновляю громкость
                      });
                    },
                    activeColor: Colors.white, // Белая активная
                    inactiveColor: Colors.grey, // Серая неактивная
                  ),
                ),
                Text(
                  '${(_musicVolume * 100).toInt()}%', // Процент
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Подпись (розовая)
            const Text(
              'Громкость звуков:',
              style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Слайдер звуков и процент
            Row( // Горизонтальный список
              children: [
                Expanded( // Растягивание
                  child: Slider( // Слайдер
                    value: _soundVolume,
                    onChanged: (value) {
                      setState(() {
                        _soundVolume = value; // Обновляю громкость
                      });
                    },
                    activeColor: Colors.white, // Белая активная
                    inactiveColor: Colors.grey, // Серая неактивная
                  ),
                ),
                Text(
                  '${(_soundVolume * 100).toInt()}%', // Процент
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Кнопка сохранить
            SizedBox( // Контейнер
              width: double.infinity, // На всю ширину
              child: ElevatedButton( // Кнопка с фоном
                onPressed: () {
                  // Сохранить настройки
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD30010), // Красная
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
    );
  }
}