import 'package:flutter/material.dart'; // Импорт Material UI
import 'screens/programmer_screen.dart'; // Импорт экрана режима разработчика

void main() {
  // Точка входа в приложение
  runApp(const RomanceClubApp());
}

// Корневой виджет приложения
class RomanceClubApp extends StatelessWidget {
  // Конструктор класса RomanceClubApp
  const RomanceClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Клуб Романтики', // Название приложения
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red), // Тема (красная)
      ),
      home: const MainMenu(), // Главный экран (меню)
    );
  }
}

// Главное меню приложения
class MainMenu extends StatelessWidget {
  // Конструктор класса MainMenu
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Чёрный фон
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Выравнивание по центру
          children: [
            // Название игры
            const Text(
              'Клуб Романтики',
              style: TextStyle(
                fontSize: 42, // Размер шрифта
                fontWeight: FontWeight.bold, // Жирный
                color: Colors.red, // Красный цвет
              ),
            ),
            // Подзаголовок
            const Text(
              'Леди Баг и Супер-Кот',
              style: TextStyle(
                fontSize: 32,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 67), // Отступ
            
            // Кнопка играть
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50, // Отступ по горизонтали
                  vertical: 20, // Отступ по вертикали
                ),
              ),
              child: const Text(
                'Играть',
                style: TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 20), // Отступ
            
            // Кнопка режима разработчика
            OutlinedButton(
              onPressed: () {
                // Переход на экран режима разработчика
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProgrammerScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
              ),
              child: const Text(
                'Режим разработчика',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}