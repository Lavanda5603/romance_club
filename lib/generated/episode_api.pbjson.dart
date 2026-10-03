// This is a generated file - do not edit.
//
// Generated from episode_api.proto.

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

@$core.Deprecated('Use getEpisodeRequestDescriptor instead')
const GetEpisodeRequest$json = {
  '1': 'GetEpisodeRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
  ],
};

/// Descriptor for `GetEpisodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEpisodeRequestDescriptor =
    $convert.base64Decode('ChFHZXRFcGlzb2RlUmVxdWVzdBIOCgJpZBgBIAEoBVICaWQ=');

@$core.Deprecated('Use getAllEpisodesRequestDescriptor instead')
const GetAllEpisodesRequest$json = {
  '1': 'GetAllEpisodesRequest',
};

/// Descriptor for `GetAllEpisodesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAllEpisodesRequestDescriptor =
    $convert.base64Decode('ChVHZXRBbGxFcGlzb2Rlc1JlcXVlc3Q=');

@$core.Deprecated('Use getAllEpisodesResponseDescriptor instead')
const GetAllEpisodesResponse$json = {
  '1': 'GetAllEpisodesResponse',
  '2': [
    {
      '1': 'episodes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.romance_club.Episode',
      '10': 'episodes'
    },
  ],
};

/// Descriptor for `GetAllEpisodesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAllEpisodesResponseDescriptor =
    $convert.base64Decode(
        'ChZHZXRBbGxFcGlzb2Rlc1Jlc3BvbnNlEjEKCGVwaXNvZGVzGAEgAygLMhUucm9tYW5jZV9jbH'
        'ViLkVwaXNvZGVSCGVwaXNvZGVz');

@$core.Deprecated('Use saveEpisodeRequestDescriptor instead')
const SaveEpisodeRequest$json = {
  '1': 'SaveEpisodeRequest',
  '2': [
    {
      '1': 'episode',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.romance_club.Episode',
      '10': 'episode'
    },
  ],
};

/// Descriptor for `SaveEpisodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveEpisodeRequestDescriptor = $convert.base64Decode(
    'ChJTYXZlRXBpc29kZVJlcXVlc3QSLwoHZXBpc29kZRgBIAEoCzIVLnJvbWFuY2VfY2x1Yi5FcG'
    'lzb2RlUgdlcGlzb2Rl');

@$core.Deprecated('Use saveEpisodeResponseDescriptor instead')
const SaveEpisodeResponse$json = {
  '1': 'SaveEpisodeResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `SaveEpisodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveEpisodeResponseDescriptor = $convert.base64Decode(
    'ChNTYXZlRXBpc29kZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2'
    'FnZRgCIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use deleteEpisodeRequestDescriptor instead')
const DeleteEpisodeRequest$json = {
  '1': 'DeleteEpisodeRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
  ],
};

/// Descriptor for `DeleteEpisodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteEpisodeRequestDescriptor = $convert
    .base64Decode('ChREZWxldGVFcGlzb2RlUmVxdWVzdBIOCgJpZBgBIAEoBVICaWQ=');

@$core.Deprecated('Use deleteEpisodeResponseDescriptor instead')
const DeleteEpisodeResponse$json = {
  '1': 'DeleteEpisodeResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `DeleteEpisodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteEpisodeResponseDescriptor = $convert.base64Decode(
    'ChVEZWxldGVFcGlzb2RlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZX'
    'NzYWdlGAIgASgJUgdtZXNzYWdl');
