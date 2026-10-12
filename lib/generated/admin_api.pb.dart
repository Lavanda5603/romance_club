// This is a generated file - do not edit.
//
// Generated from admin_api.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Запрос на удаление ассета
class AdminDeleteAssetRequest extends $pb.GeneratedMessage {
  factory AdminDeleteAssetRequest({
    $core.String? assetId,
  }) {
    final result = AdminDeleteAssetRequest._();
    if (assetId != null) result.assetId = assetId;
    return result;
  }

  AdminDeleteAssetRequest._();

  factory AdminDeleteAssetRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminDeleteAssetRequest()..mergeFromBuffer(data, registry);
  factory AdminDeleteAssetRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminDeleteAssetRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdminDeleteAssetRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: AdminDeleteAssetRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'assetId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminDeleteAssetRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminDeleteAssetRequest copyWith(
          void Function(AdminDeleteAssetRequest) updates) =>
      super.copyWith((message) => updates(message as AdminDeleteAssetRequest))
          as AdminDeleteAssetRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AdminDeleteAssetRequest() / AdminDeleteAssetRequest.new instead')
  static AdminDeleteAssetRequest create() => AdminDeleteAssetRequest._();
  static $pb.GeneratedMessage $_createMessage() => AdminDeleteAssetRequest._();
  @$core.override
  AdminDeleteAssetRequest createEmptyInstance() => AdminDeleteAssetRequest._();
  @$core.pragma('dart2js:noInline')
  static AdminDeleteAssetRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdminDeleteAssetRequest>(
          AdminDeleteAssetRequest.$_createMessage);
  static AdminDeleteAssetRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get assetId => $_getSZ(0);
  @$pb.TagNumber(1)
  set assetId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAssetId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAssetId() => $_clearField(1);
}

/// Запрос на удаление эпизода
class AdminDeleteEpisodeRequest extends $pb.GeneratedMessage {
  factory AdminDeleteEpisodeRequest({
    $core.int? episodeId,
  }) {
    final result = AdminDeleteEpisodeRequest._();
    if (episodeId != null) result.episodeId = episodeId;
    return result;
  }

  AdminDeleteEpisodeRequest._();

  factory AdminDeleteEpisodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminDeleteEpisodeRequest()..mergeFromBuffer(data, registry);
  factory AdminDeleteEpisodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminDeleteEpisodeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdminDeleteEpisodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: AdminDeleteEpisodeRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'episodeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminDeleteEpisodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminDeleteEpisodeRequest copyWith(
          void Function(AdminDeleteEpisodeRequest) updates) =>
      super.copyWith((message) => updates(message as AdminDeleteEpisodeRequest))
          as AdminDeleteEpisodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AdminDeleteEpisodeRequest() / AdminDeleteEpisodeRequest.new instead')
  static AdminDeleteEpisodeRequest create() => AdminDeleteEpisodeRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      AdminDeleteEpisodeRequest._();
  @$core.override
  AdminDeleteEpisodeRequest createEmptyInstance() =>
      AdminDeleteEpisodeRequest._();
  @$core.pragma('dart2js:noInline')
  static AdminDeleteEpisodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdminDeleteEpisodeRequest>(
          AdminDeleteEpisodeRequest.$_createMessage);
  static AdminDeleteEpisodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get episodeId => $_getIZ(0);
  @$pb.TagNumber(1)
  set episodeId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEpisodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEpisodeId() => $_clearField(1);
}

/// Ответ админ-операции
class AdminResponse extends $pb.GeneratedMessage {
  factory AdminResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = AdminResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  AdminResponse._();

  factory AdminResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminResponse()..mergeFromBuffer(data, registry);
  factory AdminResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdminResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: AdminResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminResponse copyWith(void Function(AdminResponse) updates) =>
      super.copyWith((message) => updates(message as AdminResponse))
          as AdminResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AdminResponse() / AdminResponse.new instead')
  static AdminResponse create() => AdminResponse._();
  static $pb.GeneratedMessage $_createMessage() => AdminResponse._();
  @$core.override
  AdminResponse createEmptyInstance() => AdminResponse._();
  @$core.pragma('dart2js:noInline')
  static AdminResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AdminResponse>(
          AdminResponse.$_createMessage);
  static AdminResponse? _defaultInstance;

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
