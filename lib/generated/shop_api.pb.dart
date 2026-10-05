// This is a generated file - do not edit.
//
// Generated from shop_api.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Покупка
class Purchase extends $pb.GeneratedMessage {
  factory Purchase({
    $core.String? itemId,
    $core.String? itemType,
    $core.String? purchasedAt,
  }) {
    final result = Purchase._();
    if (itemId != null) result.itemId = itemId;
    if (itemType != null) result.itemType = itemType;
    if (purchasedAt != null) result.purchasedAt = purchasedAt;
    return result;
  }

  Purchase._();

  factory Purchase.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Purchase()..mergeFromBuffer(data, registry);
  factory Purchase.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Purchase()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Purchase',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: Purchase.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'itemId')
    ..aOS(2, _omitFieldNames ? '' : 'itemType')
    ..aOS(3, _omitFieldNames ? '' : 'purchasedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Purchase clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Purchase copyWith(void Function(Purchase) updates) =>
      super.copyWith((message) => updates(message as Purchase)) as Purchase;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Purchase() / Purchase.new instead')
  static Purchase create() => Purchase._();
  static $pb.GeneratedMessage $_createMessage() => Purchase._();
  @$core.override
  Purchase createEmptyInstance() => Purchase._();
  @$core.pragma('dart2js:noInline')
  static Purchase getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Purchase>(Purchase.$_createMessage);
  static Purchase? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get itemId => $_getSZ(0);
  @$pb.TagNumber(1)
  set itemId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasItemId() => $_has(0);
  @$pb.TagNumber(1)
  void clearItemId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get itemType => $_getSZ(1);
  @$pb.TagNumber(2)
  set itemType($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasItemType() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get purchasedAt => $_getSZ(2);
  @$pb.TagNumber(3)
  set purchasedAt($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPurchasedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearPurchasedAt() => $_clearField(3);
}

/// Валюта игрока
class Currency extends $pb.GeneratedMessage {
  factory Currency({
    $core.String? playerId,
    $core.int? diamonds,
  }) {
    final result = Currency._();
    if (playerId != null) result.playerId = playerId;
    if (diamonds != null) result.diamonds = diamonds;
    return result;
  }

  Currency._();

  factory Currency.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Currency()..mergeFromBuffer(data, registry);
  factory Currency.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Currency()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Currency',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: Currency.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..aI(2, _omitFieldNames ? '' : 'diamonds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Currency clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Currency copyWith(void Function(Currency) updates) =>
      super.copyWith((message) => updates(message as Currency)) as Currency;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Currency() / Currency.new instead')
  static Currency create() => Currency._();
  static $pb.GeneratedMessage $_createMessage() => Currency._();
  @$core.override
  Currency createEmptyInstance() => Currency._();
  @$core.pragma('dart2js:noInline')
  static Currency getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Currency>(Currency.$_createMessage);
  static Currency? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get diamonds => $_getIZ(1);
  @$pb.TagNumber(2)
  set diamonds($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDiamonds() => $_has(1);
  @$pb.TagNumber(2)
  void clearDiamonds() => $_clearField(2);
}

/// Запрос на получение покупок
class GetPurchasesRequest extends $pb.GeneratedMessage {
  factory GetPurchasesRequest({
    $core.String? playerId,
  }) {
    final result = GetPurchasesRequest._();
    if (playerId != null) result.playerId = playerId;
    return result;
  }

  GetPurchasesRequest._();

  factory GetPurchasesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPurchasesRequest()..mergeFromBuffer(data, registry);
  factory GetPurchasesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPurchasesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPurchasesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: GetPurchasesRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPurchasesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPurchasesRequest copyWith(void Function(GetPurchasesRequest) updates) =>
      super.copyWith((message) => updates(message as GetPurchasesRequest))
          as GetPurchasesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetPurchasesRequest() / GetPurchasesRequest.new instead')
  static GetPurchasesRequest create() => GetPurchasesRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetPurchasesRequest._();
  @$core.override
  GetPurchasesRequest createEmptyInstance() => GetPurchasesRequest._();
  @$core.pragma('dart2js:noInline')
  static GetPurchasesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetPurchasesRequest>(
          GetPurchasesRequest.$_createMessage);
  static GetPurchasesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);
}

/// Ответ со списком покупок
class GetPurchasesResponse extends $pb.GeneratedMessage {
  factory GetPurchasesResponse({
    $core.Iterable<Purchase>? purchases,
  }) {
    final result = GetPurchasesResponse._();
    if (purchases != null) result.purchases.addAll(purchases);
    return result;
  }

  GetPurchasesResponse._();

  factory GetPurchasesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPurchasesResponse()..mergeFromBuffer(data, registry);
  factory GetPurchasesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPurchasesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPurchasesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: GetPurchasesResponse.$_createMessage)
    ..pPM<Purchase>(1, _omitFieldNames ? '' : 'purchases',
        subBuilder: Purchase.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPurchasesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPurchasesResponse copyWith(void Function(GetPurchasesResponse) updates) =>
      super.copyWith((message) => updates(message as GetPurchasesResponse))
          as GetPurchasesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetPurchasesResponse() / GetPurchasesResponse.new instead')
  static GetPurchasesResponse create() => GetPurchasesResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetPurchasesResponse._();
  @$core.override
  GetPurchasesResponse createEmptyInstance() => GetPurchasesResponse._();
  @$core.pragma('dart2js:noInline')
  static GetPurchasesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetPurchasesResponse>(
          GetPurchasesResponse.$_createMessage);
  static GetPurchasesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Purchase> get purchases => $_getList(0);
}

/// Запрос на покупку
class PurchaseRequest extends $pb.GeneratedMessage {
  factory PurchaseRequest({
    $core.String? playerId,
    $core.String? itemId,
    $core.String? itemType,
  }) {
    final result = PurchaseRequest._();
    if (playerId != null) result.playerId = playerId;
    if (itemId != null) result.itemId = itemId;
    if (itemType != null) result.itemType = itemType;
    return result;
  }

  PurchaseRequest._();

  factory PurchaseRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PurchaseRequest()..mergeFromBuffer(data, registry);
  factory PurchaseRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PurchaseRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PurchaseRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: PurchaseRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..aOS(2, _omitFieldNames ? '' : 'itemId')
    ..aOS(3, _omitFieldNames ? '' : 'itemType')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PurchaseRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PurchaseRequest copyWith(void Function(PurchaseRequest) updates) =>
      super.copyWith((message) => updates(message as PurchaseRequest))
          as PurchaseRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PurchaseRequest() / PurchaseRequest.new instead')
  static PurchaseRequest create() => PurchaseRequest._();
  static $pb.GeneratedMessage $_createMessage() => PurchaseRequest._();
  @$core.override
  PurchaseRequest createEmptyInstance() => PurchaseRequest._();
  @$core.pragma('dart2js:noInline')
  static PurchaseRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PurchaseRequest>(
          PurchaseRequest.$_createMessage);
  static PurchaseRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get itemId => $_getSZ(1);
  @$pb.TagNumber(2)
  set itemId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasItemId() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get itemType => $_getSZ(2);
  @$pb.TagNumber(3)
  set itemType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasItemType() => $_has(2);
  @$pb.TagNumber(3)
  void clearItemType() => $_clearField(3);
}

/// Ответ после покупки
class PurchaseResponse extends $pb.GeneratedMessage {
  factory PurchaseResponse({
    $core.bool? success,
    $core.String? message,
    Currency? currency,
  }) {
    final result = PurchaseResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (currency != null) result.currency = currency;
    return result;
  }

  PurchaseResponse._();

  factory PurchaseResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PurchaseResponse()..mergeFromBuffer(data, registry);
  factory PurchaseResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PurchaseResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PurchaseResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: PurchaseResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<Currency>(3, _omitFieldNames ? '' : 'currency',
        subBuilder: Currency.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PurchaseResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PurchaseResponse copyWith(void Function(PurchaseResponse) updates) =>
      super.copyWith((message) => updates(message as PurchaseResponse))
          as PurchaseResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PurchaseResponse() / PurchaseResponse.new instead')
  static PurchaseResponse create() => PurchaseResponse._();
  static $pb.GeneratedMessage $_createMessage() => PurchaseResponse._();
  @$core.override
  PurchaseResponse createEmptyInstance() => PurchaseResponse._();
  @$core.pragma('dart2js:noInline')
  static PurchaseResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PurchaseResponse>(
          PurchaseResponse.$_createMessage);
  static PurchaseResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  Currency get currency => $_getN(2);
  @$pb.TagNumber(3)
  set currency(Currency value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrency() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrency() => $_clearField(3);
  @$pb.TagNumber(3)
  Currency ensureCurrency() => $_ensure(2);
}

/// Запрос на получение баланса
class GetCurrencyRequest extends $pb.GeneratedMessage {
  factory GetCurrencyRequest({
    $core.String? playerId,
  }) {
    final result = GetCurrencyRequest._();
    if (playerId != null) result.playerId = playerId;
    return result;
  }

  GetCurrencyRequest._();

  factory GetCurrencyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCurrencyRequest()..mergeFromBuffer(data, registry);
  factory GetCurrencyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCurrencyRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCurrencyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: GetCurrencyRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCurrencyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCurrencyRequest copyWith(void Function(GetCurrencyRequest) updates) =>
      super.copyWith((message) => updates(message as GetCurrencyRequest))
          as GetCurrencyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetCurrencyRequest() / GetCurrencyRequest.new instead')
  static GetCurrencyRequest create() => GetCurrencyRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetCurrencyRequest._();
  @$core.override
  GetCurrencyRequest createEmptyInstance() => GetCurrencyRequest._();
  @$core.pragma('dart2js:noInline')
  static GetCurrencyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetCurrencyRequest>(
          GetCurrencyRequest.$_createMessage);
  static GetCurrencyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
