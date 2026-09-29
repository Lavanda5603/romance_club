// This is a generated file - do not edit.
//
// Generated from settings.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Настройки игрока
class Settings extends $pb.GeneratedMessage {
  factory Settings({
    $core.double? musicVolume,
    $core.double? soundVolume,
  }) {
    final result = Settings._();
    if (musicVolume != null) result.musicVolume = musicVolume;
    if (soundVolume != null) result.soundVolume = soundVolume;
    return result;
  }

  Settings._();

  factory Settings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Settings()..mergeFromBuffer(data, registry);
  factory Settings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Settings()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Settings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'romance_club'),
      createEmptyInstance: Settings.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'musicVolume')
    ..aD(2, _omitFieldNames ? '' : 'soundVolume')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Settings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Settings copyWith(void Function(Settings) updates) =>
      super.copyWith((message) => updates(message as Settings)) as Settings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Settings() / Settings.new instead')
  static Settings create() => Settings._();
  static $pb.GeneratedMessage $_createMessage() => Settings._();
  @$core.override
  Settings createEmptyInstance() => Settings._();
  @$core.pragma('dart2js:noInline')
  static Settings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Settings>(Settings.$_createMessage);
  static Settings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get musicVolume => $_getN(0);
  @$pb.TagNumber(1)
  set musicVolume($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMusicVolume() => $_has(0);
  @$pb.TagNumber(1)
  void clearMusicVolume() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get soundVolume => $_getN(1);
  @$pb.TagNumber(2)
  set soundVolume($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSoundVolume() => $_has(1);
  @$pb.TagNumber(2)
  void clearSoundVolume() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
