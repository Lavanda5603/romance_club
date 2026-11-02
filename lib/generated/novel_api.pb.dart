// This is a generated file - do not edit.
//
// Generated from novel_api.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Novel extends $pb.GeneratedMessage {
  factory Novel({
    $core.String? id,
    $core.String? title,
    $core.String? coverId,
    $core.String? backgroundId,
    $core.String? musicId,
    $core.String? clickId,
    $core.String? configJson,
    $core.int? revision,
  }) {
    final result = Novel._();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (coverId != null) result.coverId = coverId;
    if (backgroundId != null) result.backgroundId = backgroundId;
    if (musicId != null) result.musicId = musicId;
    if (clickId != null) result.clickId = clickId;
    if (configJson != null) result.configJson = configJson;
    if (revision != null) result.revision = revision;
    return result;
  }

  Novel._();

  factory Novel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Novel()..mergeFromBuffer(data, registry);
  factory Novel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Novel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Novel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: Novel.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'coverId')
    ..aOS(4, _omitFieldNames ? '' : 'backgroundId')
    ..aOS(5, _omitFieldNames ? '' : 'musicId')
    ..aOS(6, _omitFieldNames ? '' : 'clickId')
    ..aOS(7, _omitFieldNames ? '' : 'configJson')
    ..aI(8, _omitFieldNames ? '' : 'revision')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Novel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Novel copyWith(void Function(Novel) updates) =>
      super.copyWith((message) => updates(message as Novel)) as Novel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Novel() / Novel.new instead')
  static Novel create() => Novel._();
  static $pb.GeneratedMessage $_createMessage() => Novel._();
  @$core.override
  Novel createEmptyInstance() => Novel._();
  @$core.pragma('dart2js:noInline')
  static Novel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Novel>(Novel.$_createMessage);
  static Novel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get coverId => $_getSZ(2);
  @$pb.TagNumber(3)
  set coverId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCoverId() => $_has(2);
  @$pb.TagNumber(3)
  void clearCoverId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get backgroundId => $_getSZ(3);
  @$pb.TagNumber(4)
  set backgroundId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBackgroundId() => $_has(3);
  @$pb.TagNumber(4)
  void clearBackgroundId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get musicId => $_getSZ(4);
  @$pb.TagNumber(5)
  set musicId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMusicId() => $_has(4);
  @$pb.TagNumber(5)
  void clearMusicId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get clickId => $_getSZ(5);
  @$pb.TagNumber(6)
  set clickId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasClickId() => $_has(5);
  @$pb.TagNumber(6)
  void clearClickId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get configJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set configJson($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasConfigJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearConfigJson() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get revision => $_getIZ(7);
  @$pb.TagNumber(8)
  set revision($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRevision() => $_has(7);
  @$pb.TagNumber(8)
  void clearRevision() => $_clearField(8);
}

class NovelRequest extends $pb.GeneratedMessage {
  factory NovelRequest({
    $core.String? novelId,
  }) {
    final result = NovelRequest._();
    if (novelId != null) result.novelId = novelId;
    return result;
  }

  NovelRequest._();

  factory NovelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NovelRequest()..mergeFromBuffer(data, registry);
  factory NovelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NovelRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NovelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: NovelRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'novelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NovelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NovelRequest copyWith(void Function(NovelRequest) updates) =>
      super.copyWith((message) => updates(message as NovelRequest))
          as NovelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NovelRequest() / NovelRequest.new instead')
  static NovelRequest create() => NovelRequest._();
  static $pb.GeneratedMessage $_createMessage() => NovelRequest._();
  @$core.override
  NovelRequest createEmptyInstance() => NovelRequest._();
  @$core.pragma('dart2js:noInline')
  static NovelRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NovelRequest>(
          NovelRequest.$_createMessage);
  static NovelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get novelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set novelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNovelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNovelId() => $_clearField(1);
}

class ListNovelsRequest extends $pb.GeneratedMessage {
  factory ListNovelsRequest() => ListNovelsRequest._();

  ListNovelsRequest._();

  factory ListNovelsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListNovelsRequest()..mergeFromBuffer(data, registry);
  factory ListNovelsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListNovelsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListNovelsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: ListNovelsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNovelsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNovelsRequest copyWith(void Function(ListNovelsRequest) updates) =>
      super.copyWith((message) => updates(message as ListNovelsRequest))
          as ListNovelsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListNovelsRequest() / ListNovelsRequest.new instead')
  static ListNovelsRequest create() => ListNovelsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListNovelsRequest._();
  @$core.override
  ListNovelsRequest createEmptyInstance() => ListNovelsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListNovelsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListNovelsRequest>(
          ListNovelsRequest.$_createMessage);
  static ListNovelsRequest? _defaultInstance;
}

class ListNovelsResponse extends $pb.GeneratedMessage {
  factory ListNovelsResponse({
    $core.Iterable<Novel>? novels,
  }) {
    final result = ListNovelsResponse._();
    if (novels != null) result.novels.addAll(novels);
    return result;
  }

  ListNovelsResponse._();

  factory ListNovelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListNovelsResponse()..mergeFromBuffer(data, registry);
  factory ListNovelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListNovelsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListNovelsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: ListNovelsResponse.$_createMessage)
    ..pPM<Novel>(1, _omitFieldNames ? '' : 'novels',
        subBuilder: Novel.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNovelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNovelsResponse copyWith(void Function(ListNovelsResponse) updates) =>
      super.copyWith((message) => updates(message as ListNovelsResponse))
          as ListNovelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListNovelsResponse() / ListNovelsResponse.new instead')
  static ListNovelsResponse create() => ListNovelsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListNovelsResponse._();
  @$core.override
  ListNovelsResponse createEmptyInstance() => ListNovelsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListNovelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListNovelsResponse>(
          ListNovelsResponse.$_createMessage);
  static ListNovelsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Novel> get novels => $_getList(0);
}

class CreateNovelEpisodeRequest extends $pb.GeneratedMessage {
  factory CreateNovelEpisodeRequest({
    $core.String? novelId,
    $core.String? title,
  }) {
    final result = CreateNovelEpisodeRequest._();
    if (novelId != null) result.novelId = novelId;
    if (title != null) result.title = title;
    return result;
  }

  CreateNovelEpisodeRequest._();

  factory CreateNovelEpisodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateNovelEpisodeRequest()..mergeFromBuffer(data, registry);
  factory CreateNovelEpisodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateNovelEpisodeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateNovelEpisodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: CreateNovelEpisodeRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'novelId')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateNovelEpisodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateNovelEpisodeRequest copyWith(
          void Function(CreateNovelEpisodeRequest) updates) =>
      super.copyWith((message) => updates(message as CreateNovelEpisodeRequest))
          as CreateNovelEpisodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateNovelEpisodeRequest() / CreateNovelEpisodeRequest.new instead')
  static CreateNovelEpisodeRequest create() => CreateNovelEpisodeRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      CreateNovelEpisodeRequest._();
  @$core.override
  CreateNovelEpisodeRequest createEmptyInstance() =>
      CreateNovelEpisodeRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateNovelEpisodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateNovelEpisodeRequest>(
          CreateNovelEpisodeRequest.$_createMessage);
  static CreateNovelEpisodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get novelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set novelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNovelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNovelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);
}

