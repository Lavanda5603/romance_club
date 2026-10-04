// This is a generated file - do not edit.
//
// Generated from progress_api.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Запрос на получение прогресса
class GetProgressRequest extends $pb.GeneratedMessage {
  factory GetProgressRequest({
    $core.String? playerId,
    $core.int? episodeId,
  }) {
    final result = GetProgressRequest._();
    if (playerId != null) result.playerId = playerId;
    if (episodeId != null) result.episodeId = episodeId;
    return result;
  }

  GetProgressRequest._();

  factory GetProgressRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetProgressRequest()..mergeFromBuffer(data, registry);
  factory GetProgressRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetProgressRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetProgressRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: GetProgressRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..aI(2, _omitFieldNames ? '' : 'episodeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetProgressRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetProgressRequest copyWith(void Function(GetProgressRequest) updates) =>
      super.copyWith((message) => updates(message as GetProgressRequest))
          as GetProgressRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetProgressRequest() / GetProgressRequest.new instead')
  static GetProgressRequest create() => GetProgressRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetProgressRequest._();
  @$core.override
  GetProgressRequest createEmptyInstance() => GetProgressRequest._();
  @$core.pragma('dart2js:noInline')
  static GetProgressRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetProgressRequest>(
          GetProgressRequest.$_createMessage);
  static GetProgressRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get episodeId => $_getIZ(1);
  @$pb.TagNumber(2)
  set episodeId($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEpisodeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEpisodeId() => $_clearField(2);
}

/// Запрос на сохранение прогресса
class SaveProgressRequest extends $pb.GeneratedMessage {
  factory SaveProgressRequest({
    $core.String? playerId,
    $core.int? episodeId,
    $core.String? sceneId,
    $core.Iterable<$core.MapEntry<$core.String, $core.bool>>? flags,
    $core.Iterable<$core.MapEntry<$core.String, $core.int>>? counters,
  }) {
    final result = SaveProgressRequest._();
    if (playerId != null) result.playerId = playerId;
    if (episodeId != null) result.episodeId = episodeId;
    if (sceneId != null) result.sceneId = sceneId;
    if (flags != null) result.flags.addEntries(flags);
    if (counters != null) result.counters.addEntries(counters);
    return result;
  }

  SaveProgressRequest._();

  factory SaveProgressRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveProgressRequest()..mergeFromBuffer(data, registry);
  factory SaveProgressRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveProgressRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveProgressRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: SaveProgressRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..aI(2, _omitFieldNames ? '' : 'episodeId')
    ..aOS(3, _omitFieldNames ? '' : 'sceneId')
    ..m<$core.String, $core.bool>(4, _omitFieldNames ? '' : 'flags',
        entryClassName: 'SaveProgressRequest.FlagsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OB,
        packageName: const $pb.PackageName('romance_club'))
    ..m<$core.String, $core.int>(5, _omitFieldNames ? '' : 'counters',
        entryClassName: 'SaveProgressRequest.CountersEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O3,
        packageName: const $pb.PackageName('romance_club'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveProgressRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveProgressRequest copyWith(void Function(SaveProgressRequest) updates) =>
      super.copyWith((message) => updates(message as SaveProgressRequest))
          as SaveProgressRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SaveProgressRequest() / SaveProgressRequest.new instead')
  static SaveProgressRequest create() => SaveProgressRequest._();
  static $pb.GeneratedMessage $_createMessage() => SaveProgressRequest._();
  @$core.override
  SaveProgressRequest createEmptyInstance() => SaveProgressRequest._();
  @$core.pragma('dart2js:noInline')
  static SaveProgressRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveProgressRequest>(
          SaveProgressRequest.$_createMessage);
  static SaveProgressRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get episodeId => $_getIZ(1);
  @$pb.TagNumber(2)
  set episodeId($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEpisodeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEpisodeId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sceneId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sceneId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSceneId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSceneId() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbMap<$core.String, $core.bool> get flags => $_getMap(3);

  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, $core.int> get counters => $_getMap(4);
}

/// Ответ после сохранения
class SaveProgressResponse extends $pb.GeneratedMessage {
  factory SaveProgressResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = SaveProgressResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  SaveProgressResponse._();

  factory SaveProgressResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveProgressResponse()..mergeFromBuffer(data, registry);
  factory SaveProgressResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveProgressResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveProgressResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: SaveProgressResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveProgressResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveProgressResponse copyWith(void Function(SaveProgressResponse) updates) =>
      super.copyWith((message) => updates(message as SaveProgressResponse))
          as SaveProgressResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SaveProgressResponse() / SaveProgressResponse.new instead')
  static SaveProgressResponse create() => SaveProgressResponse._();
  static $pb.GeneratedMessage $_createMessage() => SaveProgressResponse._();
  @$core.override
  SaveProgressResponse createEmptyInstance() => SaveProgressResponse._();
  @$core.pragma('dart2js:noInline')
  static SaveProgressResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveProgressResponse>(
          SaveProgressResponse.$_createMessage);
  static SaveProgressResponse? _defaultInstance;

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

/// Запрос на сброс прогресса
class ResetProgressRequest extends $pb.GeneratedMessage {
  factory ResetProgressRequest({
    $core.String? playerId,
  }) {
    final result = ResetProgressRequest._();
    if (playerId != null) result.playerId = playerId;
    return result;
  }

  ResetProgressRequest._();

  factory ResetProgressRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetProgressRequest()..mergeFromBuffer(data, registry);
  factory ResetProgressRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetProgressRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetProgressRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: ResetProgressRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetProgressRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetProgressRequest copyWith(void Function(ResetProgressRequest) updates) =>
      super.copyWith((message) => updates(message as ResetProgressRequest))
          as ResetProgressRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResetProgressRequest() / ResetProgressRequest.new instead')
  static ResetProgressRequest create() => ResetProgressRequest._();
  static $pb.GeneratedMessage $_createMessage() => ResetProgressRequest._();
  @$core.override
  ResetProgressRequest createEmptyInstance() => ResetProgressRequest._();
  @$core.pragma('dart2js:noInline')
  static ResetProgressRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResetProgressRequest>(
          ResetProgressRequest.$_createMessage);
  static ResetProgressRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);
}

/// Ответ после сброса
class ResetProgressResponse extends $pb.GeneratedMessage {
  factory ResetProgressResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = ResetProgressResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  ResetProgressResponse._();

  factory ResetProgressResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetProgressResponse()..mergeFromBuffer(data, registry);
  factory ResetProgressResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetProgressResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetProgressResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: ResetProgressResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetProgressResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetProgressResponse copyWith(
          void Function(ResetProgressResponse) updates) =>
      super.copyWith((message) => updates(message as ResetProgressResponse))
          as ResetProgressResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResetProgressResponse() / ResetProgressResponse.new instead')
  static ResetProgressResponse create() => ResetProgressResponse._();
  static $pb.GeneratedMessage $_createMessage() => ResetProgressResponse._();
  @$core.override
  ResetProgressResponse createEmptyInstance() => ResetProgressResponse._();
  @$core.pragma('dart2js:noInline')
  static ResetProgressResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResetProgressResponse>(
          ResetProgressResponse.$_createMessage);
  static ResetProgressResponse? _defaultInstance;

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
