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
    $core.String? title,
    $core.String? background,
    $core.String? character,
    $core.Iterable<$core.String>? texts,
    $core.Iterable<$0.Choice>? choices,
    $core.String? condition,
    $core.String? textPosition,
    $core.String? characterPosition,
  }) {
    final result = Scene._();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (background != null) result.background = background;
    if (character != null) result.character = character;
    if (texts != null) result.texts.addAll(texts);
    if (choices != null) result.choices.addAll(choices);
    if (condition != null) result.condition = condition;
    if (textPosition != null) result.textPosition = textPosition;
    if (characterPosition != null) result.characterPosition = characterPosition;
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
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'background')
    ..aOS(4, _omitFieldNames ? '' : 'character')
    ..pPS(5, _omitFieldNames ? '' : 'texts')
    ..pPM<$0.Choice>(6, _omitFieldNames ? '' : 'choices',
        subBuilder: $0.Choice.$_createMessage)
    ..aOS(7, _omitFieldNames ? '' : 'condition')
    ..aOS(8, _omitFieldNames ? '' : 'textPosition')
    ..aOS(9, _omitFieldNames ? '' : 'characterPosition')
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
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get background => $_getSZ(2);
  @$pb.TagNumber(3)
  set background($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBackground() => $_has(2);
  @$pb.TagNumber(3)
  void clearBackground() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get character => $_getSZ(3);
  @$pb.TagNumber(4)
  set character($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCharacter() => $_has(3);
  @$pb.TagNumber(4)
  void clearCharacter() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get texts => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<$0.Choice> get choices => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get condition => $_getSZ(6);
  @$pb.TagNumber(7)
  set condition($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCondition() => $_has(6);
  @$pb.TagNumber(7)
  void clearCondition() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get textPosition => $_getSZ(7);
  @$pb.TagNumber(8)
  set textPosition($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTextPosition() => $_has(7);
  @$pb.TagNumber(8)
  void clearTextPosition() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get characterPosition => $_getSZ(8);
  @$pb.TagNumber(9)
  set characterPosition($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCharacterPosition() => $_has(8);
  @$pb.TagNumber(9)
  void clearCharacterPosition() => $_clearField(9);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
