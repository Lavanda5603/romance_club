// This is a generated file - do not edit.
//
// Generated from scene.proto.

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

@$core.Deprecated('Use sceneDescriptor instead')
const Scene$json = {
  '1': 'Scene',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'background', '3': 3, '4': 1, '5': 9, '10': 'background'},
    {'1': 'character', '3': 4, '4': 1, '5': 9, '10': 'character'},
    {'1': 'texts', '3': 5, '4': 3, '5': 9, '10': 'texts'},
    {
      '1': 'choices',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.romance_club.Choice',
      '10': 'choices'
    },
    {'1': 'condition', '3': 7, '4': 1, '5': 9, '10': 'condition'},
    {'1': 'text_position', '3': 8, '4': 1, '5': 9, '10': 'textPosition'},
    {
      '1': 'character_position',
      '3': 9,
      '4': 1,
      '5': 9,
      '10': 'characterPosition'
    },
    {'1': 'scene_key', '3': 10, '4': 1, '5': 9, '10': 'sceneKey'},
    {
      '1': 'character_emotion',
      '3': 11,
      '4': 1,
      '5': 9,
      '10': 'characterEmotion'
    },
  ],
};

/// Descriptor for `Scene`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sceneDescriptor = $convert.base64Decode(
    'CgVTY2VuZRIOCgJpZBgBIAEoBVICaWQSFAoFdGl0bGUYAiABKAlSBXRpdGxlEh4KCmJhY2tncm'
    '91bmQYAyABKAlSCmJhY2tncm91bmQSHAoJY2hhcmFjdGVyGAQgASgJUgljaGFyYWN0ZXISFAoF'
    'dGV4dHMYBSADKAlSBXRleHRzEi4KB2Nob2ljZXMYBiADKAsyFC5yb21hbmNlX2NsdWIuQ2hvaW'
    'NlUgdjaG9pY2VzEhwKCWNvbmRpdGlvbhgHIAEoCVIJY29uZGl0aW9uEiMKDXRleHRfcG9zaXRp'
    'b24YCCABKAlSDHRleHRQb3NpdGlvbhItChJjaGFyYWN0ZXJfcG9zaXRpb24YCSABKAlSEWNoYX'
    'JhY3RlclBvc2l0aW9uEhsKCXNjZW5lX2tleRgKIAEoCVIIc2NlbmVLZXkSKwoRY2hhcmFjdGVy'
    'X2Vtb3Rpb24YCyABKAlSEGNoYXJhY3RlckVtb3Rpb24=');
