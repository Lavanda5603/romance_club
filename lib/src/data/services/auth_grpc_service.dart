import 'rpc_policy.dart'; // Импорт сроков ожидания и ошибок сети
import 'package:grpc/grpc.dart'; // Импорт gRPC
import '../../../generated/auth_api.pbgrpc.dart'; // Импорт gRPC-клиента
import 'auth_options.dart'; // Импорт общей проверки токена

// Сервис для работы с авторизацией через gRPC
class AuthGrpcService {
  late final ClientChannel _channel; // Канал связи
  late final AuthApiClient _client; // gRPC-клиент

  // Конструктор
  AuthGrpcService({String host = '10.0.2.2', int port = 50051, RpcDeadline? deadlines}) {
    // Создаю канал связи
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    // Создаю gRPC-клиент
    _client = AuthApiClient(_channel, interceptors: [deadlines ?? RpcDeadline()]);
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
    return await _client.register(request);
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
    return await _client.login(request);
  }

  // Получить игрока (с токеном)
  Future<AuthResponse> getPlayer(String playerId) async {
    final request = GetPlayerRequest(playerId: playerId);
    final options = await authOptions(); // Метаданные с токеном
    return await _client.getPlayer(request, options: options);
  }

  // Закрыть соединение
  Future<void> close() async {
    await _channel.terminate();
  }
}