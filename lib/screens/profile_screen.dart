import 'package:grpc/grpc.dart';
import '../src/data/services/rpc_policy.dart';
import '../generated/episode.pb.dart';
import '../src/domain/repositories/auth_repository.dart';
import '../src/domain/repositories/progress_repository.dart';
import '../src/domain/repositories/achievement_repository.dart';
import 'package:flutter/material.dart'; // Импорт Material UI
import '../services/storage_service.dart'; // Импорт сервиса хранения
import '../src/data/repositories/auth_repository_remote.dart'; // Импорт репозитория авторизации
import '../src/data/repositories/progress_repository_remote.dart'; // Импорт репозитория прогресса
import '../src/data/repositories/achievement_repository_remote.dart'; // Импорт репозитория достижений
import '../src/data/services/auth_grpc_service.dart'; // Импорт gRPC-сервиса авторизации
import '../src/data/services/episode_grpc_service.dart'; // Импорт gRPC-сервиса эпизодов
import '../src/data/services/progress_grpc_service.dart'; // Импорт gRPC-сервиса прогресса
import '../src/data/services/achievement_grpc_service.dart'; // Импорт gRPC-сервиса достижений
import 'login_screen.dart'; // Импорт экрана авторизации

// Экран профиля игрока
class ProfileScreen extends StatefulWidget {
  // Конструктор
  final AuthRepository? authRepository;
  final ProgressRepository? progressRepository;
  final AchievementRepository? achievementRepository;
  final EpisodeGrpcService? episodeService;
  final Future<String> Function()? loadPlayerId;
  const ProfileScreen({super.key, this.authRepository, this.progressRepository,
    this.achievementRepository, this.episodeService, this.loadPlayerId});

  // Создаю состояние экрана
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

  // Список всех достижений (ключ - название)
  final List<Map<String, String>> _allAchievements = [
    {'key': 'all_episodes', 'title': 'Все эпизоды'},
    {'key': 'all_endings', 'title': 'Все концовки'},
    {'key': 'max_points', 'title': 'Максимум баллов'},
    {'key': 'secret_scene', 'title': 'Секретная сцена'},
    {'key': 'all_friends', 'title': 'Все друзья'},
  ];

  // Множество открытых достижений
  final Set<String> _unlockedAchievements = {};

  // Флаг загрузки
  bool _isLoading = true;
  bool _statsLoading = true;
  bool _achievementsLoading = true;
  String? _profileError;
  String? _statsError;
  String? _achievementsError;

  // gRPC-сервисы
  late AuthGrpcService _authService;
  late EpisodeGrpcService _episodeService;
  late ProgressGrpcService _progressService;
  late AchievementGrpcService _achievementService;

  // Репозитории
  late AuthRepository _authRepository;
  late ProgressRepository _progressRepository;
  late AchievementRepository _achievementRepository;

  // ID игрока
  String _playerId = '';

  @override
  void initState() {
    super.initState();
    // Создаю gRPC-сервисы
    _authService = AuthGrpcService();
    _episodeService = widget.episodeService ?? EpisodeGrpcService();
    _progressService = ProgressGrpcService();
    _achievementService = AchievementGrpcService();
    // Создаю репозитории
    _authRepository = widget.authRepository ?? AuthRepositoryRemote(_authService);
    _progressRepository = widget.progressRepository ?? ProgressRepositoryRemote(_progressService);
    _achievementRepository = widget.achievementRepository ?? AchievementRepositoryRemote(_achievementService);
    // Загружаю данные
    _loadProfile();
  }

  @override
  void dispose() {
    // Закрываю соединения
    _authService.close();
    if (widget.episodeService == null) _episodeService.close();
    _progressService.close();
    _achievementService.close();
    super.dispose();
  }

