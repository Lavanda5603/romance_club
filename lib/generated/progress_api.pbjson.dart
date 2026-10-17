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

import 'progress.pbjson.dart' as $0;

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
    {
      '1': 'expected_revision',
      '3': 6,
      '4': 1,
      '5': 5,
      '10': 'expectedRevision'
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
    'UmVxdWVzdC5Db3VudGVyc0VudHJ5Ughjb3VudGVycxIrChFleHBlY3RlZF9yZXZpc2lvbhgGIA'
    'EoBVIQZXhwZWN0ZWRSZXZpc2lvbho4CgpGbGFnc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQK'
    'BXZhbHVlGAIgASgIUgV2YWx1ZToCOAEaOwoNQ291bnRlcnNFbnRyeRIQCgNrZXkYASABKAlSA2'
    'tleRIUCgV2YWx1ZRgCIAEoBVIFdmFsdWU6AjgB');

@$core.Deprecated('Use saveProgressResponseDescriptor instead')
const SaveProgressResponse$json = {
  '1': 'SaveProgressResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'revision', '3': 3, '4': 1, '5': 5, '10': 'revision'},
  ],
};

/// Descriptor for `SaveProgressResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveProgressResponseDescriptor = $convert.base64Decode(
    'ChRTYXZlUHJvZ3Jlc3NSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3'
    'NhZ2UYAiABKAlSB21lc3NhZ2USGgoIcmV2aXNpb24YAyABKAVSCHJldmlzaW9u');

@$core.Deprecated('Use resetProgressRequestDescriptor instead')
const ResetProgressRequest$json = {
  '1': 'ResetProgressRequest',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
  ],
};

/// Descriptor for `ResetProgressRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetProgressRequestDescriptor =
    $convert.base64Decode(
        'ChRSZXNldFByb2dyZXNzUmVxdWVzdBIbCglwbGF5ZXJfaWQYASABKAlSCHBsYXllcklk');

@$core.Deprecated('Use resetProgressResponseDescriptor instead')
const ResetProgressResponse$json = {
  '1': 'ResetProgressResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ResetProgressResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetProgressResponseDescriptor = $convert.base64Decode(
    'ChVSZXNldFByb2dyZXNzUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZX'
    'NzYWdlGAIgASgJUgdtZXNzYWdl');

const $core.Map<$core.String, $core.dynamic> ProgressApiServiceBase$json = {
  '1': 'ProgressApi',
  '2': [
    {
      '1': 'GetProgress',
      '2': '.romance_club.GetProgressRequest',
      '3': '.romance_club.Progress'
    },
    {
      '1': 'SaveProgress',
      '2': '.romance_club.SaveProgressRequest',
      '3': '.romance_club.SaveProgressResponse'
    },
    {
      '1': 'ResetProgress',
      '2': '.romance_club.ResetProgressRequest',
      '3': '.romance_club.ResetProgressResponse'
    },
  ],
};

@$core.Deprecated('Use progressApiServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    ProgressApiServiceBase$messageJson = {
  '.romance_club.GetProgressRequest': GetProgressRequest$json,
  '.romance_club.Progress': $0.Progress$json,
  '.romance_club.Progress.FlagsEntry': $0.Progress_FlagsEntry$json,
  '.romance_club.Progress.CountersEntry': $0.Progress_CountersEntry$json,
  '.romance_club.SaveProgressRequest': SaveProgressRequest$json,
  '.romance_club.SaveProgressRequest.FlagsEntry':
      SaveProgressRequest_FlagsEntry$json,
  '.romance_club.SaveProgressRequest.CountersEntry':
      SaveProgressRequest_CountersEntry$json,
  '.romance_club.SaveProgressResponse': SaveProgressResponse$json,
  '.romance_club.ResetProgressRequest': ResetProgressRequest$json,
  '.romance_club.ResetProgressResponse': ResetProgressResponse$json,
};

/// Descriptor for `ProgressApi`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List progressApiServiceDescriptor = $convert.base64Decode(
    'CgtQcm9ncmVzc0FwaRJHCgtHZXRQcm9ncmVzcxIgLnJvbWFuY2VfY2x1Yi5HZXRQcm9ncmVzc1'
    'JlcXVlc3QaFi5yb21hbmNlX2NsdWIuUHJvZ3Jlc3MSVQoMU2F2ZVByb2dyZXNzEiEucm9tYW5j'
    'ZV9jbHViLlNhdmVQcm9ncmVzc1JlcXVlc3QaIi5yb21hbmNlX2NsdWIuU2F2ZVByb2dyZXNzUm'
    'VzcG9uc2USWAoNUmVzZXRQcm9ncmVzcxIiLnJvbWFuY2VfY2x1Yi5SZXNldFByb2dyZXNzUmVx'
    'dWVzdBojLnJvbWFuY2VfY2x1Yi5SZXNldFByb2dyZXNzUmVzcG9uc2U=');
