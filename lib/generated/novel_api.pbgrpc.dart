// This is a generated file - do not edit.
//
// Generated from novel_api.proto.

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
import 'novel_api.pb.dart' as $0;

export 'novel_api.pb.dart';

@$pb.GrpcServiceName('romance_club.NovelApi')
class NovelApiClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  NovelApiClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListNovelsResponse> listNovels(
    $0.ListNovelsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listNovels, request, options: options);
  }

  $grpc.ResponseFuture<$0.Novel> saveNovel(
    $0.Novel request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveNovel, request, options: options);
  }

  $grpc.ResponseFuture<$1.Episode> createNovelEpisode(
    $0.CreateNovelEpisodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createNovelEpisode, request, options: options);
  }

  $grpc.ResponseFuture<$0.NovelAudio> uploadAudio(
    $0.UploadNovelAudioRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$uploadAudio, request, options: options);
  }

  $grpc.ResponseFuture<$0.NovelAudio> getAudio(
    $0.NovelAudioRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAudio, request, options: options);
  }

  // method descriptors

  static final _$listNovels =
      $grpc.ClientMethod<$0.ListNovelsRequest, $0.ListNovelsResponse>(
          '/romance_club.NovelApi/ListNovels',
          ($0.ListNovelsRequest value) => value.writeToBuffer(),
          $0.ListNovelsResponse.fromBuffer);
  static final _$saveNovel = $grpc.ClientMethod<$0.Novel, $0.Novel>(
      '/romance_club.NovelApi/SaveNovel',
      ($0.Novel value) => value.writeToBuffer(),
      $0.Novel.fromBuffer);
  static final _$createNovelEpisode =
      $grpc.ClientMethod<$0.CreateNovelEpisodeRequest, $1.Episode>(
          '/romance_club.NovelApi/CreateNovelEpisode',
          ($0.CreateNovelEpisodeRequest value) => value.writeToBuffer(),
          $1.Episode.fromBuffer);
  static final _$uploadAudio =
      $grpc.ClientMethod<$0.UploadNovelAudioRequest, $0.NovelAudio>(
          '/romance_club.NovelApi/UploadAudio',
          ($0.UploadNovelAudioRequest value) => value.writeToBuffer(),
          $0.NovelAudio.fromBuffer);
  static final _$getAudio =
      $grpc.ClientMethod<$0.NovelAudioRequest, $0.NovelAudio>(
          '/romance_club.NovelApi/GetAudio',
          ($0.NovelAudioRequest value) => value.writeToBuffer(),
          $0.NovelAudio.fromBuffer);
}

@$pb.GrpcServiceName('romance_club.NovelApi')
abstract class NovelApiServiceBase extends $grpc.Service {
  $core.String get $name => 'romance_club.NovelApi';

  NovelApiServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ListNovelsRequest, $0.ListNovelsResponse>(
        'ListNovels',
        listNovels_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListNovelsRequest.fromBuffer(value),
        ($0.ListNovelsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Novel, $0.Novel>(
        'SaveNovel',
        saveNovel_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Novel.fromBuffer(value),
        ($0.Novel value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateNovelEpisodeRequest, $1.Episode>(
        'CreateNovelEpisode',
        createNovelEpisode_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateNovelEpisodeRequest.fromBuffer(value),
        ($1.Episode value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UploadNovelAudioRequest, $0.NovelAudio>(
        'UploadAudio',
        uploadAudio_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UploadNovelAudioRequest.fromBuffer(value),
        ($0.NovelAudio value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.NovelAudioRequest, $0.NovelAudio>(
        'GetAudio',
        getAudio_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.NovelAudioRequest.fromBuffer(value),
        ($0.NovelAudio value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListNovelsResponse> listNovels_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListNovelsRequest> $request) async {
    return listNovels($call, await $request);
  }

  $async.Future<$0.ListNovelsResponse> listNovels(
      $grpc.ServiceCall call, $0.ListNovelsRequest request);

  $async.Future<$0.Novel> saveNovel_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Novel> $request) async {
    return saveNovel($call, await $request);
  }

  $async.Future<$0.Novel> saveNovel($grpc.ServiceCall call, $0.Novel request);

  $async.Future<$1.Episode> createNovelEpisode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateNovelEpisodeRequest> $request) async {
    return createNovelEpisode($call, await $request);
  }

  $async.Future<$1.Episode> createNovelEpisode(
      $grpc.ServiceCall call, $0.CreateNovelEpisodeRequest request);

  $async.Future<$0.NovelAudio> uploadAudio_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UploadNovelAudioRequest> $request) async {
    return uploadAudio($call, await $request);
  }

  $async.Future<$0.NovelAudio> uploadAudio(
      $grpc.ServiceCall call, $0.UploadNovelAudioRequest request);

  $async.Future<$0.NovelAudio> getAudio_Pre($grpc.ServiceCall $call,
      $async.Future<$0.NovelAudioRequest> $request) async {
    return getAudio($call, await $request);
  }

  $async.Future<$0.NovelAudio> getAudio(
      $grpc.ServiceCall call, $0.NovelAudioRequest request);
}