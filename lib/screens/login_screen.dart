import 'package:flutter/material.dart'; // Импорт Material UI

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

  @override
  void initState() {
    super.initState();
    _loginController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // Освобождение ресурсов контроллеров при закрытии экрана
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Авторизация
  void _login() {
    // Отправить данные на сервер
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
                'АВТОРИЗАЦИЯ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),
              // Подпись (розовая)
              const Text('логин', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16)),
              const SizedBox(height: 8),
              // Поле логина
              TextField( // Поле ввода
                controller: _loginController,
                style: const TextStyle(color: Colors.white, fontSize: 16), // Белый текст
                decoration: InputDecoration( // Оформление поля
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
              // Подпись (розовая)
              const Text('пароль', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 16)),
              const SizedBox(height: 8),
              // Поле пароля
              TextField( // Поле ввода
                controller: _passwordController,
                obscureText: _obscurePassword, // Скрытие пароля
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration( // Оформление поля
                  suffixIcon: IconButton( // Иконка показать/скрыть
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
              SizedBox( // Контейнер
                width: double.infinity, // На всю ширину
                child: ElevatedButton( // Кнопка с фоном
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD30010), // Красная
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'войти',
                    style: TextStyle(color: Color(0xFF3F0404), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Кнопка регистрация
              Center( // По центру
                child: ElevatedButton( // Кнопка с фоном
                  onPressed: () {
                    // Переход на экран регистрации
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD30010), // Красная
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'регистрация',
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