// This is a generated file - do not edit.
//
// Generated from episode_api.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'episode.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Запрос на получение эпизода по ID
class GetEpisodeRequest extends $pb.GeneratedMessage {
  factory GetEpisodeRequest({
    $core.int? id,
  }) {
    final result = GetEpisodeRequest._();
    if (id != null) result.id = id;
    return result;
  }

  GetEpisodeRequest._();

  factory GetEpisodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetEpisodeRequest()..mergeFromBuffer(data, registry);
  factory GetEpisodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetEpisodeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetEpisodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: GetEpisodeRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEpisodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEpisodeRequest copyWith(void Function(GetEpisodeRequest) updates) =>
      super.copyWith((message) => updates(message as GetEpisodeRequest))
          as GetEpisodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetEpisodeRequest() / GetEpisodeRequest.new instead')
  static GetEpisodeRequest create() => GetEpisodeRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetEpisodeRequest._();
  @$core.override
  GetEpisodeRequest createEmptyInstance() => GetEpisodeRequest._();
  @$core.pragma('dart2js:noInline')
  static GetEpisodeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetEpisodeRequest>(
          GetEpisodeRequest.$_createMessage);
  static GetEpisodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

/// Запрос на получение всех эпизодов
class GetAllEpisodesRequest extends $pb.GeneratedMessage {
  factory GetAllEpisodesRequest() => GetAllEpisodesRequest._();

  GetAllEpisodesRequest._();

  factory GetAllEpisodesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAllEpisodesRequest()..mergeFromBuffer(data, registry);
  factory GetAllEpisodesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAllEpisodesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAllEpisodesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: GetAllEpisodesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAllEpisodesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAllEpisodesRequest copyWith(
          void Function(GetAllEpisodesRequest) updates) =>
      super.copyWith((message) => updates(message as GetAllEpisodesRequest))
          as GetAllEpisodesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAllEpisodesRequest() / GetAllEpisodesRequest.new instead')
  static GetAllEpisodesRequest create() => GetAllEpisodesRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetAllEpisodesRequest._();
  @$core.override
  GetAllEpisodesRequest createEmptyInstance() => GetAllEpisodesRequest._();
  @$core.pragma('dart2js:noInline')
  static GetAllEpisodesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAllEpisodesRequest>(
          GetAllEpisodesRequest.$_createMessage);
  static GetAllEpisodesRequest? _defaultInstance;
}

/// Ответ со всеми эпизодами
class GetAllEpisodesResponse extends $pb.GeneratedMessage {
  factory GetAllEpisodesResponse({
    $core.Iterable<$1.Episode>? episodes,
  }) {
    final result = GetAllEpisodesResponse._();
    if (episodes != null) result.episodes.addAll(episodes);
    return result;
  }

  GetAllEpisodesResponse._();

  factory GetAllEpisodesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAllEpisodesResponse()..mergeFromBuffer(data, registry);
  factory GetAllEpisodesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAllEpisodesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAllEpisodesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: GetAllEpisodesResponse.$_createMessage)
    ..pPM<$1.Episode>(1, _omitFieldNames ? '' : 'episodes',
        subBuilder: $1.Episode.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAllEpisodesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAllEpisodesResponse copyWith(
          void Function(GetAllEpisodesResponse) updates) =>
      super.copyWith((message) => updates(message as GetAllEpisodesResponse))
          as GetAllEpisodesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAllEpisodesResponse() / GetAllEpisodesResponse.new instead')
  static GetAllEpisodesResponse create() => GetAllEpisodesResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetAllEpisodesResponse._();
  @$core.override
  GetAllEpisodesResponse createEmptyInstance() => GetAllEpisodesResponse._();
  @$core.pragma('dart2js:noInline')
  static GetAllEpisodesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAllEpisodesResponse>(
          GetAllEpisodesResponse.$_createMessage);
  static GetAllEpisodesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$1.Episode> get episodes => $_getList(0);
}

/// Запрос на сохранение эпизода
class SaveEpisodeRequest extends $pb.GeneratedMessage {
  factory SaveEpisodeRequest({
    $1.Episode? episode,
  }) {
    final result = SaveEpisodeRequest._();
    if (episode != null) result.episode = episode;
    return result;
  }

  SaveEpisodeRequest._();

  factory SaveEpisodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveEpisodeRequest()..mergeFromBuffer(data, registry);
  factory SaveEpisodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveEpisodeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveEpisodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: SaveEpisodeRequest.$_createMessage)
    ..aOM<$1.Episode>(1, _omitFieldNames ? '' : 'episode',
        subBuilder: $1.Episode.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveEpisodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveEpisodeRequest copyWith(void Function(SaveEpisodeRequest) updates) =>
      super.copyWith((message) => updates(message as SaveEpisodeRequest))
          as SaveEpisodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SaveEpisodeRequest() / SaveEpisodeRequest.new instead')
  static SaveEpisodeRequest create() => SaveEpisodeRequest._();
  static $pb.GeneratedMessage $_createMessage() => SaveEpisodeRequest._();
  @$core.override
  SaveEpisodeRequest createEmptyInstance() => SaveEpisodeRequest._();
  @$core.pragma('dart2js:noInline')
  static SaveEpisodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveEpisodeRequest>(
          SaveEpisodeRequest.$_createMessage);
  static SaveEpisodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.Episode get episode => $_getN(0);
  @$pb.TagNumber(1)
  set episode($1.Episode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEpisode() => $_has(0);
  @$pb.TagNumber(1)
  void clearEpisode() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Episode ensureEpisode() => $_ensure(0);
}

/// Ответ после сохранения
class SaveEpisodeResponse extends $pb.GeneratedMessage {
  factory SaveEpisodeResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = SaveEpisodeResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  SaveEpisodeResponse._();

  factory SaveEpisodeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveEpisodeResponse()..mergeFromBuffer(data, registry);
  factory SaveEpisodeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveEpisodeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveEpisodeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: SaveEpisodeResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveEpisodeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveEpisodeResponse copyWith(void Function(SaveEpisodeResponse) updates) =>
      super.copyWith((message) => updates(message as SaveEpisodeResponse))
          as SaveEpisodeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SaveEpisodeResponse() / SaveEpisodeResponse.new instead')
  static SaveEpisodeResponse create() => SaveEpisodeResponse._();
  static $pb.GeneratedMessage $_createMessage() => SaveEpisodeResponse._();
  @$core.override
  SaveEpisodeResponse createEmptyInstance() => SaveEpisodeResponse._();
  @$core.pragma('dart2js:noInline')
  static SaveEpisodeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveEpisodeResponse>(
          SaveEpisodeResponse.$_createMessage);
  static SaveEpisodeResponse? _defaultInstance;

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
