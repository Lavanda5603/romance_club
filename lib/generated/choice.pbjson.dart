// This is a generated file - do not edit.
//
// Generated from choice.proto.

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

@$core.Deprecated('Use choiceDescriptor instead')
const Choice$json = {
  '1': 'Choice',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {
      '1': 'actions',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.romance_club.Action',
      '10': 'actions'
    },
  ],
};

/// Descriptor for `Choice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List choiceDescriptor = $convert.base64Decode(
    'CgZDaG9pY2USEgoEdGV4dBgBIAEoCVIEdGV4dBIuCgdhY3Rpb25zGAIgAygLMhQucm9tYW5jZV'
    '9jbHViLkFjdGlvblIHYWN0aW9ucw==');
