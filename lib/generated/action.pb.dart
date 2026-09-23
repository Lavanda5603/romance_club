// This is a generated file - do not edit.
//
// Generated from action.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Действие (происходит после выбора)
class Action extends $pb.GeneratedMessage {
  factory Action({
    $core.String? type,
    $core.int? sceneId,
    $core.String? flagName,
    $core.bool? flagValue,
    $core.String? counterName,
    $core.int? counterValue,
    $core.String? soundPath,
    $core.String? imagePath,
  }) {
    final result = Action._();
    if (type != null) result.type = type;
    if (sceneId != null) result.sceneId = sceneId;
    if (flagName != null) result.flagName = flagName;
    if (flagValue != null) result.flagValue = flagValue;
    if (counterName != null) result.counterName = counterName;
    if (counterValue != null) result.counterValue = counterValue;
    if (soundPath != null) result.soundPath = soundPath;
    if (imagePath != null) result.imagePath = imagePath;
    return result;
  }

  Action._();

  factory Action.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Action()..mergeFromBuffer(data, registry);
  factory Action.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Action()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Action',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: Action.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aI(2, _omitFieldNames ? '' : 'sceneId')
    ..aOS(3, _omitFieldNames ? '' : 'flagName')
    ..aOB(4, _omitFieldNames ? '' : 'flagValue')
    ..aOS(5, _omitFieldNames ? '' : 'counterName')
    ..aI(6, _omitFieldNames ? '' : 'counterValue')
    ..aOS(7, _omitFieldNames ? '' : 'soundPath')
    ..aOS(8, _omitFieldNames ? '' : 'imagePath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Action clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Action copyWith(void Function(Action) updates) =>
      super.copyWith((message) => updates(message as Action)) as Action;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Action() / Action.new instead')
  static Action create() => Action._();
  static $pb.GeneratedMessage $_createMessage() => Action._();
  @$core.override
  Action createEmptyInstance() => Action._();
  @$core.pragma('dart2js:noInline')
  static Action getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Action>(Action.$_createMessage);
  static Action? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get sceneId => $_getIZ(1);
  @$pb.TagNumber(2)
  set sceneId($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSceneId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSceneId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get flagName => $_getSZ(2);
  @$pb.TagNumber(3)
  set flagName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFlagName() => $_has(2);
  @$pb.TagNumber(3)
  void clearFlagName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get flagValue => $_getBF(3);
  @$pb.TagNumber(4)
  set flagValue($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFlagValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearFlagValue() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get counterName => $_getSZ(4);
  @$pb.TagNumber(5)
  set counterName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCounterName() => $_has(4);
  @$pb.TagNumber(5)
  void clearCounterName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get counterValue => $_getIZ(5);
  @$pb.TagNumber(6)
  set counterValue($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCounterValue() => $_has(5);
  @$pb.TagNumber(6)
  void clearCounterValue() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get soundPath => $_getSZ(6);
  @$pb.TagNumber(7)
  set soundPath($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSoundPath() => $_has(6);
  @$pb.TagNumber(7)
  void clearSoundPath() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get imagePath => $_getSZ(7);
  @$pb.TagNumber(8)
  set imagePath($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasImagePath() => $_has(7);
  @$pb.TagNumber(8)
  void clearImagePath() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
