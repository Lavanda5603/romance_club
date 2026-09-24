// This is a generated file - do not edit.
//
// Generated from progress.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Прогресс игрока (текущее состояние)
class Progress extends $pb.GeneratedMessage {
  factory Progress({
    $core.int? id,
    $core.int? playerId,
    $core.int? episodeId,
    $core.int? sceneId,
    $core.Iterable<$core.MapEntry<$core.String, $core.bool>>? flags,
    $core.Iterable<$core.MapEntry<$core.String, $core.int>>? counters,
    $core.String? updatedAt,
  }) {
    final result = Progress._();
    if (id != null) result.id = id;
    if (playerId != null) result.playerId = playerId;
    if (episodeId != null) result.episodeId = episodeId;
    if (sceneId != null) result.sceneId = sceneId;
    if (flags != null) result.flags.addEntries(flags);
    if (counters != null) result.counters.addEntries(counters);
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  Progress._();

  factory Progress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Progress()..mergeFromBuffer(data, registry);
  factory Progress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Progress()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Progress',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: Progress.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..aI(2, _omitFieldNames ? '' : 'playerId')
    ..aI(3, _omitFieldNames ? '' : 'episodeId')
    ..aI(4, _omitFieldNames ? '' : 'sceneId')
    ..m<$core.String, $core.bool>(5, _omitFieldNames ? '' : 'flags',
        entryClassName: 'Progress.FlagsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OB,
        packageName: const $pb.PackageName('romance_club'))
    ..m<$core.String, $core.int>(6, _omitFieldNames ? '' : 'counters',
        entryClassName: 'Progress.CountersEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O3,
        packageName: const $pb.PackageName('romance_club'))
    ..aOS(7, _omitFieldNames ? '' : 'updatedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Progress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Progress copyWith(void Function(Progress) updates) =>
      super.copyWith((message) => updates(message as Progress)) as Progress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Progress() / Progress.new instead')
  static Progress create() => Progress._();
  static $pb.GeneratedMessage $_createMessage() => Progress._();
  @$core.override
  Progress createEmptyInstance() => Progress._();
  @$core.pragma('dart2js:noInline')
  static Progress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Progress>(Progress.$_createMessage);
  static Progress? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get playerId => $_getIZ(1);
  @$pb.TagNumber(2)
  set playerId($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPlayerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlayerId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get episodeId => $_getIZ(2);
  @$pb.TagNumber(3)
  set episodeId($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEpisodeId() => $_has(2);
  @$pb.TagNumber(3)
  void clearEpisodeId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get sceneId => $_getIZ(3);
  @$pb.TagNumber(4)
  set sceneId($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSceneId() => $_has(3);
  @$pb.TagNumber(4)
  void clearSceneId() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, $core.bool> get flags => $_getMap(4);

  @$pb.TagNumber(6)
  $pb.PbMap<$core.String, $core.int> get counters => $_getMap(5);

  @$pb.TagNumber(7)
  $core.String get updatedAt => $_getSZ(6);
  @$pb.TagNumber(7)
  set updatedAt($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUpdatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdatedAt() => $_clearField(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
