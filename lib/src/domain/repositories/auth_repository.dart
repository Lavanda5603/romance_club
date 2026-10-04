import '../models/auth_model.dart'; // Импорт доменных моделей

// Контракт репозитория авторизации
abstract class AuthRepository {
  // Зарегистрироваться
  Future<AuthModel> register({
    required String login,
    required String email,
    required String password,
  });

  // Войти
  Future<AuthModel> login({
    required String login,
    required String password,
  });

  // Получить игрока по ID
  Future<AuthModel> getPlayer(String playerId);
}