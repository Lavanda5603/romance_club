// This is a generated file - do not edit.
//
// Generated from achievement_api.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Достижение игрока
class Achievement extends $pb.GeneratedMessage {
  factory Achievement({
    $core.String? name,
    $core.String? unlockedAt,
  }) {
    final result = Achievement._();
    if (name != null) result.name = name;
    if (unlockedAt != null) result.unlockedAt = unlockedAt;
    return result;
  }

  Achievement._();

  factory Achievement.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Achievement()..mergeFromBuffer(data, registry);
  factory Achievement.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Achievement()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Achievement',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: Achievement.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'unlockedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Achievement clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Achievement copyWith(void Function(Achievement) updates) =>
      super.copyWith((message) => updates(message as Achievement))
          as Achievement;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Achievement() / Achievement.new instead')
  static Achievement create() => Achievement._();
  static $pb.GeneratedMessage $_createMessage() => Achievement._();
  @$core.override
  Achievement createEmptyInstance() => Achievement._();
  @$core.pragma('dart2js:noInline')
  static Achievement getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Achievement>(
          Achievement.$_createMessage);
  static Achievement? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get unlockedAt => $_getSZ(1);
  @$pb.TagNumber(2)
  set unlockedAt($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUnlockedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnlockedAt() => $_clearField(2);
}

/// Запрос на получение достижений
class GetAchievementsRequest extends $pb.GeneratedMessage {
  factory GetAchievementsRequest({
    $core.String? playerId,
  }) {
    final result = GetAchievementsRequest._();
    if (playerId != null) result.playerId = playerId;
    return result;
  }

  GetAchievementsRequest._();

  factory GetAchievementsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAchievementsRequest()..mergeFromBuffer(data, registry);
  factory GetAchievementsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAchievementsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAchievementsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: GetAchievementsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAchievementsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAchievementsRequest copyWith(
          void Function(GetAchievementsRequest) updates) =>
      super.copyWith((message) => updates(message as GetAchievementsRequest))
          as GetAchievementsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAchievementsRequest() / GetAchievementsRequest.new instead')
  static GetAchievementsRequest create() => GetAchievementsRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetAchievementsRequest._();
  @$core.override
  GetAchievementsRequest createEmptyInstance() => GetAchievementsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetAchievementsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAchievementsRequest>(
          GetAchievementsRequest.$_createMessage);
  static GetAchievementsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);
}

/// Ответ со списком достижений
class GetAchievementsResponse extends $pb.GeneratedMessage {
  factory GetAchievementsResponse({
    $core.Iterable<Achievement>? achievements,
  }) {
    final result = GetAchievementsResponse._();
    if (achievements != null) result.achievements.addAll(achievements);
    return result;
  }

  GetAchievementsResponse._();

  factory GetAchievementsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAchievementsResponse()..mergeFromBuffer(data, registry);
  factory GetAchievementsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAchievementsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAchievementsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: GetAchievementsResponse.$_createMessage)
    ..pPM<Achievement>(1, _omitFieldNames ? '' : 'achievements',
        subBuilder: Achievement.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAchievementsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAchievementsResponse copyWith(
          void Function(GetAchievementsResponse) updates) =>
      super.copyWith((message) => updates(message as GetAchievementsResponse))
          as GetAchievementsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAchievementsResponse() / GetAchievementsResponse.new instead')
  static GetAchievementsResponse create() => GetAchievementsResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetAchievementsResponse._();
  @$core.override
  GetAchievementsResponse createEmptyInstance() => GetAchievementsResponse._();
  @$core.pragma('dart2js:noInline')
  static GetAchievementsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAchievementsResponse>(
          GetAchievementsResponse.$_createMessage);
  static GetAchievementsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Achievement> get achievements => $_getList(0);
}

/// Запрос на открытие достижения
class UnlockAchievementRequest extends $pb.GeneratedMessage {
  factory UnlockAchievementRequest({
    $core.String? playerId,
    $core.String? name,
  }) {
    final result = UnlockAchievementRequest._();
    if (playerId != null) result.playerId = playerId;
    if (name != null) result.name = name;
    return result;
  }

  UnlockAchievementRequest._();

  factory UnlockAchievementRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnlockAchievementRequest()..mergeFromBuffer(data, registry);
  factory UnlockAchievementRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnlockAchievementRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnlockAchievementRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: UnlockAchievementRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnlockAchievementRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnlockAchievementRequest copyWith(
          void Function(UnlockAchievementRequest) updates) =>
      super.copyWith((message) => updates(message as UnlockAchievementRequest))
          as UnlockAchievementRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UnlockAchievementRequest() / UnlockAchievementRequest.new instead')
  static UnlockAchievementRequest create() => UnlockAchievementRequest._();
  static $pb.GeneratedMessage $_createMessage() => UnlockAchievementRequest._();
  @$core.override
  UnlockAchievementRequest createEmptyInstance() =>
      UnlockAchievementRequest._();
  @$core.pragma('dart2js:noInline')
  static UnlockAchievementRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnlockAchievementRequest>(
          UnlockAchievementRequest.$_createMessage);
  static UnlockAchievementRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

/// Ответ после открытия
class UnlockAchievementResponse extends $pb.GeneratedMessage {
  factory UnlockAchievementResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = UnlockAchievementResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  UnlockAchievementResponse._();

  factory UnlockAchievementResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnlockAchievementResponse()..mergeFromBuffer(data, registry);
  factory UnlockAchievementResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnlockAchievementResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnlockAchievementResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: UnlockAchievementResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnlockAchievementResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnlockAchievementResponse copyWith(
          void Function(UnlockAchievementResponse) updates) =>
      super.copyWith((message) => updates(message as UnlockAchievementResponse))
          as UnlockAchievementResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UnlockAchievementResponse() / UnlockAchievementResponse.new instead')
  static UnlockAchievementResponse create() => UnlockAchievementResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      UnlockAchievementResponse._();
  @$core.override
  UnlockAchievementResponse createEmptyInstance() =>
      UnlockAchievementResponse._();
  @$core.pragma('dart2js:noInline')
  static UnlockAchievementResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnlockAchievementResponse>(
          UnlockAchievementResponse.$_createMessage);
  static UnlockAchievementResponse? _defaultInstance;

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
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
