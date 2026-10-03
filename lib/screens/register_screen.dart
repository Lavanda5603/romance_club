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
    return Column( // Вертикальный список
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Подпись (розовая)
        Text(label, style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16)),
        const SizedBox(height: 8),
        // Поле ввода
        TextField( // Поле ввода
          controller: controller,
          obscureText: isPassword && _obscurePassword, // Скрытие пароля
          style: const TextStyle(color: Colors.white, fontSize: 16), // Белый текст
          decoration: InputDecoration( // Оформление поля
            suffixIcon: isPassword // Если пароль - иконка показать/скрыть
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
              borderRadius: BorderRadius.circular(12), // Круглые углы
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white), // Белая рамка
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD30010)), // Красная при фокусе
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
      body: SingleChildScrollView( // Прокрутка
        child: Padding( // Отступы
          padding: const EdgeInsets.all(16),
          child: Column( // Вертикальный список
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text( // Большой заголовок
                'РЕГИСТРАЦИЯ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              // Поля регистрации
              _buildField('логин', _loginController),
              _buildField('email', _emailController),
              _buildField('пароль', _passwordController, isPassword: true),
              _buildField('повторите пароль', _confirmPasswordController, isPassword: true),
              const SizedBox(height: 16),
              // Кнопка зарегестрироваться
              SizedBox( // Контейнер
                width: double.infinity, // На всю ширину
                child: ElevatedButton( // Кнопка с фоном
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD30010), // Красная
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'зарегестрироваться',
                          style: TextStyle(color: Color(0xFF3F0404), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Кнопка вход
              Center( // По центру
                child: ElevatedButton( // Кнопка с фоном
                  onPressed: () {
                    Navigator.push( // Открыть экран
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(), // Экран авторизации
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD30010), // Красная
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'вход',
                    style: TextStyle(color: Color(0xFF3F0404), fontSize: 16, fontWeight: FontWeight.bold),
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