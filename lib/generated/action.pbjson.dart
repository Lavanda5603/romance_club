// This is a generated file - do not edit.
//
// Generated from action.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use actionDescriptor instead')
const Action$json = {
  '1': 'Action',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'scene_id', '3': 2, '4': 1, '5': 5, '10': 'sceneId'},
    {'1': 'flag_name', '3': 3, '4': 1, '5': 9, '10': 'flagName'},
    {'1': 'flag_value', '3': 4, '4': 1, '5': 8, '10': 'flagValue'},
    {'1': 'counter_name', '3': 5, '4': 1, '5': 9, '10': 'counterName'},
    {'1': 'counter_value', '3': 6, '4': 1, '5': 5, '10': 'counterValue'},
    {'1': 'sound_path', '3': 7, '4': 1, '5': 9, '10': 'soundPath'},
    {'1': 'image_path', '3': 8, '4': 1, '5': 9, '10': 'imagePath'},
  ],
};

/// Descriptor for `Action`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List actionDescriptor = $convert.base64Decode(
    'CgZBY3Rpb24SEgoEdHlwZRgBIAEoCVIEdHlwZRIZCghzY2VuZV9pZBgCIAEoBVIHc2NlbmVJZB'
    'IbCglmbGFnX25hbWUYAyABKAlSCGZsYWdOYW1lEh0KCmZsYWdfdmFsdWUYBCABKAhSCWZsYWdW'
    'YWx1ZRIhCgxjb3VudGVyX25hbWUYBSABKAlSC2NvdW50ZXJOYW1lEiMKDWNvdW50ZXJfdmFsdW'
    'UYBiABKAVSDGNvdW50ZXJWYWx1ZRIdCgpzb3VuZF9wYXRoGAcgASgJUglzb3VuZFBhdGgSHQoK'
    'aW1hZ2VfcGF0aBgIIAEoCVIJaW1hZ2VQYXRo');
