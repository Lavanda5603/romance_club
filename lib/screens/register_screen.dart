import 'package:flutter/material.dart'; // Импорт Material UI
import 'login_screen.dart'; // Импорт экрана авторизации
import '../src/data/repositories/auth_repository_remote.dart'; // Импорт репозитория
import '../src/data/services/auth_grpc_service.dart'; // Импорт gRPC-сервиса
import '../services/storage_service.dart'; // Импорт сервиса хранения

// Экран регистрации
class RegisterScreen extends StatefulWidget {
  // Конструктор класса RegisterScreen
  const RegisterScreen({super.key});

  // Метод createState (создание объекта состояния)
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late TextEditingController _loginController; // Контроллер для логина
  late TextEditingController _emailController; // Контроллер для email
  late TextEditingController _passwordController; // Контроллер для пароля
  late TextEditingController _confirmPasswordController; // Контроллер для повторного пароля
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
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Создаю gRPC-сервис и репозиторий
    _service = AuthGrpcService();
    _repository = AuthRepositoryRemote(_service);
  }

  @override
  void dispose() {
    // Освобождение ресурсов контроллеров при закрытии экрана
    _loginController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _service.close();
    super.dispose();
  }

  // Регистрация
  Future<void> _register() async {
    // Проверяю, что поля не пустые
    if (_loginController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    // Проверяю, что пароли совпадают
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароли не совпадают')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Отправляю запрос на сервер
      final result = await _repository.register(
        login: _loginController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        // Сохраняю player_id локально
        await StorageService.savePlayerId(result.playerId);

        if (!mounted) return;

        // Успех - переход на логин
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Регистрация успешна! Добро пожаловать, ${result.login}!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
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

  // Поле ввода (вспомогательный метод)
  Widget _buildField(String label, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Подпись (розовая)
        Text(label, style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16)),
        const SizedBox(height: 8),
        // Поле ввода
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
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
      ],
    );
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
                            'РЕГИСТРАЦИЯ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w300, // Тонкий шрифт
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Поля регистрации
                        _buildField('логин', _loginController),
                        _buildField('email', _emailController),
                        _buildField('пароль', _passwordController, isPassword: true),
                        _buildField('повторите пароль', _confirmPasswordController, isPassword: true),
                        
                        const SizedBox(height: 8),

                        // Кнопка зарегистрироваться
                        Center(
                          child: SizedBox(
                            width: 260,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
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
                                      'зарегистрироваться',
                                      style: TextStyle(
                                        color: Color(0xFF3F0404), 
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),

                        // Кнопка вход
                        Center(
                          child: SizedBox(
                            width: 160,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
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
                                'вход',
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