// This is a generated file - do not edit.
//
// Generated from episode_api.proto.

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

import 'episode.pb.dart' as $1;
import 'episode_api.pb.dart' as $0;

export 'episode_api.pb.dart';

/// gRPC-сервис для работы с эпизодами
@$pb.GrpcServiceName('romance_club.EpisodeApi')
class EpisodeApiClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  EpisodeApiClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.Episode> getEpisode(
    $0.GetEpisodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getEpisode, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetAllEpisodesResponse> getAllEpisodes(
    $0.GetAllEpisodesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAllEpisodes, request, options: options);
  }

  $grpc.ResponseFuture<$0.SaveEpisodeResponse> saveEpisode(
    $0.SaveEpisodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveEpisode, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteEpisodeResponse> deleteEpisode(
    $0.DeleteEpisodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteEpisode, request, options: options);
  }

  // method descriptors

  static final _$getEpisode =
      $grpc.ClientMethod<$0.GetEpisodeRequest, $1.Episode>(
          '/romance_club.EpisodeApi/GetEpisode',
          ($0.GetEpisodeRequest value) => value.writeToBuffer(),
          $1.Episode.fromBuffer);
  static final _$getAllEpisodes =
      $grpc.ClientMethod<$0.GetAllEpisodesRequest, $0.GetAllEpisodesResponse>(
          '/romance_club.EpisodeApi/GetAllEpisodes',
          ($0.GetAllEpisodesRequest value) => value.writeToBuffer(),
          $0.GetAllEpisodesResponse.fromBuffer);
  static final _$saveEpisode =
      $grpc.ClientMethod<$0.SaveEpisodeRequest, $0.SaveEpisodeResponse>(
          '/romance_club.EpisodeApi/SaveEpisode',
          ($0.SaveEpisodeRequest value) => value.writeToBuffer(),
          $0.SaveEpisodeResponse.fromBuffer);
  static final _$deleteEpisode =
      $grpc.ClientMethod<$0.DeleteEpisodeRequest, $0.DeleteEpisodeResponse>(
          '/romance_club.EpisodeApi/DeleteEpisode',
          ($0.DeleteEpisodeRequest value) => value.writeToBuffer(),
          $0.DeleteEpisodeResponse.fromBuffer);
}

@$pb.GrpcServiceName('romance_club.EpisodeApi')
abstract class EpisodeApiServiceBase extends $grpc.Service {
  $core.String get $name => 'romance_club.EpisodeApi';

  EpisodeApiServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetEpisodeRequest, $1.Episode>(
        'GetEpisode',
        getEpisode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetEpisodeRequest.fromBuffer(value),
        ($1.Episode value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetAllEpisodesRequest,
            $0.GetAllEpisodesResponse>(
        'GetAllEpisodes',
        getAllEpisodes_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetAllEpisodesRequest.fromBuffer(value),
        ($0.GetAllEpisodesResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SaveEpisodeRequest, $0.SaveEpisodeResponse>(
            'SaveEpisode',
            saveEpisode_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SaveEpisodeRequest.fromBuffer(value),
            ($0.SaveEpisodeResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteEpisodeRequest, $0.DeleteEpisodeResponse>(
            'DeleteEpisode',
            deleteEpisode_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteEpisodeRequest.fromBuffer(value),
            ($0.DeleteEpisodeResponse value) => value.writeToBuffer()));
  }

  $async.Future<$1.Episode> getEpisode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetEpisodeRequest> $request) async {
    return getEpisode($call, await $request);
  }

  $async.Future<$1.Episode> getEpisode(
      $grpc.ServiceCall call, $0.GetEpisodeRequest request);

  $async.Future<$0.GetAllEpisodesResponse> getAllEpisodes_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetAllEpisodesRequest> $request) async {
    return getAllEpisodes($call, await $request);
  }

  $async.Future<$0.GetAllEpisodesResponse> getAllEpisodes(
      $grpc.ServiceCall call, $0.GetAllEpisodesRequest request);

  $async.Future<$0.SaveEpisodeResponse> saveEpisode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SaveEpisodeRequest> $request) async {
    return saveEpisode($call, await $request);
  }

  $async.Future<$0.SaveEpisodeResponse> saveEpisode(
      $grpc.ServiceCall call, $0.SaveEpisodeRequest request);

  $async.Future<$0.DeleteEpisodeResponse> deleteEpisode_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteEpisodeRequest> $request) async {
    return deleteEpisode($call, await $request);
  }

  $async.Future<$0.DeleteEpisodeResponse> deleteEpisode(
      $grpc.ServiceCall call, $0.DeleteEpisodeRequest request);
}
