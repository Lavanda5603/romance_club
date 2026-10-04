import 'package:flutter/material.dart'; // Импорт Material UI
import '../services/storage_service.dart'; // Импорт сервиса хранения
import '../src/data/repositories/auth_repository_remote.dart'; // Импорт репозитория авторизации
import '../src/data/repositories/progress_repository_remote.dart'; // Импорт репозитория прогресса
import '../src/data/services/auth_grpc_service.dart'; // Импорт gRPC-сервиса авторизации
import '../src/data/services/episode_grpc_service.dart'; // Импорт gRPC-сервиса эпизодов
import '../src/data/services/progress_grpc_service.dart'; // Импорт gRPC-сервиса прогресса
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
  // Данные игрока
  String _login = ''; // Логин
  String _email = ''; // Email
  String _createdAt = ''; // Дата регистрации
  int _completedEpisodes = 0; // Пройдено эпизодов
  int _totalEpisodes = 0; // Всего эпизодов

  // Флаг загрузки
  bool _isLoading = true;

  // gRPC-сервисы
  late AuthGrpcService _authService;
  late EpisodeGrpcService _episodeService;
  late ProgressGrpcService _progressService;

  // Репозитории
  late AuthRepositoryRemote _authRepository;
  late ProgressRepositoryRemote _progressRepository;

  // ID игрока
  String _playerId = '';

  @override
  void initState() {
    super.initState();
    // Создаю gRPC-сервисы
    _authService = AuthGrpcService();
    _episodeService = EpisodeGrpcService();
    _progressService = ProgressGrpcService();
    // Создаю репозитории
    _authRepository = AuthRepositoryRemote(_authService);
    _progressRepository = ProgressRepositoryRemote(_progressService);
    // Загружаю данные
    _loadProfile();
  }

  @override
  void dispose() {
    // Закрываю соединения
    _authService.close();
    _episodeService.close();
    _progressService.close();
    super.dispose();
  }

  // Загрузка профиля
  Future<void> _loadProfile() async {
    try {
      // Загружаю player_id из Storage
      _playerId = await StorageService.loadPlayerId();

      if (_playerId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Загружаю игрока с сервера
      final authModel = await _authRepository.getPlayer(_playerId);

      // Загружаю все эпизоды
      final episodes = await _episodeService.getAllEpisodes();

      // Считаю пройденные эпизоды
      int completed = 0;
      for (final ep in episodes) {
        try {
          final progress = await _progressRepository.getProgress(_playerId, ep.id);
          if (progress.sceneId.isNotEmpty) {
            completed++;
          }
        } catch (e) {
          // Игнорирую
        }
      }

      if (!mounted) return;

      setState(() {
        _login = authModel.login;
        _email = authModel.email;
        _createdAt = authModel.createdAt;
        _completedEpisodes = completed;
        _totalEpisodes = episodes.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Прогресс в процентах
  double get _progress => _totalEpisodes == 0 ? 0 : _completedEpisodes / _totalEpisodes;

  // Форматирование даты
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return dateStr;
    }
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
      // Удаляю player_id из Storage
      await StorageService.savePlayerId('');

      if (!mounted) return;

      // Перехожу на экран авторизации
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFD30010)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Заголовок
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
                                  backgroundColor: const Color(0xFF534F50),
                                  child: const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Color(0xFFFFA0A0),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Логин
                              Center(
                                child: Text(
                                  _login.isNotEmpty ? _login : 'игрок',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 24),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Email
                              Center(
                                child: Text(
                                  _email,
                                  style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Дата регистрации
                              Center(
                                child: Text(
                                  'дата регистрации: ${_formatDate(_createdAt)}',
                                  style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Прогресс
                              const Text(
                                'прогресс',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'пройдено эпизодов: $_completedEpisodes/$_totalEpisodes',
                                style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _progress,
                                  backgroundColor: const Color(0xFF534F50),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  minHeight: 20,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Достижения
                              const Text(
                                'достижения',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300),
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(children: [Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('1', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12))]),
                                  Column(children: [Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('2', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12))]),
                                  Column(children: [Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('3', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12))]),
                                  Column(children: [Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('4', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12))]),
                                  Column(children: [Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('5', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 12))]),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Концовки
                              const Text(
                                'концовки',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300),
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(children: [Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('Марикот', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10))]),
                                  Column(children: [Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('Лука', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10))]),
                                  Column(children: [Icon(Icons.lock_outline, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10))]),
                                  Column(children: [Icon(Icons.lock_outline, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10))]),
                                  Column(children: [Icon(Icons.lock_outline, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10))]),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Кнопка выйти
                              SizedBox(
                                width: 200,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _logout,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF534F50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'выйти',
                                    style: TextStyle(
                                      color: Color(0xFF3F0404),
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),

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