import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/auth_api.pbgrpc.dart'; // Импорт gRPC-клиента
import '../../../services/storage_service.dart'; // Импорт StorageService

// Таймауты
const _timeoutFast = Duration(seconds: 10);   // Быстрые (login, register)
const _timeoutMedium = Duration(seconds: 15); // Средние

// Сервис для работы с авторизацией через gRPC
class AuthGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final AuthApiClient _client; // gRPC-клиент

  // Конструктор класса AuthGrpcService
  AuthGrpcService({String host = '10.0.2.2', int port = 50051}) {
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _client = AuthApiClient(_channel);
  }

  // Создать метаданные с JWT-токеном (для авторизованных запросов)
  Future<CallOptions> _getAuthOptions() async {
    final token = await StorageService.loadToken();
    if (token.isEmpty) {
      return CallOptions(timeout: _timeoutFast);
    }
    return CallOptions(
      metadata: {'authorization': 'Bearer $token'},
      timeout: _timeoutFast,
    );
  }

  // Регистрация
  Future<AuthResponse> register({
    required String login,
    required String email,
    required String password,
  }) async {
    final request = RegisterRequest(
      login: login,
      email: email,
      password: password,
    );
    return await _client.register(
      request,
      options: CallOptions(timeout: _timeoutFast), // таймаут 10 сек
    );
  }

  // Вход
  Future<AuthResponse> login({
    required String login,
    required String password,
  }) async {
    final request = LoginRequest(
      login: login,
      password: password,
    );
    return await _client.login(
      request,
      options: CallOptions(timeout: _timeoutFast), // таймаут 10 сек
    );
  }

  // Получить игрока (с токеном)
  Future<AuthResponse> getPlayer(String playerId) async {
    final request = GetPlayerRequest(playerId: playerId);
    final options = await _getAuthOptions(); // Метаданные с токеном и таймаут
    return await _client.getPlayer(request, options: options);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.shutdown();
  }
}