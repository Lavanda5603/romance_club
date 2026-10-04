// Доменная модель авторизации
class AuthModel {
  final bool success; // Успешно ли
  final String message; // Сообщение
  final String playerId; // ID игрока
  final String login; // Логин
  final String email; // Email
  final String createdAt; // Дата регистрации

  // Конструктор класса AuthModel
  const AuthModel({
    required this.success,
    required this.message,
    required this.playerId,
    required this.login,
    required this.email,
    required this.createdAt,
  });

  // Пустой результат
  factory AuthModel.empty() => const AuthModel(
        success: false,
        message: '',
        playerId: '',
        login: '',
        email: '',
        createdAt: '',
      );
}