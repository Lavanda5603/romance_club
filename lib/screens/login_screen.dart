import 'package:flutter/material.dart'; // Импорт Material UI
import 'register_screen.dart'; // Импорт экрана регистрации
import 'main_menu_screen.dart'; // Импорт главного меню
import '../src/data/repositories/auth_repository_remote.dart'; // Импорт репозитория
import '../src/data/services/auth_grpc_service.dart'; // Импорт gRPC-сервиса
import '../services/storage_service.dart'; // Импорт сервиса хранения

// Экран авторизации
class LoginScreen extends StatefulWidget {
  // Конструктор класса LoginScreen
  const LoginScreen({super.key});

  // Метод createState (создание объекта состояния)
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _loginController; // Контроллер для логина
  late TextEditingController _passwordController; // Контроллер для пароля
  bool _obscurePassword = true; // Флаг видимости пароля
  bool _isLoading = false; // Флаг загрузки

  // gRPC-сервис
  late AuthGrpcService _service;

  // Репозиторий
  late AuthRepositoryRemote _repository;

  @override
  void initState() {
    super.initState();
    // Создание контроллеров
    _loginController = TextEditingController();
    _passwordController = TextEditingController();

    // Создаю gRPC-сервис и репозиторий
    _service = AuthGrpcService();
    _repository = AuthRepositoryRemote(_service);
  }

  @override
  void dispose() {
    // Освобождение ресурсов контроллеров при закрытии экрана
    _loginController.dispose();
    _passwordController.dispose();
    _service.close();
    super.dispose();
  }

  // Авторизация
  Future<void> _login() async {
    // Проверяю, что поля не пустые
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Отправляю запрос на сервер
      final result = await _repository.login(
        login: _loginController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        // Сохраняю player_id локально
        await StorageService.savePlayerId(result.playerId);

        if (!mounted) return;

        // Успех — переход на главное меню
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Добро пожаловать, ${result.login}!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainMenu()),
        );
      } else {
        // Ошибка
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
                // Верхняя панель
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

                // Основной блок
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок
                        const Center(
                          child: Text(
                            'АВТОРИЗАЦИЯ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w300, // Тонкий шрифт
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Подпись
                        const Text('логин', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16)),
                        const SizedBox(height: 8),
                        
                        // Поле логина
                        TextField(
                          controller: _loginController,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFD30010)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Подпись
                        const Text('пароль', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16)),
                        const SizedBox(height: 8),
                        
                        // Поле пароля
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFD30010)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Кнопка войти
                        Center(
                          child: SizedBox(
                            width: 160,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD30010),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'войти',
                                      style: TextStyle(
                                        color: Color(0xFF3F0404), 
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),

                        // Кнопка регистрация
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
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
                                'регистрация',
                                style: TextStyle(
                                  color: Color(0xFF3F0404), 
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold
                                ),
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