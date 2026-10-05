// This is a generated file - do not edit.
//
// Generated from shop_api.proto.

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

import 'shop_api.pb.dart' as $0;

export 'shop_api.pb.dart';

/// gRPC-сервис для работы с магазином
@$pb.GrpcServiceName('romance_club.ShopApi')
class ShopApiClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ShopApiClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.GetPurchasesResponse> getPurchases(
    $0.GetPurchasesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getPurchases, request, options: options);
  }

  $grpc.ResponseFuture<$0.PurchaseResponse> purchase(
    $0.PurchaseRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$purchase, request, options: options);
  }

  $grpc.ResponseFuture<$0.Currency> getCurrency(
    $0.GetCurrencyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getCurrency, request, options: options);
  }

  // method descriptors

  static final _$getPurchases =
      $grpc.ClientMethod<$0.GetPurchasesRequest, $0.GetPurchasesResponse>(
          '/romance_club.ShopApi/GetPurchases',
          ($0.GetPurchasesRequest value) => value.writeToBuffer(),
          $0.GetPurchasesResponse.fromBuffer);
  static final _$purchase =
      $grpc.ClientMethod<$0.PurchaseRequest, $0.PurchaseResponse>(
          '/romance_club.ShopApi/Purchase',
          ($0.PurchaseRequest value) => value.writeToBuffer(),
          $0.PurchaseResponse.fromBuffer);
  static final _$getCurrency =
      $grpc.ClientMethod<$0.GetCurrencyRequest, $0.Currency>(
          '/romance_club.ShopApi/GetCurrency',
          ($0.GetCurrencyRequest value) => value.writeToBuffer(),
          $0.Currency.fromBuffer);
}

@$pb.GrpcServiceName('romance_club.ShopApi')
abstract class ShopApiServiceBase extends $grpc.Service {
  $core.String get $name => 'romance_club.ShopApi';

  ShopApiServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.GetPurchasesRequest, $0.GetPurchasesResponse>(
            'GetPurchases',
            getPurchases_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetPurchasesRequest.fromBuffer(value),
            ($0.GetPurchasesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PurchaseRequest, $0.PurchaseResponse>(
        'Purchase',
        purchase_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PurchaseRequest.fromBuffer(value),
        ($0.PurchaseResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetCurrencyRequest, $0.Currency>(
        'GetCurrency',
        getCurrency_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetCurrencyRequest.fromBuffer(value),
        ($0.Currency value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetPurchasesResponse> getPurchases_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetPurchasesRequest> $request) async {
    return getPurchases($call, await $request);
  }

  $async.Future<$0.GetPurchasesResponse> getPurchases(
      $grpc.ServiceCall call, $0.GetPurchasesRequest request);

  $async.Future<$0.PurchaseResponse> purchase_Pre($grpc.ServiceCall $call,
      $async.Future<$0.PurchaseRequest> $request) async {
    return purchase($call, await $request);
  }

  $async.Future<$0.PurchaseResponse> purchase(
      $grpc.ServiceCall call, $0.PurchaseRequest request);

  $async.Future<$0.Currency> getCurrency_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetCurrencyRequest> $request) async {
    return getCurrency($call, await $request);
  }

  $async.Future<$0.Currency> getCurrency(
      $grpc.ServiceCall call, $0.GetCurrencyRequest request);
}
