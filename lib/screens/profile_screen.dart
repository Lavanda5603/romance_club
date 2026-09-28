import 'package:flutter/material.dart'; // Импорт Material UI

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
  String _registrationDate = ''; // Дата регистрации
  int _completedEpisodes = 0; // Прогресс
  int _totalEpisodes = 0; // Всего эпизодов
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
            children: [
              const Text( // Большой заголовок
                'ПРОФИЛЬ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              // Аватар
              CircleAvatar( // Круглый аватар
                radius: 60,
                backgroundColor: const Color(0xFF333333), // Тёмный фон
                child: Icon(
                  Icons.person, // Иконка
                  size: 80,
                  color: Color(0xFFFFA0A0), // Розовая
                ),
              ),
              const SizedBox(height: 16),
              // Имя игрока
              TextField( // Поле ввода
                controller: _nameController, // Контроллер
                textAlign: TextAlign.center, // По центру
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), // Белый
                decoration: const InputDecoration( // Оформление
                  border: InputBorder.none, // Без рамки
                  isDense: true, // Компактнее
                ),
              ),
              const SizedBox(height: 8),
              // Дата регистрации (розовая)
              Text(
                'дата регистрации: $_registrationDate',
                style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
              ),
              const SizedBox(height: 32),
              // Надпись (белая)
              const Align( // Выравнивание
                alignment: Alignment.centerLeft,
                child: Text(
                  'прогресс',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              // Текст прогресса (розовый)
              Align( // Выравнивание
                alignment: Alignment.centerLeft,
                child: Text(
                  'пройдено эпизодов: $_completedEpisodes/$_totalEpisodes',
                  style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              // Полоса прогресса (белая)
              LinearProgressIndicator( // Полоса прогресса
                value: _progress,
                backgroundColor: const Color(0xFF333333), // Тёмный фон
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), // Белая полоса
                minHeight: 12,
              ),
              const SizedBox(height: 32),
              // Надпись (белая)
              const Align( // Выравнивание
                alignment: Alignment.centerLeft,
                child: Text(
                  'достижения',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              // Иконки достижений (розовые)
              Row( // Горизонтальный список
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32), // Алмаз 1
                  Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32), // Алмаз 2
                  Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32), // Алмаз 3
                  Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32), // Алмаз 4
                  Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32), // Алмаз 5
                ],
              ),
              const SizedBox(height: 8),
              // Подписи достижений (розовые)
              const Row( // Горизонтальный список
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('1', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12)), // Достижение 1
                  Text('2', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12)), // Достижение 2
                  Text('3', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12)), // Достижение 3
                  Text('4', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12)), // Достижение 4
                  Text('5', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12)), // Достижение 5
                ],
              ),
              const SizedBox(height: 32),
              // Надпись (белая)
              const Align( // Выравнивание
                alignment: Alignment.centerLeft,
                child: Text(
                  'концовки',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              // Иконки концовок (розовые)
              Row( // Горизонтальный список
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32), // Марикот
                  Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32), // Адринетт
                  Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32), // Супербаг
                  Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32), // АдриБаг
                  Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32), // Лука
                ],
              ),
              const SizedBox(height: 8),
              // Подписи концовок (розовые)
              const Row( // Горизонтальный список
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Марикот', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10)), // Концовка 1
                  Text('Адринетт', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10)), // Концовка 2
                  Text('Супербаг', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10)), // Концовка 3
                  Text('АдриБаг', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10)), // Концовка 4
                  Text('Лука', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10)), // Концовка 5
                ],
              ),
              const SizedBox(height: 32),
              // Кнопка выйти
              SizedBox( // Контейнер
                width: double.infinity, // На всю ширину
                child: ElevatedButton( // Кнопка с фоном
                  onPressed: () {
                    // Выход из аккаунта
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333), // Тёмно-серый
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'выйти',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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