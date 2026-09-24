// This is a generated file - do not edit.
//
// Generated from player_choice.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Выбор, который сделал игрок
class PlayerChoice extends $pb.GeneratedMessage {
  factory PlayerChoice({
    $core.int? id,
    $core.int? playerId,
    $core.int? choiceId,
    $core.String? madeAt,
  }) {
    final result = PlayerChoice._();
    if (id != null) result.id = id;
    if (playerId != null) result.playerId = playerId;
    if (choiceId != null) result.choiceId = choiceId;
    if (madeAt != null) result.madeAt = madeAt;
    return result;
  }

  PlayerChoice._();

  factory PlayerChoice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayerChoice()..mergeFromBuffer(data, registry);
  factory PlayerChoice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayerChoice()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayerChoice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: PlayerChoice.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..aI(2, _omitFieldNames ? '' : 'playerId')
    ..aI(3, _omitFieldNames ? '' : 'choiceId')
    ..aOS(4, _omitFieldNames ? '' : 'madeAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayerChoice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayerChoice copyWith(void Function(PlayerChoice) updates) =>
      super.copyWith((message) => updates(message as PlayerChoice))
          as PlayerChoice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PlayerChoice() / PlayerChoice.new instead')
  static PlayerChoice create() => PlayerChoice._();
  static $pb.GeneratedMessage $_createMessage() => PlayerChoice._();
  @$core.override
  PlayerChoice createEmptyInstance() => PlayerChoice._();
  @$core.pragma('dart2js:noInline')
  static PlayerChoice getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlayerChoice>(
          PlayerChoice.$_createMessage);
  static PlayerChoice? _defaultInstance;

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
  $core.int get choiceId => $_getIZ(2);
  @$pb.TagNumber(3)
  set choiceId($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChoiceId() => $_has(2);
  @$pb.TagNumber(3)
  void clearChoiceId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get madeAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set madeAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMadeAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearMadeAt() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
