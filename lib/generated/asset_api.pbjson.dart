// This is a generated file - do not edit.
//
// Generated from asset_api.proto.

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

@$core.Deprecated('Use assetDescriptor instead')
const Asset$json = {
  '1': 'Asset',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'emotion', '3': 4, '4': 1, '5': 9, '10': 'emotion'},
    {'1': 'url', '3': 5, '4': 1, '5': 9, '10': 'url'},
    {'1': 'display_name', '3': 6, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'episode_id', '3': 7, '4': 1, '5': 9, '10': 'episodeId'},
    {'1': 'file_data', '3': 8, '4': 1, '5': 12, '10': 'fileData'},
  ],
};

/// Descriptor for `Asset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List assetDescriptor = $convert.base64Decode(
    'CgVBc3NldBIOCgJpZBgBIAEoCVICaWQSEgoEdHlwZRgCIAEoCVIEdHlwZRISCgRuYW1lGAMgAS'
    'gJUgRuYW1lEhgKB2Vtb3Rpb24YBCABKAlSB2Vtb3Rpb24SEAoDdXJsGAUgASgJUgN1cmwSIQoM'
    'ZGlzcGxheV9uYW1lGAYgASgJUgtkaXNwbGF5TmFtZRIdCgplcGlzb2RlX2lkGAcgASgJUgllcG'
    'lzb2RlSWQSGwoJZmlsZV9kYXRhGAggASgMUghmaWxlRGF0YQ==');

@$core.Deprecated('Use getAssetsRequestDescriptor instead')
const GetAssetsRequest$json = {
  '1': 'GetAssetsRequest',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'episode_id', '3': 2, '4': 1, '5': 9, '10': 'episodeId'},
  ],
};

/// Descriptor for `GetAssetsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAssetsRequestDescriptor = $convert.base64Decode(
    'ChBHZXRBc3NldHNSZXF1ZXN0EhIKBHR5cGUYASABKAlSBHR5cGUSHQoKZXBpc29kZV9pZBgCIA'
    'EoCVIJZXBpc29kZUlk');

@$core.Deprecated('Use getAssetsResponseDescriptor instead')
const GetAssetsResponse$json = {
  '1': 'GetAssetsResponse',
  '2': [
    {
      '1': 'assets',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.romance_club.Asset',
      '10': 'assets'
    },
  ],
};

/// Descriptor for `GetAssetsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAssetsResponseDescriptor = $convert.base64Decode(
    'ChFHZXRBc3NldHNSZXNwb25zZRIrCgZhc3NldHMYASADKAsyEy5yb21hbmNlX2NsdWIuQXNzZX'
    'RSBmFzc2V0cw==');

@$core.Deprecated('Use uploadAssetRequestDescriptor instead')
const UploadAssetRequest$json = {
  '1': 'UploadAssetRequest',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'emotion', '3': 3, '4': 1, '5': 9, '10': 'emotion'},
    {'1': 'display_name', '3': 4, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'episode_id', '3': 5, '4': 1, '5': 9, '10': 'episodeId'},
    {'1': 'file_data', '3': 6, '4': 1, '5': 12, '10': 'fileData'},
    {'1': 'file_name', '3': 7, '4': 1, '5': 9, '10': 'fileName'},
  ],
};

/// Descriptor for `UploadAssetRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadAssetRequestDescriptor = $convert.base64Decode(
    'ChJVcGxvYWRBc3NldFJlcXVlc3QSEgoEdHlwZRgBIAEoCVIEdHlwZRISCgRuYW1lGAIgASgJUg'
    'RuYW1lEhgKB2Vtb3Rpb24YAyABKAlSB2Vtb3Rpb24SIQoMZGlzcGxheV9uYW1lGAQgASgJUgtk'
    'aXNwbGF5TmFtZRIdCgplcGlzb2RlX2lkGAUgASgJUgllcGlzb2RlSWQSGwoJZmlsZV9kYXRhGA'
    'YgASgMUghmaWxlRGF0YRIbCglmaWxlX25hbWUYByABKAlSCGZpbGVOYW1l');

@$core.Deprecated('Use uploadAssetResponseDescriptor instead')
const UploadAssetResponse$json = {
  '1': 'UploadAssetResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'asset',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.romance_club.Asset',
      '10': 'asset'
    },
  ],
};

/// Descriptor for `UploadAssetResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadAssetResponseDescriptor = $convert.base64Decode(
    'ChNVcGxvYWRBc3NldFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2'
    'FnZRgCIAEoCVIHbWVzc2FnZRIpCgVhc3NldBgDIAEoCzITLnJvbWFuY2VfY2x1Yi5Bc3NldFIF'
    'YXNzZXQ=');

@$core.Deprecated('Use deleteAssetRequestDescriptor instead')
const DeleteAssetRequest$json = {
  '1': 'DeleteAssetRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteAssetRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteAssetRequestDescriptor =
    $convert.base64Decode('ChJEZWxldGVBc3NldFJlcXVlc3QSDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use deleteAssetResponseDescriptor instead')
const DeleteAssetResponse$json = {
  '1': 'DeleteAssetResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `DeleteAssetResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteAssetResponseDescriptor = $convert.base64Decode(
    'ChNEZWxldGVBc3NldFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2'
    'FnZRgCIAEoCVIHbWVzc2FnZQ==');
