import 'package:flutter/material.dart'; // Импорт Material UI
import 'programmer_screen.dart'; // Импорт экрана режима разработчика
import 'profile_screen.dart'; // Импорт экрана профиля
import 'settings_screen.dart'; // Импорт экрана настроек
import 'episode_select_screen.dart'; // Импорт экрана выбора эпизода
import 'shop_screen.dart'; // Импорт экрана магазина
import '../services/storage_service.dart'; // Импорт сервиса хранения
import '../src/data/services/auth_grpc_service.dart'; // Импорт gRPC-сервиса авторизации
import '../src/data/repositories/auth_repository_remote.dart'; // Импорт репозитория авторизации

// Главное меню приложения
class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  bool _isAdmin = false; // Админ ли игрок
  bool _isLoading = true; // Флаг загрузки

  // gRPC-сервис и репозиторий
  late AuthGrpcService _authService;
  late AuthRepositoryRemote _authRepository;

  @override
  void initState() {
    super.initState();
    // Создаю сервис и репозиторий
    _authService = AuthGrpcService();
    _authRepository = AuthRepositoryRemote(_authService);
    // Загружаю игрока
    _loadPlayer();
  }

  @override
  void dispose() {
    _authService.close();
    super.dispose();
  }

  // Загрузка игрока (для проверки админа)
  Future<void> _loadPlayer() async {
    try {
      // Загружаю player_id
      final playerId = await StorageService.loadPlayerId();

      if (playerId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Запрашиваю игрока с сервера
      final authModel = await _authRepository.getPlayer(playerId);

      if (!mounted) return;
      setState(() {
        _isAdmin = authModel.isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Каркас экрана
      backgroundColor: const Color(0xFF1A1A1A), // Фон экрана
      body: Stack(
        children: [
          // Слой для фона
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1A1A),
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
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Логотип
                        const Text(
                          'КЛУБ\nРОМАНТИКИ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 40,
                            height: 1.1,
                            fontWeight: FontWeight.w300,
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

                        const SizedBox(height: 60),

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
                              backgroundColor: const Color(0xFFD30010),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'ИГРАТЬ',
                              style: TextStyle(
                                fontSize: 22,
                                color: Color(0xFF3F0404),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Кнопка разработчик (активна только для админа)
                        SizedBox(
                          width: 220,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: (_isLoading || !_isAdmin)
                                ? null // Серая, неактивная
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ProgrammerScreen()),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD30010),
                              // Серая для неактивной
                              disabledBackgroundColor: const Color(0xFF534F50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: Center(
                              child: Text(
                                _isAdmin ? 'разработчик' : 'разработчик (только админ)',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFF3F0404),
                                  fontWeight: FontWeight.bold,
                                ),
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