  // Независимые части профиля загружаю одновременно
  Future<void> _loadProfile() async {
    try {
      _playerId = await (widget.loadPlayerId ?? StorageService.loadPlayerId)();
      if (!mounted) return;
      if (_playerId.isEmpty) throw StateError('Нет данных игрока');
      await Future.wait([_loadPlayer(), _loadStatistics(), _loadAchievements()]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statsLoading = false;
        _achievementsLoading = false;
        _profileError = e is GrpcError ? networkError(e) : 'Не удалось загрузить профиль';
        _statsError = e is GrpcError ? networkError(e) : 'Не удалось загрузить прогресс';
        _achievementsError = e is GrpcError ? networkError(e) : 'Не удалось загрузить достижения';
      });
    }
  }

  Future<void> _loadPlayer() async {
    try {
      final player = await _authRepository.getPlayer(_playerId);
      if (!player.success) throw StateError(player.message);
      if (!mounted) return;
      setState(() {
        _login = player.login;
        _email = player.email;
        _createdAt = player.createdAt;
        _isLoading = false;
        _profileError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _profileError = e is GrpcError ? networkError(e) : 'Не удалось загрузить профиль'; });
    }
  }

  Future<void> _loadStatistics() async {
    setState(() { _statsLoading = true; _statsError = null; });
    try {
      List<Episode>? episodes;
      Set<int>? ids;
      await Future.wait([
        _episodeService.getAllEpisodes().then((value) { episodes = value; }),
        _progressRepository.getProgressSummary(_playerId).then((value) { ids = value; }),
      ], eagerError: true);
      if (!mounted) return;
      setState(() {
        _completedEpisodes = episodes!.where((ep) => ids!.contains(ep.id)).map((ep) => ep.id).toSet().length;
        _totalEpisodes = episodes!.length;
        _statsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _statsLoading = false; _statsError = e is GrpcError ? networkError(e) : 'Не удалось загрузить прогресс'; });
    }
  }

  Future<void> _loadAchievements() async {
    setState(() { _achievementsLoading = true; _achievementsError = null; });
    try {
      final achievements = await _achievementRepository.getAchievements(_playerId);
      if (!mounted) return;
      setState(() {
        _unlockedAchievements.clear();
        _unlockedAchievements.addAll(achievements.where((a) => a.isUnlocked).map((a) => a.name));
        _achievementsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _achievementsLoading = false; _achievementsError = e is GrpcError ? networkError(e) : 'Не удалось загрузить достижения'; });
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
      // Удаляю player_id и JWT-токен из Storage
      await StorageService.savePlayerId('');
      await StorageService.deleteToken();

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

                              if (_profileError != null)
                                Text(_profileError!, style: const TextStyle(color: Colors.red)),
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
                                _statsLoading ? 'Прогресс загружается...' : _statsError ?? 'пройдено эпизодов: $_completedEpisodes/$_totalEpisodes',
                                style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              if (!_statsLoading && _statsError == null)
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
                              if (_achievementsLoading || _achievementsError != null)
                                Text(_achievementsLoading ? 'Достижения загружаются...' : _achievementsError!,
                                  style: const TextStyle(color: Colors.white)),
                              if (!_achievementsLoading && _achievementsError == null)
                              Wrap(
                                alignment: WrapAlignment.spaceEvenly,
                                spacing: 12,
                                runSpacing: 12,
                                children: _allAchievements.map((item) {
                                  final isUnlocked = _unlockedAchievements.contains(item['key']);
                                  return Column(
                                    children: [
                                      Icon(
                                        isUnlocked ? Icons.diamond : Icons.lock_outline,
                                        color: isUnlocked ? const Color(0xFFFFA0A0) : const Color(0xFF534F50),
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['title']!,
                                        style: TextStyle(
                                          color: isUnlocked ? const Color(0xFFFFA0A0) : const Color(0xFF534F50),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
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
                                  Column(children: [Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('МариКот', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10))]),
                                  Column(children: [Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('СуперБаг', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10))]),
                                  Column(children: [Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('АдриБаг', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10))]),
                                  Column(children: [Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('АдриНетт', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10))]),
                                  Column(children: [Icon(Icons.favorite, color: Color(0xFFFFA0A0), size: 32), SizedBox(height: 4), Text('Лука', style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 10))]),
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