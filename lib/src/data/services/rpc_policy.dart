import 'package:grpc/grpc.dart'; // Импорт для gRPC-запросов
import '../../../services/session_store.dart'; // Импорт согласованной сессии

// Ограничиваю ожидание по типу запроса
class RpcDeadline extends ClientInterceptor {
  final Duration read;
  final Duration write;
  final Duration transfer;
  RpcDeadline({this.read = const Duration(seconds: 15),
    this.write = const Duration(seconds: 30),
    this.transfer = const Duration(seconds: 60)});

  Duration timeoutFor(String path) {
    final method = path.split('/').last;
    if (method == 'UploadAsset' || method == 'GetAsset') return transfer;
    if (method == 'GetEpisode' || !method.startsWith('Get')) return write;
    return read;
  }

  @override
  ResponseFuture<R> interceptUnary<Q, R>(ClientMethod<Q, R> method, Q request,
      CallOptions options, ClientUnaryInvoker<Q, R> invoker) {
    final limit = timeoutFor(method.path);
    final timeout = options.timeout;
    final response = invoker(method, request, options.mergedWith(CallOptions(
      timeout: timeout != null && timeout < limit ? timeout : limit)));
    final bearer = options.metadata['authorization'];
    // Отказ старому токену не должен завершать новый вход
    if (bearer != null && bearer.startsWith('Bearer ')) {
      response.then<void>((_) {}, onError: (Object error, StackTrace stack) async {
        if (error is GrpcError && error.code == StatusCode.unauthenticated) {
          try {
            await SessionStore.shared.invalidate(bearer.substring(7));
          } catch (_) {
            // Хранилище сообщает экрану об ошибке очистки
          }
        }
      });
    }
    return response;
  }
}

String networkError(Object error) {
  if (error is GrpcError) {
    switch (error.code) {
      case StatusCode.unauthenticated:
        return 'Сессия недействительна. Выйдите из аккаунта и войдите снова.';
      case StatusCode.deadlineExceeded:
        return 'Сервер не ответил вовремя. Повторите загрузку. Если сохраняли изменения, сначала проверьте результат.';
      case StatusCode.unavailable:
        return 'Не удалось связаться с сервером. Проверьте подключение и повторите запрос.';
      case StatusCode.cancelled:
        return 'Запрос отменён';
    }
    return error.message ?? 'Ошибка запроса';
  }
  return error.toString();
}
