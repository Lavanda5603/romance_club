import 'package:grpc/grpc.dart';

/// Connection settings shared by every RPC service.
/// Use --dart-define to select an emulator, a LAN server, or a TLS endpoint.
abstract final class GrpcConfig {
  static const host = String.fromEnvironment(
    'GRPC_HOST',
    defaultValue: 'localhost',
  );
  static const port = int.fromEnvironment('GRPC_PORT', defaultValue: 50051);
  static const tls = bool.fromEnvironment('GRPC_TLS');

  static ClientChannel createChannel({
    String host = GrpcConfig.host,
    int port = GrpcConfig.port,
    bool tls = GrpcConfig.tls,
  }) {
    if (host.isEmpty ||
        host.trim() != host ||
        host.contains(RegExp(r'[\s/?#]'))) {
      throw ArgumentError.value(
        host,
        'GRPC_HOST',
        'Укажите имя или IP без URL',
      );
    }
    if (port < 1 || port > 65535) {
      throw ArgumentError.value(port, 'GRPC_PORT', 'Допустимы порты 1–65535');
    }
    return ClientChannel(
      host,
      port: port,
      options: ChannelOptions(
        credentials: tls
            ? const ChannelCredentials.secure()
            : const ChannelCredentials.insecure(),
      ),
    );
  }
}
