// This is a generated file - do not edit.
//
// Generated from progress_api.proto.

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

@$core.Deprecated('Use getProgressRequestDescriptor instead')
const GetProgressRequest$json = {
  '1': 'GetProgressRequest',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'episode_id', '3': 2, '4': 1, '5': 5, '10': 'episodeId'},
  ],
};

/// Descriptor for `GetProgressRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getProgressRequestDescriptor = $convert.base64Decode(
    'ChJHZXRQcm9ncmVzc1JlcXVlc3QSGwoJcGxheWVyX2lkGAEgASgJUghwbGF5ZXJJZBIdCgplcG'
    'lzb2RlX2lkGAIgASgFUgllcGlzb2RlSWQ=');

@$core.Deprecated('Use saveProgressRequestDescriptor instead')
const SaveProgressRequest$json = {
  '1': 'SaveProgressRequest',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'episode_id', '3': 2, '4': 1, '5': 5, '10': 'episodeId'},
    {'1': 'scene_id', '3': 3, '4': 1, '5': 9, '10': 'sceneId'},
    {
      '1': 'flags',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.romance_club.SaveProgressRequest.FlagsEntry',
      '10': 'flags'
    },
    {
      '1': 'counters',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.romance_club.SaveProgressRequest.CountersEntry',
      '10': 'counters'
    },
  ],
  '3': [
    SaveProgressRequest_FlagsEntry$json,
    SaveProgressRequest_CountersEntry$json
  ],
};

@$core.Deprecated('Use saveProgressRequestDescriptor instead')
const SaveProgressRequest_FlagsEntry$json = {
  '1': 'FlagsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use saveProgressRequestDescriptor instead')
const SaveProgressRequest_CountersEntry$json = {
  '1': 'CountersEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 5, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `SaveProgressRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveProgressRequestDescriptor = $convert.base64Decode(
    'ChNTYXZlUHJvZ3Jlc3NSZXF1ZXN0EhsKCXBsYXllcl9pZBgBIAEoCVIIcGxheWVySWQSHQoKZX'
    'Bpc29kZV9pZBgCIAEoBVIJZXBpc29kZUlkEhkKCHNjZW5lX2lkGAMgASgJUgdzY2VuZUlkEkIK'
    'BWZsYWdzGAQgAygLMiwucm9tYW5jZV9jbHViLlNhdmVQcm9ncmVzc1JlcXVlc3QuRmxhZ3NFbn'
    'RyeVIFZmxhZ3MSSwoIY291bnRlcnMYBSADKAsyLy5yb21hbmNlX2NsdWIuU2F2ZVByb2dyZXNz'
    'UmVxdWVzdC5Db3VudGVyc0VudHJ5Ughjb3VudGVycxo4CgpGbGFnc0VudHJ5EhAKA2tleRgBIA'
    'EoCVIDa2V5EhQKBXZhbHVlGAIgASgIUgV2YWx1ZToCOAEaOwoNQ291bnRlcnNFbnRyeRIQCgNr'
    'ZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoBVIFdmFsdWU6AjgB');

@$core.Deprecated('Use saveProgressResponseDescriptor instead')
const SaveProgressResponse$json = {
  '1': 'SaveProgressResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `SaveProgressResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveProgressResponseDescriptor = $convert.base64Decode(
    'ChRTYXZlUHJvZ3Jlc3NSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3'
    'NhZ2UYAiABKAlSB21lc3NhZ2U=');
