import 'package:flutter/material.dart'; // Импорт Material UI
import 'screens/programmer_screen.dart'; // Импорт экрана режима разработчика
import 'screens/profile_screen.dart'; // Импорт экрана профиля
import 'screens/settings_screen.dart'; // Импорт экрана настроек
import 'screens/episode_select_screen.dart'; // Импорт экрана выбора эпизода
import 'screens/shop_screen.dart'; // Импорт экрана магазина
// import 'services/surreal_service.dart'; // Импорт сервиса SurrealDB
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Инициализация Flutter (нужно для await в main)
  // await SurrealService.connect(); // Подключение к SurrealDB
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

// Главное меню приложения
class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Каркас экрана
      backgroundColor: const Color(0xFF1A1A1A), // Фон экрана
      appBar: AppBar( // Верхняя панель
        backgroundColor: Colors.transparent, // Прозрачный фон
        elevation: 0, // Без тени
        leadingWidth: 100, // Ширина области (чтобы влезли иконки)
        leading: Row( // Горизонтальный список (слева)
          mainAxisSize: MainAxisSize.min, // Минимальная ширина
          children: [
            IconButton( // Кнопка с иконкой
              icon: const Icon(Icons.settings, color: Color(0xFFD30010)), // Настройки
              onPressed: () {
                Navigator.push( // Открыть экран настроек
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            IconButton( // Кнопка с иконкой
              icon: const Icon(Icons.shopping_cart, color: Color(0xFFD30010)), // Магазин
              onPressed: () {
                Navigator.push( // Открыть экран магазина
                  context,
                  MaterialPageRoute(builder: (context) => const ShopScreen()),
                );
              },
            ),
          ],
        ),
        title: const Text( // Текст (маленький, в AppBar)
          'Клуб романтики',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true, // По центру
        actions: [
          IconButton( // Кнопка с иконкой (справа)
            icon: const Icon(Icons.person, color: Color(0xFFD30010)), // Профиль
            onPressed: () {
              Navigator.push( // Открыть экран профиля
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView( // Прокрутка
        child: Padding( // Отступы
          padding: const EdgeInsets.all(16),
          child: Column( // Вертикальный список
            children: [
              const SizedBox(height: 80), // Отступ сверху
              const Text( // Большой логотип
                'КЛУБ РОМАНТИКИ',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold, // Жирность шрифта
                  color: Color(0xFFD30010),
                ),
              ),
              const SizedBox(height: 8),
              const Text( // Подзаголовок
                'Леди Баг и Супер-Кот',
                style: TextStyle(fontSize: 24, color: Color(0xFFD30010)),
              ),
              const SizedBox(height: 80),
              SizedBox( // Контейнер на всю ширину
                width: double.infinity,
                child: ElevatedButton( // Кнопка играть
                  onPressed: () {
                    Navigator.push( // Открыть экран выбора эпизода
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EpisodeSelectScreen(),
                      )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD30010),
                    padding: const EdgeInsets.symmetric(vertical: 20), // Внутренние отступы
                    shape: RoundedRectangleBorder( // Форма кнопки (прямоугольник со скруглёнными углами)
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ИГРАТЬ',
                    style: TextStyle(fontSize: 20, color: Color(0xFF3F0404), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, // На всю ширину (бесконечность)
                child: ElevatedButton( // Кнопка разработчика
                  onPressed: () {
                    Navigator.push( // Открыть экран режима разработчикаа
                      context,
                      MaterialPageRoute(builder: (context) => const ProgrammerScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD30010),
                    padding: const EdgeInsets.symmetric(vertical: 20), // Внутренние отступы
                    shape: RoundedRectangleBorder( // Форма кнопки (прямоугольник со скруглёнными углами)
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'разработчик',
                    style: TextStyle(fontSize: 18, color: Color(0xFF3F0404), fontWeight: FontWeight.bold),
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