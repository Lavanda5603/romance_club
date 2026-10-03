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
      backgroundColor: const Color(0xFF1A1A1A), // Фон экрана (тёмно-серый, если картинка не загрузится)
      
      // Иконки
      body: Stack(
        children: [
          // Слой для фона
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1A1A), // Цвет фона-заглушки
              
              // Картинка фона
              child: Image.asset(
                'assets/images/main_background.png', // Путь к картинке
                fit: BoxFit.cover, // Растягивает картинку на весь экран
              ),
            ),
          ),

          // Основной контент
          SafeArea(
            child: Column(
              children: [
                // Верхняя панель
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Левая часть: настройки и магазин
                      Row(
                        children: [
                          IconButton( // Настройки
                            icon: const Icon(Icons.settings, color: Color(0xFFD30010), size: 28),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              );
                            },
                          ),
                          IconButton( // Магазин
                            icon: const Icon(Icons.shopping_cart, color: Color(0xFFD30010), size: 28),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ShopScreen()),
                              );
                            },
                          ),
                        ],
                      ),

                      // Центр: название приложения
                      const Text( 
                        'Клуб романтики',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),

                      // Правая часть: профиль
                      IconButton( // Профиль
                        icon: const Icon(Icons.person_outline, color: Color(0xFFD30010), size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Основной блок с текстом и кнопками
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30), // Отступы по бокам
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Центрируем по вертикали
                      children: [
                        // Логотип
                        const Text( 
                          'КЛУБ\nРОМАНТИКИ', // Перенос строки как на макете
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 40,
                            height: 1.1, // Межстрочный интервал
                            fontWeight: FontWeight.w300, // Тонкий шрифт
                            color: Color(0xFFD30010),
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // Подзаголовок
                        const Text( 
                          'Леди Баг и Супер-Кот',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22, 
                            color: Color(0xFFFFA0A0),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        
                        const SizedBox(height: 60), // Отступ перед кнопками

                        // Кнопка играть
                        SizedBox( 
                          width: 220,
                          height: 60, 
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
                              backgroundColor: const Color(0xFFD30010), // Красный фон
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30), 
                              ),
                              elevation: 0, 
                            ),
                            child: const Text(
                              'ИГРАТЬ',
                              style: TextStyle(
                                fontSize: 22, 
                                color: Color(0xFF3F0404), // Темно-красный текст
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20), // Отступ между кнопками

                        // Кнопка разработчик
                        SizedBox( 
                          width: 220,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProgrammerScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD30010),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'разработчик',
                              style: TextStyle(
                                fontSize: 20, 
                                color: Color(0xFF3F0404), 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}