class UploadNovelAudioRequest extends $pb.GeneratedMessage {
  factory UploadNovelAudioRequest({
    $core.String? novelId,
    $core.String? kind,
    $core.List<$core.int>? data,
  }) {
    final result = UploadNovelAudioRequest._();
    if (novelId != null) result.novelId = novelId;
    if (kind != null) result.kind = kind;
    if (data != null) result.data = data;
    return result;
  }

  UploadNovelAudioRequest._();

  factory UploadNovelAudioRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadNovelAudioRequest()..mergeFromBuffer(data, registry);
  factory UploadNovelAudioRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadNovelAudioRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadNovelAudioRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: UploadNovelAudioRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'novelId')
    ..aOS(2, _omitFieldNames ? '' : 'kind')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadNovelAudioRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadNovelAudioRequest copyWith(
          void Function(UploadNovelAudioRequest) updates) =>
      super.copyWith((message) => updates(message as UploadNovelAudioRequest))
          as UploadNovelAudioRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UploadNovelAudioRequest() / UploadNovelAudioRequest.new instead')
  static UploadNovelAudioRequest create() => UploadNovelAudioRequest._();
  static $pb.GeneratedMessage $_createMessage() => UploadNovelAudioRequest._();
  @$core.override
  UploadNovelAudioRequest createEmptyInstance() => UploadNovelAudioRequest._();
  @$core.pragma('dart2js:noInline')
  static UploadNovelAudioRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadNovelAudioRequest>(
          UploadNovelAudioRequest.$_createMessage);
  static UploadNovelAudioRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get novelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set novelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNovelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNovelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get data => $_getN(2);
  @$pb.TagNumber(3)
  set data($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => $_clearField(3);
}

