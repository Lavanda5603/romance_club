// This is a generated file - do not edit.
//
// Generated from achievement_api.proto.

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

import 'achievement_api.pb.dart' as $0;

export 'achievement_api.pb.dart';

/// gRPC-сервис для работы с достижениями
@$pb.GrpcServiceName('romance_club.AchievementApi')
class AchievementApiClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  AchievementApiClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.GetAchievementsResponse> getAchievements(
    $0.GetAchievementsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAchievements, request, options: options);
  }

  $grpc.ResponseFuture<$0.UnlockAchievementResponse> unlockAchievement(
    $0.UnlockAchievementRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$unlockAchievement, request, options: options);
  }

  // method descriptors

  static final _$getAchievements =
      $grpc.ClientMethod<$0.GetAchievementsRequest, $0.GetAchievementsResponse>(
          '/romance_club.AchievementApi/GetAchievements',
          ($0.GetAchievementsRequest value) => value.writeToBuffer(),
          $0.GetAchievementsResponse.fromBuffer);
  static final _$unlockAchievement = $grpc.ClientMethod<
          $0.UnlockAchievementRequest, $0.UnlockAchievementResponse>(
      '/romance_club.AchievementApi/UnlockAchievement',
      ($0.UnlockAchievementRequest value) => value.writeToBuffer(),
      $0.UnlockAchievementResponse.fromBuffer);
}

@$pb.GrpcServiceName('romance_club.AchievementApi')
abstract class AchievementApiServiceBase extends $grpc.Service {
  $core.String get $name => 'romance_club.AchievementApi';

  AchievementApiServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetAchievementsRequest,
            $0.GetAchievementsResponse>(
        'GetAchievements',
        getAchievements_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetAchievementsRequest.fromBuffer(value),
        ($0.GetAchievementsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UnlockAchievementRequest,
            $0.UnlockAchievementResponse>(
        'UnlockAchievement',
        unlockAchievement_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UnlockAchievementRequest.fromBuffer(value),
        ($0.UnlockAchievementResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetAchievementsResponse> getAchievements_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetAchievementsRequest> $request) async {
    return getAchievements($call, await $request);
  }

  $async.Future<$0.GetAchievementsResponse> getAchievements(
      $grpc.ServiceCall call, $0.GetAchievementsRequest request);

  $async.Future<$0.UnlockAchievementResponse> unlockAchievement_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UnlockAchievementRequest> $request) async {
    return unlockAchievement($call, await $request);
  }

  $async.Future<$0.UnlockAchievementResponse> unlockAchievement(
      $grpc.ServiceCall call, $0.UnlockAchievementRequest request);
}
