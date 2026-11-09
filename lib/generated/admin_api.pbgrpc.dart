// This is a generated file - do not edit.
//
// Generated from admin_api.proto.

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

import 'admin_api.pb.dart' as $0;

export 'admin_api.pb.dart';

/// gRPC-сервис для админ-операций
@$pb.GrpcServiceName('romance_club.AdminApi')
class AdminApiClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  AdminApiClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.AdminResponse> deleteAsset(
    $0.AdminDeleteAssetRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteAsset, request, options: options);
  }

  $grpc.ResponseFuture<$0.AdminResponse> deleteEpisode(
    $0.AdminDeleteEpisodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteEpisode, request, options: options);
  }

  // method descriptors

  static final _$deleteAsset =
      $grpc.ClientMethod<$0.AdminDeleteAssetRequest, $0.AdminResponse>(
          '/romance_club.AdminApi/DeleteAsset',
          ($0.AdminDeleteAssetRequest value) => value.writeToBuffer(),
          $0.AdminResponse.fromBuffer);
  static final _$deleteEpisode =
      $grpc.ClientMethod<$0.AdminDeleteEpisodeRequest, $0.AdminResponse>(
          '/romance_club.AdminApi/DeleteEpisode',
          ($0.AdminDeleteEpisodeRequest value) => value.writeToBuffer(),
          $0.AdminResponse.fromBuffer);
}

@$pb.GrpcServiceName('romance_club.AdminApi')
abstract class AdminApiServiceBase extends $grpc.Service {
  $core.String get $name => 'romance_club.AdminApi';

  AdminApiServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.AdminDeleteAssetRequest, $0.AdminResponse>(
            'DeleteAsset',
            deleteAsset_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.AdminDeleteAssetRequest.fromBuffer(value),
            ($0.AdminResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.AdminDeleteEpisodeRequest, $0.AdminResponse>(
            'DeleteEpisode',
            deleteEpisode_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.AdminDeleteEpisodeRequest.fromBuffer(value),
            ($0.AdminResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.AdminResponse> deleteAsset_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AdminDeleteAssetRequest> $request) async {
    return deleteAsset($call, await $request);
  }

  $async.Future<$0.AdminResponse> deleteAsset(
      $grpc.ServiceCall call, $0.AdminDeleteAssetRequest request);

  $async.Future<$0.AdminResponse> deleteEpisode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AdminDeleteEpisodeRequest> $request) async {
    return deleteEpisode($call, await $request);
  }

  $async.Future<$0.AdminResponse> deleteEpisode(
      $grpc.ServiceCall call, $0.AdminDeleteEpisodeRequest request);
}