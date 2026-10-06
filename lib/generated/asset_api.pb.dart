// This is a generated file - do not edit.
//
// Generated from asset_api.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Ассет (картинка, звук)
class Asset extends $pb.GeneratedMessage {
  factory Asset({
    $core.String? id,
    $core.String? type,
    $core.String? name,
    $core.String? emotion,
    $core.String? url,
    $core.String? displayName,
    $core.String? episodeId,
    $core.List<$core.int>? fileData,
  }) {
    final result = Asset._();
    if (id != null) result.id = id;
    if (type != null) result.type = type;
    if (name != null) result.name = name;
    if (emotion != null) result.emotion = emotion;
    if (url != null) result.url = url;
    if (displayName != null) result.displayName = displayName;
    if (episodeId != null) result.episodeId = episodeId;
    if (fileData != null) result.fileData = fileData;
    return result;
  }

  Asset._();

  factory Asset.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Asset()..mergeFromBuffer(data, registry);
  factory Asset.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Asset()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Asset',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: Asset.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'emotion')
    ..aOS(5, _omitFieldNames ? '' : 'url')
    ..aOS(6, _omitFieldNames ? '' : 'displayName')
    ..aOS(7, _omitFieldNames ? '' : 'episodeId')
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'fileData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Asset clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Asset copyWith(void Function(Asset) updates) =>
      super.copyWith((message) => updates(message as Asset)) as Asset;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Asset() / Asset.new instead')
  static Asset create() => Asset._();
  static $pb.GeneratedMessage $_createMessage() => Asset._();
  @$core.override
  Asset createEmptyInstance() => Asset._();
  @$core.pragma('dart2js:noInline')
  static Asset getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Asset>(Asset.$_createMessage);
  static Asset? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get emotion => $_getSZ(3);
  @$pb.TagNumber(4)
  set emotion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEmotion() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmotion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get url => $_getSZ(4);
  @$pb.TagNumber(5)
  set url($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearUrl() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get displayName => $_getSZ(5);
  @$pb.TagNumber(6)
  set displayName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDisplayName() => $_has(5);
  @$pb.TagNumber(6)
  void clearDisplayName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get episodeId => $_getSZ(6);
  @$pb.TagNumber(7)
  set episodeId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEpisodeId() => $_has(6);
  @$pb.TagNumber(7)
  void clearEpisodeId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.List<$core.int> get fileData => $_getN(7);
  @$pb.TagNumber(8)
  set fileData($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFileData() => $_has(7);
  @$pb.TagNumber(8)
  void clearFileData() => $_clearField(8);
}

/// Запрос на получение ассетов по типу
class GetAssetsRequest extends $pb.GeneratedMessage {
  factory GetAssetsRequest({
    $core.String? type,
    $core.String? episodeId,
  }) {
    final result = GetAssetsRequest._();
    if (type != null) result.type = type;
    if (episodeId != null) result.episodeId = episodeId;
    return result;
  }

  GetAssetsRequest._();

  factory GetAssetsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAssetsRequest()..mergeFromBuffer(data, registry);
  factory GetAssetsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAssetsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAssetsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: GetAssetsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOS(2, _omitFieldNames ? '' : 'episodeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAssetsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAssetsRequest copyWith(void Function(GetAssetsRequest) updates) =>
      super.copyWith((message) => updates(message as GetAssetsRequest))
          as GetAssetsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetAssetsRequest() / GetAssetsRequest.new instead')
  static GetAssetsRequest create() => GetAssetsRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetAssetsRequest._();
  @$core.override
  GetAssetsRequest createEmptyInstance() => GetAssetsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetAssetsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAssetsRequest>(
          GetAssetsRequest.$_createMessage);
  static GetAssetsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get episodeId => $_getSZ(1);
  @$pb.TagNumber(2)
  set episodeId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEpisodeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEpisodeId() => $_clearField(2);
}

/// Ответ со списком ассетов
class GetAssetsResponse extends $pb.GeneratedMessage {
  factory GetAssetsResponse({
    $core.Iterable<Asset>? assets,
  }) {
    final result = GetAssetsResponse._();
    if (assets != null) result.assets.addAll(assets);
    return result;
  }

  GetAssetsResponse._();

  factory GetAssetsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAssetsResponse()..mergeFromBuffer(data, registry);
  factory GetAssetsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAssetsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAssetsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: GetAssetsResponse.$_createMessage)
    ..pPM<Asset>(1, _omitFieldNames ? '' : 'assets',
        subBuilder: Asset.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAssetsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAssetsResponse copyWith(void Function(GetAssetsResponse) updates) =>
      super.copyWith((message) => updates(message as GetAssetsResponse))
          as GetAssetsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetAssetsResponse() / GetAssetsResponse.new instead')
  static GetAssetsResponse create() => GetAssetsResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetAssetsResponse._();
  @$core.override
  GetAssetsResponse createEmptyInstance() => GetAssetsResponse._();
  @$core.pragma('dart2js:noInline')
  static GetAssetsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAssetsResponse>(
          GetAssetsResponse.$_createMessage);
  static GetAssetsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Asset> get assets => $_getList(0);
}

/// Запрос на загрузку нового ассета
class UploadAssetRequest extends $pb.GeneratedMessage {
  factory UploadAssetRequest({
    $core.String? type,
    $core.String? name,
    $core.String? emotion,
    $core.String? displayName,
    $core.String? episodeId,
    $core.List<$core.int>? fileData,
    $core.String? fileName,
  }) {
    final result = UploadAssetRequest._();
    if (type != null) result.type = type;
    if (name != null) result.name = name;
    if (emotion != null) result.emotion = emotion;
    if (displayName != null) result.displayName = displayName;
    if (episodeId != null) result.episodeId = episodeId;
    if (fileData != null) result.fileData = fileData;
    if (fileName != null) result.fileName = fileName;
    return result;
  }

  UploadAssetRequest._();

  factory UploadAssetRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadAssetRequest()..mergeFromBuffer(data, registry);
  factory UploadAssetRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadAssetRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadAssetRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: UploadAssetRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'emotion')
    ..aOS(4, _omitFieldNames ? '' : 'displayName')
    ..aOS(5, _omitFieldNames ? '' : 'episodeId')
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'fileData', $pb.PbFieldType.OY)
    ..aOS(7, _omitFieldNames ? '' : 'fileName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadAssetRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadAssetRequest copyWith(void Function(UploadAssetRequest) updates) =>
      super.copyWith((message) => updates(message as UploadAssetRequest))
          as UploadAssetRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UploadAssetRequest() / UploadAssetRequest.new instead')
  static UploadAssetRequest create() => UploadAssetRequest._();
  static $pb.GeneratedMessage $_createMessage() => UploadAssetRequest._();
  @$core.override
  UploadAssetRequest createEmptyInstance() => UploadAssetRequest._();
  @$core.pragma('dart2js:noInline')
  static UploadAssetRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadAssetRequest>(
          UploadAssetRequest.$_createMessage);
  static UploadAssetRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get emotion => $_getSZ(2);
  @$pb.TagNumber(3)
  set emotion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEmotion() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmotion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get displayName => $_getSZ(3);
  @$pb.TagNumber(4)
  set displayName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisplayName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplayName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get episodeId => $_getSZ(4);
  @$pb.TagNumber(5)
  set episodeId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEpisodeId() => $_has(4);
  @$pb.TagNumber(5)
  void clearEpisodeId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get fileData => $_getN(5);
  @$pb.TagNumber(6)
  set fileData($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFileData() => $_has(5);
  @$pb.TagNumber(6)
  void clearFileData() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get fileName => $_getSZ(6);
  @$pb.TagNumber(7)
  set fileName($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFileName() => $_has(6);
  @$pb.TagNumber(7)
  void clearFileName() => $_clearField(7);
}

/// Ответ после загрузки
class UploadAssetResponse extends $pb.GeneratedMessage {
  factory UploadAssetResponse({
    $core.bool? success,
    $core.String? message,
    Asset? asset,
  }) {
    final result = UploadAssetResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (asset != null) result.asset = asset;
    return result;
  }

  UploadAssetResponse._();

  factory UploadAssetResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadAssetResponse()..mergeFromBuffer(data, registry);
  factory UploadAssetResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadAssetResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadAssetResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: UploadAssetResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<Asset>(3, _omitFieldNames ? '' : 'asset',
        subBuilder: Asset.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadAssetResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadAssetResponse copyWith(void Function(UploadAssetResponse) updates) =>
      super.copyWith((message) => updates(message as UploadAssetResponse))
          as UploadAssetResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use UploadAssetResponse() / UploadAssetResponse.new instead')
  static UploadAssetResponse create() => UploadAssetResponse._();
  static $pb.GeneratedMessage $_createMessage() => UploadAssetResponse._();
  @$core.override
  UploadAssetResponse createEmptyInstance() => UploadAssetResponse._();
  @$core.pragma('dart2js:noInline')
  static UploadAssetResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadAssetResponse>(
          UploadAssetResponse.$_createMessage);
  static UploadAssetResponse? _defaultInstance;

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
  Asset get asset => $_getN(2);
  @$pb.TagNumber(3)
  set asset(Asset value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAsset() => $_has(2);
  @$pb.TagNumber(3)
  void clearAsset() => $_clearField(3);
  @$pb.TagNumber(3)
  Asset ensureAsset() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
