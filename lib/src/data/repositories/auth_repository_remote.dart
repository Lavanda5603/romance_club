import '../../domain/models/auth_model.dart'; // Импорт доменных моделей
import '../../domain/repositories/auth_repository.dart'; // Импорт контракта
import '../services/auth_grpc_service.dart'; // Импорт gRPC-сервиса
import '../../../generated/auth_api.pb.dart'; // Импорт Protobuf-модели AuthResponse

// Реализация репозитория авторизации через gRPC
class AuthRepositoryRemote implements AuthRepository {
  final AuthGrpcService _service; // gRPC-сервис

  // Конструктор класса AuthRepositoryRemote
  AuthRepositoryRemote(this._service);

  // Зарегистрироваться
  @override
  Future<AuthModel> register({
    required String login,
    required String email,
    required String password,
  }) async {
    final response = await _service.register(
      login: login,
      email: email,
      password: password,
    );
    return toDomain(response);
  }

  // Войти
  @override
  Future<AuthModel> login({
    required String login,
    required String password,
  }) async {
    final response = await _service.login(
      login: login,
      password: password,
    );
    return toDomain(response);
  }

  // Преобразование Protobuf-модели в доменную
  AuthModel toDomain(AuthResponse response) {
    // Если игрок есть - извлекаю данные
    if (response.hasPlayer()) {
      return AuthModel(
        success: response.success,
        message: response.message,
        playerId: response.player.id,
        login: response.player.login,
        email: response.player.email,
      );
    }
    // Если игрока нет - пустой результат
    return AuthModel(
      success: response.success,
      message: response.message,
      playerId: '',
      login: '',
      email: '',
    );
  }
}