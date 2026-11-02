// This is a generated file - do not edit.
//
// Generated from novel_api.proto.

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

@$core.Deprecated('Use novelDescriptor instead')
const Novel$json = {
  '1': 'Novel',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'cover_id', '3': 3, '4': 1, '5': 9, '10': 'coverId'},
    {'1': 'background_id', '3': 4, '4': 1, '5': 9, '10': 'backgroundId'},
    {'1': 'music_id', '3': 5, '4': 1, '5': 9, '10': 'musicId'},
    {'1': 'click_id', '3': 6, '4': 1, '5': 9, '10': 'clickId'},
    {'1': 'config_json', '3': 7, '4': 1, '5': 9, '10': 'configJson'},
    {'1': 'revision', '3': 8, '4': 1, '5': 5, '10': 'revision'},
  ],
};

/// Descriptor for `Novel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List novelDescriptor = $convert.base64Decode(
    'CgVOb3ZlbBIOCgJpZBgBIAEoCVICaWQSFAoFdGl0bGUYAiABKAlSBXRpdGxlEhkKCGNvdmVyX2'
    'lkGAMgASgJUgdjb3ZlcklkEiMKDWJhY2tncm91bmRfaWQYBCABKAlSDGJhY2tncm91bmRJZBIZ'
    'CghtdXNpY19pZBgFIAEoCVIHbXVzaWNJZBIZCghjbGlja19pZBgGIAEoCVIHY2xpY2tJZBIfCg'
    'tjb25maWdfanNvbhgHIAEoCVIKY29uZmlnSnNvbhIaCghyZXZpc2lvbhgIIAEoBVIIcmV2aXNp'
    'b24=');

@$core.Deprecated('Use novelRequestDescriptor instead')
const NovelRequest$json = {
  '1': 'NovelRequest',
  '2': [
    {'1': 'novel_id', '3': 1, '4': 1, '5': 9, '10': 'novelId'},
  ],
};

/// Descriptor for `NovelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List novelRequestDescriptor = $convert
    .base64Decode('CgxOb3ZlbFJlcXVlc3QSGQoIbm92ZWxfaWQYASABKAlSB25vdmVsSWQ=');

@$core.Deprecated('Use listNovelsRequestDescriptor instead')
const ListNovelsRequest$json = {
  '1': 'ListNovelsRequest',
};

/// Descriptor for `ListNovelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listNovelsRequestDescriptor =
    $convert.base64Decode('ChFMaXN0Tm92ZWxzUmVxdWVzdA==');

@$core.Deprecated('Use listNovelsResponseDescriptor instead')
const ListNovelsResponse$json = {
  '1': 'ListNovelsResponse',
  '2': [
    {
      '1': 'novels',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.romance_club.Novel',
      '10': 'novels'
    },
  ],
};

/// Descriptor for `ListNovelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listNovelsResponseDescriptor = $convert.base64Decode(
    'ChJMaXN0Tm92ZWxzUmVzcG9uc2USKwoGbm92ZWxzGAEgAygLMhMucm9tYW5jZV9jbHViLk5vdm'
    'VsUgZub3ZlbHM=');

@$core.Deprecated('Use createNovelEpisodeRequestDescriptor instead')
const CreateNovelEpisodeRequest$json = {
  '1': 'CreateNovelEpisodeRequest',
  '2': [
    {'1': 'novel_id', '3': 1, '4': 1, '5': 9, '10': 'novelId'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
  ],
};

/// Descriptor for `CreateNovelEpisodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createNovelEpisodeRequestDescriptor =
    $convert.base64Decode(
        'ChlDcmVhdGVOb3ZlbEVwaXNvZGVSZXF1ZXN0EhkKCG5vdmVsX2lkGAEgASgJUgdub3ZlbElkEh'
        'QKBXRpdGxlGAIgASgJUgV0aXRsZQ==');

@$core.Deprecated('Use uploadNovelAudioRequestDescriptor instead')
const UploadNovelAudioRequest$json = {
  '1': 'UploadNovelAudioRequest',
  '2': [
    {'1': 'novel_id', '3': 1, '4': 1, '5': 9, '10': 'novelId'},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'data', '3': 3, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `UploadNovelAudioRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadNovelAudioRequestDescriptor =
    $convert.base64Decode(
        'ChdVcGxvYWROb3ZlbEF1ZGlvUmVxdWVzdBIZCghub3ZlbF9pZBgBIAEoCVIHbm92ZWxJZBISCg'
        'RraW5kGAIgASgJUgRraW5kEhIKBGRhdGEYAyABKAxSBGRhdGE=');

@$core.Deprecated('Use novelAudioRequestDescriptor instead')
const NovelAudioRequest$json = {
  '1': 'NovelAudioRequest',
  '2': [
    {'1': 'novel_id', '3': 1, '4': 1, '5': 9, '10': 'novelId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `NovelAudioRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List novelAudioRequestDescriptor = $convert.base64Decode(
    'ChFOb3ZlbEF1ZGlvUmVxdWVzdBIZCghub3ZlbF9pZBgBIAEoCVIHbm92ZWxJZBIOCgJpZBgCIA'
    'EoCVICaWQ=');

@$core.Deprecated('Use novelAudioDescriptor instead')
const NovelAudio$json = {
  '1': 'NovelAudio',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
    {'1': 'hash', '3': 3, '4': 1, '5': 9, '10': 'hash'},
  ],
};

/// Descriptor for `NovelAudio`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List novelAudioDescriptor = $convert.base64Decode(
    'CgpOb3ZlbEF1ZGlvEg4KAmlkGAEgASgJUgJpZBISCgRkYXRhGAIgASgMUgRkYXRhEhIKBGhhc2'
    'gYAyABKAlSBGhhc2g=');