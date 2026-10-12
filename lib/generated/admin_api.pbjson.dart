// This is a generated file - do not edit.
//
// Generated from admin_api.proto.

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

@$core.Deprecated('Use adminDeleteAssetRequestDescriptor instead')
const AdminDeleteAssetRequest$json = {
  '1': 'AdminDeleteAssetRequest',
  '2': [
    {'1': 'asset_id', '3': 1, '4': 1, '5': 9, '10': 'assetId'},
  ],
};

/// Descriptor for `AdminDeleteAssetRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminDeleteAssetRequestDescriptor =
    $convert.base64Decode(
        'ChdBZG1pbkRlbGV0ZUFzc2V0UmVxdWVzdBIZCghhc3NldF9pZBgBIAEoCVIHYXNzZXRJZA==');

@$core.Deprecated('Use adminDeleteEpisodeRequestDescriptor instead')
const AdminDeleteEpisodeRequest$json = {
  '1': 'AdminDeleteEpisodeRequest',
  '2': [
    {'1': 'episode_id', '3': 1, '4': 1, '5': 5, '10': 'episodeId'},
  ],
};

/// Descriptor for `AdminDeleteEpisodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminDeleteEpisodeRequestDescriptor =
    $convert.base64Decode(
        'ChlBZG1pbkRlbGV0ZUVwaXNvZGVSZXF1ZXN0Eh0KCmVwaXNvZGVfaWQYASABKAVSCWVwaXNvZG'
        'VJZA==');

@$core.Deprecated('Use adminResponseDescriptor instead')
const AdminResponse$json = {
  '1': 'AdminResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `AdminResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminResponseDescriptor = $convert.base64Decode(
    'Cg1BZG1pblJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2FnZRgCIA'
    'EoCVIHbWVzc2FnZQ==');
