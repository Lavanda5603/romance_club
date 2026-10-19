import 'package:flutter/material.dart'; // Импорт Material UI
import 'screens/main_menu_screen.dart'; // Импорт главного меню
import 'screens/login_screen.dart'; // Импорт экрана авторизации
import 'dart:async'; // Импорт подписки на окончание сессии
import 'package:grpc/grpc.dart'; // Импорт статусов RPC
import 'services/session_store.dart'; // Импорт единого хранилища сессии
import 'src/data/services/auth_grpc_service.dart'; // Импорт проверки игрока на сервере
import 'src/data/services/rpc_policy.dart'; // Импорт понятных ошибок сети

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Инициализация Flutter
  runApp(const RomanceClubApp()); // Запуск приложения
}

// Корневой виджет приложения
class RomanceClubApp extends StatefulWidget {
  final Future<bool> Function(Session)? validateSession;
  final Widget Function()? buildMenu;
  const RomanceClubApp({super.key, this.validateSession, this.buildMenu}); // Корневой виджет

  @override
  State<RomanceClubApp> createState() => _RomanceClubAppState();
}

class _RomanceClubAppState extends State<RomanceClubApp> {
  final _navigator = GlobalKey<NavigatorState>();
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late final StreamSubscription<String> _sessionChanges;

  @override
  void initState() {
    super.initState();
    _sessionChanges = SessionStore.shared.expired.listen((message) {
      if (!mounted) return;
      _navigator.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      _messenger.currentState?.showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  void dispose() {
    _sessionChanges.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigator,
      scaffoldMessengerKey: _messenger,
      title: 'Клуб Романтики',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD30010)), // Тема
      ),
      home: SplashScreen(validate: widget.validateSession, buildMenu: widget.buildMenu), // Стартовый экран
    );
  }
}

// Стартовый экран (проверяет, залогинен ли игрок)
class SplashScreen extends StatefulWidget {
  final Future<bool> Function(Session)? validate;
  final Widget Function()? buildMenu;
  const SplashScreen({super.key, this.validate, this.buildMenu});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;
  @override
  void initState() {
    super.initState();
    _checkLogin(); // Проверяю авторизацию
  }

  // Сервер проверяет подпись токена и соответствие игрока
  Future<bool> _validate(Session session) async {
    final service = AuthGrpcService();
    try {
      final result = await service.getPlayer(session.playerId);
      return result.success && result.hasPlayer() && result.player.id == session.playerId;
    } finally {
      await service.close();
    }
  }

  // Пока проверка не закончилась, меню не открываю
  Future<void> _checkLogin() async {
    setState(() => _error = null);
    try {
      final session = await SessionStore.shared.load();
      if (!mounted) return;
      var valid = false;
      if (session != null) {
        try {
          valid = await (widget.validate ?? _validate)(session);
        } on GrpcError catch (error) {
          if (error.code != StatusCode.unauthenticated && error.code != StatusCode.permissionDenied) rethrow;
        }
        if (!mounted) return;
        // Ответ проверки не должен открыть меню для уже сменившегося аккаунта
        final current = await SessionStore.shared.load();
        if (!mounted) return;
        if (current?.token != session.token || current?.playerId != session.playerId) {
          await _checkLogin();
          return;
        }
        if (!valid && !await SessionStore.shared.clearIfCurrent(session)) {
          if (mounted) await _checkLogin();
          return;
        }
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => valid
          ? (widget.buildMenu?.call() ?? const MainMenu()) : const LoginScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось проверить сессию. ${networkError(error)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A), // Фон
      body: Center(
        child: _error == null
          ? const CircularProgressIndicator(color: Color(0xFFD30010))
          : Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              TextButton(onPressed: _checkLogin, child: const Text('Повторить')),
            ]),
      ),
    );
  }
}
