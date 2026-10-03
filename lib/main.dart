import 'package:flutter/material.dart'; // Импорт Material UI
import 'screens/main_menu_screen.dart'; // Импорт главного меню

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Инициализация Flutter
  runApp(const RomanceClubApp()); // Запуск приложения
}

// Корневой виджет приложения
class RomanceClubApp extends StatelessWidget {
  const RomanceClubApp({super.key}); // Виджет без состояния

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Клуб Романтики',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD30010)), // Тема
      ),
      home: const MainMenu(), // Главное меню
    );
  }
}