class NovelAudioRequest extends $pb.GeneratedMessage {
  factory NovelAudioRequest({
    $core.String? novelId,
    $core.String? id,
  }) {
    final result = NovelAudioRequest._();
    if (novelId != null) result.novelId = novelId;
    if (id != null) result.id = id;
    return result;
  }

  NovelAudioRequest._();

  factory NovelAudioRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NovelAudioRequest()..mergeFromBuffer(data, registry);
  factory NovelAudioRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NovelAudioRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NovelAudioRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: NovelAudioRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'novelId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NovelAudioRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NovelAudioRequest copyWith(void Function(NovelAudioRequest) updates) =>
      super.copyWith((message) => updates(message as NovelAudioRequest))
          as NovelAudioRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NovelAudioRequest() / NovelAudioRequest.new instead')
  static NovelAudioRequest create() => NovelAudioRequest._();
  static $pb.GeneratedMessage $_createMessage() => NovelAudioRequest._();
  @$core.override
  NovelAudioRequest createEmptyInstance() => NovelAudioRequest._();
  @$core.pragma('dart2js:noInline')
  static NovelAudioRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NovelAudioRequest>(
          NovelAudioRequest.$_createMessage);
  static NovelAudioRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get novelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set novelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNovelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNovelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);
}

class NovelAudio extends $pb.GeneratedMessage {
  factory NovelAudio({
    $core.String? id,
    $core.List<$core.int>? data,
    $core.String? hash,
  }) {
    final result = NovelAudio._();
    if (id != null) result.id = id;
    if (data != null) result.data = data;
    if (hash != null) result.hash = hash;
    return result;
  }

  NovelAudio._();

  factory NovelAudio.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NovelAudio()..mergeFromBuffer(data, registry);
  factory NovelAudio.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NovelAudio()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NovelAudio',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: NovelAudio.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'hash')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NovelAudio clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NovelAudio copyWith(void Function(NovelAudio) updates) =>
      super.copyWith((message) => updates(message as NovelAudio)) as NovelAudio;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NovelAudio() / NovelAudio.new instead')
  static NovelAudio create() => NovelAudio._();
  static $pb.GeneratedMessage $_createMessage() => NovelAudio._();
  @$core.override
  NovelAudio createEmptyInstance() => NovelAudio._();
  @$core.pragma('dart2js:noInline')
  static NovelAudio getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NovelAudio>(NovelAudio.$_createMessage);
  static NovelAudio? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get hash => $_getSZ(2);
  @$pb.TagNumber(3)
  set hash($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHash() => $_has(2);
  @$pb.TagNumber(3)
  void clearHash() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');