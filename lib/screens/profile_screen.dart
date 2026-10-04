import 'package:flutter/material.dart'; // Импорт Material UI
import 'login_screen.dart'; // Импорт экрана авторизации

// Экран профиля игрока
class ProfileScreen extends StatefulWidget {
  // Конструктор класса ProfileScreen
  const ProfileScreen({super.key});

  // Метод createState (создание объекта состояния)
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController; // Контроллер для имени
  final String _registrationDate = ''; // Дата регистрации
  final int _completedEpisodes = 0; // Прогресс
  final int _totalEpisodes = 0; // Всего эпизодов
  double get _progress => _totalEpisodes == 0 ? 0 : _completedEpisodes / _totalEpisodes; // Прогресс в процентах

  @override
  void initState() {
    super.initState();
    // Создание контроллера
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    // Освобождение ресурса контроллера при закрытии экрана
    _nameController.dispose();
    super.dispose();
  }

  // Выход из аккаунта
  Future<void> _logout() async {
    // Показываю диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog( // Всплывающее окно
          title: const Text('Выйти из аккаунта?'),
          content: const Text(
            'Вы точно уверены, что хотите выйти из аккаунта?',
          ),
          actions: [
            TextButton( // Кнопка без фона
              onPressed: () => Navigator.pop(context, false), // Отмена
              child: const Text('Отмена'),
            ),
            TextButton( // Кнопка без фона
              onPressed: () => Navigator.pop(context, true), // Подтверждение
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );

    // Если пользователь подтвердил - выхожу
    if (confirmed == true) {
      if (!mounted) return; // Проверяю, что экран ещё на месте

      // Перехожу на экран авторизации (очищаю стек экранов)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(), // Экран авторизации
        ),
        (route) => false, // Очищаю все экраны
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Каркас экрана
      backgroundColor: const Color(0xFF1A1A1A), // Фон экрана
      
      // Использую Stack, чтобы наложить контент на фон
      body: Stack(
        children: [
          // Слой для фона
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1A1A), // Цвет фона-заглушки
              // Картинка фона
              child: Image.asset(
                'assets/images/main_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Основной контент
          SafeArea(
            child: Column(
              children: [
                // --- ВЕРХНЯЯ ПАНЕЛЬ (AppBar) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Кнопка назад
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFFD30010), size: 28),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      
                      // Заголовок
                      const Text(
                        'Клуб романтики',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      
                      // Пустой контейнер для симметрии
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // --- ОСНОВНОЙ БЛОК (скроллится) ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок "ПРОФИЛЬ" (тонкий)
                        const Center(
                          child: Text(
                            'ПРОФИЛЬ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Аватар
                        Center(
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(0xFF534F50), // Тёмно-серый
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Color(0xFFFFA0A0), // Розовая иконка
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Имя игрока
                        Center(
                          child: TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 24), // Без жирного
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Дата регистрации (розовая)
                        Center(
                          child: Text(
                            'дата регистрации: $_registrationDate',
                            style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Надпись "прогресс" (тонкая)
                        const Text(
                          'прогресс',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300),
                        ),
                        const SizedBox(height: 8),

                        // Текст прогресса (розовый)
                        Text(
                          'пройдено эпизодов: $_completedEpisodes/$_totalEpisodes',
                          style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                        ),
                        const SizedBox(height: 8),

                        // Полоса прогресса (шире и с закруглёнными углами)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10), // Закругление
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: const Color(0xFF534F50),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 20, // Шире
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Надпись "достижения" (тонкая)
                        const Text(
                          'достижения',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300),
                        ),
                        const SizedBox(height: 12),

                        // Иконки достижений с подписями (каждая в Column, чтобы не ехали)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32),
                                SizedBox(height: 4),
                                Text('1', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32),
                                SizedBox(height: 4),
                                Text('2', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32),
                                SizedBox(height: 4),
                                Text('3', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32),
                                SizedBox(height: 4),
                                Text('4', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32),
                                SizedBox(height: 4),
                                Text('5', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Надпись "концовки" (тонкая)
                        const Text(
                          'концовки',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300),
                        ),
                        const SizedBox(height: 12),

                        // Иконки концовок с подписями (каждая в Column, чтобы не ехали)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32),
                                SizedBox(height: 4),
                                Text('Марикот', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32),
                                SizedBox(height: 4),
                                Text('Лука', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.lock_outline, color: Color(0xFFFFA0A0), size: 32),
                                SizedBox(height: 4),
                                Text('', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.lock_outline, color: Color(0xFFFFA0A0), size: 32),
                                SizedBox(height: 4),
                                Text('', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.lock_outline, color: Color(0xFFFFA0A0), size: 32),
                                SizedBox(height: 4),
                                Text('', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Кнопка "выйти" (слева, серая)
                        SizedBox(
                          width: 200,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF534F50), // Серый
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'выйти',
                              style: TextStyle(
                                color: Color(0xFF3F0404), // Тёмно-красный
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),

                        // Пустое пространство снизу
                        const SizedBox(height: 100),
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