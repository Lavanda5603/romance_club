// This is a generated file - do not edit.
//
// Generated from scene.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'choice.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Сцена (текст и возможные выборы)
class Scene extends $pb.GeneratedMessage {
  factory Scene({
    $core.int? id,
    $core.String? background,
    $core.String? character,
    $core.Iterable<$core.String>? texts,
    $core.Iterable<$0.Choice>? choices,
    $core.String? condition,
  }) {
    final result = Scene._();
    if (id != null) result.id = id;
    if (background != null) result.background = background;
    if (character != null) result.character = character;
    if (texts != null) result.texts.addAll(texts);
    if (choices != null) result.choices.addAll(choices);
    if (condition != null) result.condition = condition;
    return result;
  }

  Scene._();

  factory Scene.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Scene()..mergeFromBuffer(data, registry);
  factory Scene.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Scene()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Scene',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: Scene.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'background')
    ..aOS(3, _omitFieldNames ? '' : 'character')
    ..pPS(4, _omitFieldNames ? '' : 'texts')
    ..pPM<$0.Choice>(5, _omitFieldNames ? '' : 'choices',
        subBuilder: $0.Choice.$_createMessage)
    ..aOS(6, _omitFieldNames ? '' : 'condition')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Scene clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Scene copyWith(void Function(Scene) updates) =>
      super.copyWith((message) => updates(message as Scene)) as Scene;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Scene() / Scene.new instead')
  static Scene create() => Scene._();
  static $pb.GeneratedMessage $_createMessage() => Scene._();
  @$core.override
  Scene createEmptyInstance() => Scene._();
  @$core.pragma('dart2js:noInline')
  static Scene getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Scene>(Scene.$_createMessage);
  static Scene? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get background => $_getSZ(1);
  @$pb.TagNumber(2)
  set background($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBackground() => $_has(1);
  @$pb.TagNumber(2)
  void clearBackground() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get character => $_getSZ(2);
  @$pb.TagNumber(3)
  set character($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCharacter() => $_has(2);
  @$pb.TagNumber(3)
  void clearCharacter() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get texts => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<$0.Choice> get choices => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get condition => $_getSZ(5);
  @$pb.TagNumber(6)
  set condition($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCondition() => $_has(5);
  @$pb.TagNumber(6)
  void clearCondition() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
