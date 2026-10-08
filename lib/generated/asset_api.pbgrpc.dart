// This is a generated file - do not edit.
//
// Generated from asset_api.proto.

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

import 'asset_api.pb.dart' as $0;

export 'asset_api.pb.dart';

/// gRPC-сервис для работы с ассетами
@$pb.GrpcServiceName('romance_club.AssetApi')
class AssetApiClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  AssetApiClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.GetAssetsResponse> getAssets(
    $0.GetAssetsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAssets, request, options: options);
  }

  $grpc.ResponseFuture<$0.UploadAssetResponse> uploadAsset(
    $0.UploadAssetRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$uploadAsset, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteAssetResponse> deleteAsset(
    $0.DeleteAssetRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteAsset, request, options: options);
  }

  // method descriptors

  static final _$getAssets =
      $grpc.ClientMethod<$0.GetAssetsRequest, $0.GetAssetsResponse>(
          '/romance_club.AssetApi/GetAssets',
          ($0.GetAssetsRequest value) => value.writeToBuffer(),
          $0.GetAssetsResponse.fromBuffer);
  static final _$uploadAsset =
      $grpc.ClientMethod<$0.UploadAssetRequest, $0.UploadAssetResponse>(
          '/romance_club.AssetApi/UploadAsset',
          ($0.UploadAssetRequest value) => value.writeToBuffer(),
          $0.UploadAssetResponse.fromBuffer);
  static final _$deleteAsset =
      $grpc.ClientMethod<$0.DeleteAssetRequest, $0.DeleteAssetResponse>(
          '/romance_club.AssetApi/DeleteAsset',
          ($0.DeleteAssetRequest value) => value.writeToBuffer(),
          $0.DeleteAssetResponse.fromBuffer);
}

@$pb.GrpcServiceName('romance_club.AssetApi')
abstract class AssetApiServiceBase extends $grpc.Service {
  $core.String get $name => 'romance_club.AssetApi';

  AssetApiServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetAssetsRequest, $0.GetAssetsResponse>(
        'GetAssets',
        getAssets_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetAssetsRequest.fromBuffer(value),
        ($0.GetAssetsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.UploadAssetRequest, $0.UploadAssetResponse>(
            'UploadAsset',
            uploadAsset_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UploadAssetRequest.fromBuffer(value),
            ($0.UploadAssetResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteAssetRequest, $0.DeleteAssetResponse>(
            'DeleteAsset',
            deleteAsset_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteAssetRequest.fromBuffer(value),
            ($0.DeleteAssetResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetAssetsResponse> getAssets_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetAssetsRequest> $request) async {
    return getAssets($call, await $request);
  }

  $async.Future<$0.GetAssetsResponse> getAssets(
      $grpc.ServiceCall call, $0.GetAssetsRequest request);

  $async.Future<$0.UploadAssetResponse> uploadAsset_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UploadAssetRequest> $request) async {
    return uploadAsset($call, await $request);
  }

  $async.Future<$0.UploadAssetResponse> uploadAsset(
      $grpc.ServiceCall call, $0.UploadAssetRequest request);

  $async.Future<$0.DeleteAssetResponse> deleteAsset_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteAssetRequest> $request) async {
    return deleteAsset($call, await $request);
  }

  $async.Future<$0.DeleteAssetResponse> deleteAsset(
      $grpc.ServiceCall call, $0.DeleteAssetRequest request);
}
