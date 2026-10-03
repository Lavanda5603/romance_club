// This is a generated file - do not edit.
//
// Generated from progress_api.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'progress.pb.dart' as $1;
import 'progress_api.pb.dart' as $0;

export 'progress_api.pb.dart';

/// gRPC-сервис для работы с прогрессом
@$pb.GrpcServiceName('romance_club.ProgressApi')
class ProgressApiClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ProgressApiClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.Progress> getProgress(
    $0.GetProgressRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getProgress, request, options: options);
  }

  $grpc.ResponseFuture<$0.SaveProgressResponse> saveProgress(
    $0.SaveProgressRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveProgress, request, options: options);
  }

  // method descriptors

  static final _$getProgress =
      $grpc.ClientMethod<$0.GetProgressRequest, $1.Progress>(
          '/romance_club.ProgressApi/GetProgress',
          ($0.GetProgressRequest value) => value.writeToBuffer(),
          $1.Progress.fromBuffer);
  static final _$saveProgress =
      $grpc.ClientMethod<$0.SaveProgressRequest, $0.SaveProgressResponse>(
          '/romance_club.ProgressApi/SaveProgress',
          ($0.SaveProgressRequest value) => value.writeToBuffer(),
          $0.SaveProgressResponse.fromBuffer);
}

@$pb.GrpcServiceName('romance_club.ProgressApi')
abstract class ProgressApiServiceBase extends $grpc.Service {
  $core.String get $name => 'romance_club.ProgressApi';

  ProgressApiServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetProgressRequest, $1.Progress>(
        'GetProgress',
        getProgress_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetProgressRequest.fromBuffer(value),
        ($1.Progress value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SaveProgressRequest, $0.SaveProgressResponse>(
            'SaveProgress',
            saveProgress_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SaveProgressRequest.fromBuffer(value),
            ($0.SaveProgressResponse value) => value.writeToBuffer()));
  }

  $async.Future<$1.Progress> getProgress_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetProgressRequest> $request) async {
    return getProgress($call, await $request);
  }

  $async.Future<$1.Progress> getProgress(
      $grpc.ServiceCall call, $0.GetProgressRequest request);

  $async.Future<$0.SaveProgressResponse> saveProgress_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SaveProgressRequest> $request) async {
    return saveProgress($call, await $request);
  }

  $async.Future<$0.SaveProgressResponse> saveProgress(
      $grpc.ServiceCall call, $0.SaveProgressRequest request);
}
