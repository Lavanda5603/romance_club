// Доменная модель авторизации (результат входа или регистрации)
class AuthModel {
  final bool success; // Успешно ли
  final String message; // Сообщение
  final String playerId; // ID игрока
  final String login; // Логин
  final String email; // Email

  // Конструктор класса AuthModel
  const AuthModel({
    required this.success,
    required this.message,
    required this.playerId,
    required this.login,
    required this.email,
  });

  // Пустой результат (когда ничего нет)
  factory AuthModel.empty() => const AuthModel(
        success: false,
        message: '',
        playerId: '',
        login: '',
        email: '',
      );
}