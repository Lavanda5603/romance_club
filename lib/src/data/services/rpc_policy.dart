import 'package:grpc/grpc.dart';

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
    return invoker(method, request, options.mergedWith(CallOptions(
      timeout: timeout != null && timeout < limit ? timeout : limit)));
  }
}

String networkError(Object error) {
  if (error is GrpcError) {
    switch (error.code) {
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