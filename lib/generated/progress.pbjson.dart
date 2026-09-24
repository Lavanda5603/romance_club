// This is a generated file - do not edit.
//
// Generated from progress.proto.

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

@$core.Deprecated('Use progressDescriptor instead')
const Progress$json = {
  '1': 'Progress',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'player_id', '3': 2, '4': 1, '5': 5, '10': 'playerId'},
    {'1': 'episode_id', '3': 3, '4': 1, '5': 5, '10': 'episodeId'},
    {'1': 'scene_id', '3': 4, '4': 1, '5': 5, '10': 'sceneId'},
    {
      '1': 'flags',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.romance_club.Progress.FlagsEntry',
      '10': 'flags'
    },
    {
      '1': 'counters',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.romance_club.Progress.CountersEntry',
      '10': 'counters'
    },
    {'1': 'updated_at', '3': 7, '4': 1, '5': 9, '10': 'updatedAt'},
  ],
  '3': [Progress_FlagsEntry$json, Progress_CountersEntry$json],
};

@$core.Deprecated('Use progressDescriptor instead')
const Progress_FlagsEntry$json = {
  '1': 'FlagsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use progressDescriptor instead')
const Progress_CountersEntry$json = {
  '1': 'CountersEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 5, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `Progress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List progressDescriptor = $convert.base64Decode(
    'CghQcm9ncmVzcxIOCgJpZBgBIAEoBVICaWQSGwoJcGxheWVyX2lkGAIgASgFUghwbGF5ZXJJZB'
    'IdCgplcGlzb2RlX2lkGAMgASgFUgllcGlzb2RlSWQSGQoIc2NlbmVfaWQYBCABKAVSB3NjZW5l'
    'SWQSNwoFZmxhZ3MYBSADKAsyIS5yb21hbmNlX2NsdWIuUHJvZ3Jlc3MuRmxhZ3NFbnRyeVIFZm'
    'xhZ3MSQAoIY291bnRlcnMYBiADKAsyJC5yb21hbmNlX2NsdWIuUHJvZ3Jlc3MuQ291bnRlcnNF'
    'bnRyeVIIY291bnRlcnMSHQoKdXBkYXRlZF9hdBgHIAEoCVIJdXBkYXRlZEF0GjgKCkZsYWdzRW'
    '50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAhSBXZhbHVlOgI4ARo7Cg1Db3Vu'
    'dGVyc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgFUgV2YWx1ZToCOAE=');
