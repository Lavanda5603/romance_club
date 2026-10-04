import 'package:flutter/material.dart'; // Импорт Material UI
import 'screens/main_menu_screen.dart'; // Импорт главного меню
import 'screens/login_screen.dart'; // Импорт экрана авторизации
import 'services/storage_service.dart'; // Импорт сервиса хранения

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
      home: const SplashScreen(), // Стартовый экран
    );
  }
}

// Стартовый экран (проверяет, залогинен ли игрок)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin(); // Проверяю авторизацию
  }

  // Проверка player_id в Storage
  Future<void> _checkLogin() async {
    // Загружаю player_id
    final playerId = await StorageService.loadPlayerId();

    if (!mounted) return;

    // Если player_id есть - на главное меню, иначе на логин
    if (playerId.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainMenu()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A1A), // Фон
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFD30010)), // Загрузка
      ),
    );
  }
}