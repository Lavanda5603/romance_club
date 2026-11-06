import 'package:flutter_test/flutter_test.dart';
import 'package:romance_club/src/data/services/grpc_config.dart';

void main() {
  test('Every build uses its configured endpoint and TLS mode', () async {
    final channel = GrpcConfig.createChannel();
    addTearDown(channel.terminate);
    expect(channel.host, GrpcConfig.host);
    expect(channel.port, GrpcConfig.port);
    expect(channel.options.credentials.isSecure, GrpcConfig.tls);
    expect(
      GrpcConfig.host,
      const String.fromEnvironment('GRPC_HOST', defaultValue: 'localhost'),
    );
    expect(
      GrpcConfig.port,
      const int.fromEnvironment('GRPC_PORT', defaultValue: 50051),
    );
  });

  test('Local test servers can override build-time settings', () async {
    final channel = GrpcConfig.createChannel(
      host: '127.0.0.1',
      port: 12345,
      tls: false,
    );
    addTearDown(channel.terminate);
    expect(channel.host, '127.0.0.1');
    expect(channel.port, 12345);
    expect(channel.options.credentials.isSecure, isFalse);
    final secure = GrpcConfig.createChannel(
      host: 'game.example.com',
      port: 443,
      tls: true,
    );
    addTearDown(secure.terminate);
    expect(secure.options.credentials.isSecure, isTrue);
  });

  test('Rejects URLs, whitespace, and invalid ports before connecting', () {
    for (final host in [
      '',
      ' ',
      ' localhost',
      'host name',
      'https://server',
      'server/path',
    ]) {
      expect(() => GrpcConfig.createChannel(host: host), throwsArgumentError);
    }
    for (final port in [0, -1, 65536]) {
      expect(() => GrpcConfig.createChannel(port: port), throwsArgumentError);
    }
  });
}
