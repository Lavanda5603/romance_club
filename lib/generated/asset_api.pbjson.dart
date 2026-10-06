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
  ],
};

/// Descriptor for `Asset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List assetDescriptor = $convert.base64Decode(
    'CgVBc3NldBIOCgJpZBgBIAEoCVICaWQSEgoEdHlwZRgCIAEoCVIEdHlwZRISCgRuYW1lGAMgAS'
    'gJUgRuYW1lEhgKB2Vtb3Rpb24YBCABKAlSB2Vtb3Rpb24SEAoDdXJsGAUgASgJUgN1cmwSIQoM'
    'ZGlzcGxheV9uYW1lGAYgASgJUgtkaXNwbGF5TmFtZRIdCgplcGlzb2RlX2lkGAcgASgJUgllcG'
    'lzb2RlSWQ=');

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
