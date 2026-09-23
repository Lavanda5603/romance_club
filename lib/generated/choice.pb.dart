// This is a generated file - do not edit.
//
// Generated from choice.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'action.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Выбор (вариант, видит игрок)
class Choice extends $pb.GeneratedMessage {
  factory Choice({
    $core.String? text,
    $core.Iterable<$0.Action>? actions,
  }) {
    final result = Choice._();
    if (text != null) result.text = text;
    if (actions != null) result.actions.addAll(actions);
    return result;
  }

  Choice._();

  factory Choice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Choice()..mergeFromBuffer(data, registry);
  factory Choice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Choice()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Choice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: Choice.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..pPM<$0.Action>(2, _omitFieldNames ? '' : 'actions',
        subBuilder: $0.Action.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Choice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Choice copyWith(void Function(Choice) updates) =>
      super.copyWith((message) => updates(message as Choice)) as Choice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Choice() / Choice.new instead')
  static Choice create() => Choice._();
  static $pb.GeneratedMessage $_createMessage() => Choice._();
  @$core.override
  Choice createEmptyInstance() => Choice._();
  @$core.pragma('dart2js:noInline')
  static Choice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Choice>(Choice.$_createMessage);
  static Choice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$0.Action> get actions => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
