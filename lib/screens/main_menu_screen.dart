import 'package:flutter/material.dart'; // Импорт Material UI
import 'programmer_screen.dart'; // Импорт экрана режима разработчика
import 'profile_screen.dart'; // Импорт экрана профиля
import 'settings_screen.dart'; // Импорт экрана настроек
import 'episode_select_screen.dart'; // Импорт экрана выбора эпизода
import 'shop_screen.dart'; // Импорт экрана магазина

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
        leadingWidth: 100, // Ширина области
        leading: Row( // Горизонтальный список (слева)
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton( // Настройки
              icon: const Icon(Icons.settings, color: Color(0xFFD30010)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            IconButton( // Магазин
              icon: const Icon(Icons.shopping_cart, color: Color(0xFFD30010)),
              onPressed: () {
                Navigator.push(
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
        centerTitle: true,
        actions: [
          IconButton( // Профиль
            icon: const Icon(Icons.person, color: Color(0xFFD30010)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView( // Прокрутка
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Text( // Логотип
                'КЛУБ РОМАНТИКИ',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD30010),
                ),
              ),
              const SizedBox(height: 8),
              const Text( // Подзаголовок
                'Леди Баг и Супер-Кот',
                style: TextStyle(fontSize: 24, color: Color(0xFFD30010)),
              ),
              const SizedBox(height: 80),
              SizedBox( // Кнопка играт
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EpisodeSelectScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD30010),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
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
              SizedBox( // Кнопка разработчик
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProgrammerScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD30010),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
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