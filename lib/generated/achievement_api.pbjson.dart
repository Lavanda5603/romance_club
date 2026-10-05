// This is a generated file - do not edit.
//
// Generated from achievement_api.proto.

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

@$core.Deprecated('Use achievementDescriptor instead')
const Achievement$json = {
  '1': 'Achievement',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'unlocked_at', '3': 2, '4': 1, '5': 9, '10': 'unlockedAt'},
  ],
};

/// Descriptor for `Achievement`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List achievementDescriptor = $convert.base64Decode(
    'CgtBY2hpZXZlbWVudBISCgRuYW1lGAEgASgJUgRuYW1lEh8KC3VubG9ja2VkX2F0GAIgASgJUg'
    'p1bmxvY2tlZEF0');

@$core.Deprecated('Use getAchievementsRequestDescriptor instead')
const GetAchievementsRequest$json = {
  '1': 'GetAchievementsRequest',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
  ],
};

/// Descriptor for `GetAchievementsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAchievementsRequestDescriptor =
    $convert.base64Decode(
        'ChZHZXRBY2hpZXZlbWVudHNSZXF1ZXN0EhsKCXBsYXllcl9pZBgBIAEoCVIIcGxheWVySWQ=');

@$core.Deprecated('Use getAchievementsResponseDescriptor instead')
const GetAchievementsResponse$json = {
  '1': 'GetAchievementsResponse',
  '2': [
    {
      '1': 'achievements',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.romance_club.Achievement',
      '10': 'achievements'
    },
  ],
};

/// Descriptor for `GetAchievementsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAchievementsResponseDescriptor =
    $convert.base64Decode(
        'ChdHZXRBY2hpZXZlbWVudHNSZXNwb25zZRI9CgxhY2hpZXZlbWVudHMYASADKAsyGS5yb21hbm'
        'NlX2NsdWIuQWNoaWV2ZW1lbnRSDGFjaGlldmVtZW50cw==');

@$core.Deprecated('Use unlockAchievementRequestDescriptor instead')
const UnlockAchievementRequest$json = {
  '1': 'UnlockAchievementRequest',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `UnlockAchievementRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unlockAchievementRequestDescriptor =
    $convert.base64Decode(
        'ChhVbmxvY2tBY2hpZXZlbWVudFJlcXVlc3QSGwoJcGxheWVyX2lkGAEgASgJUghwbGF5ZXJJZB'
        'ISCgRuYW1lGAIgASgJUgRuYW1l');

@$core.Deprecated('Use unlockAchievementResponseDescriptor instead')
const UnlockAchievementResponse$json = {
  '1': 'UnlockAchievementResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `UnlockAchievementResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unlockAchievementResponseDescriptor =
    $convert.base64Decode(
        'ChlVbmxvY2tBY2hpZXZlbWVudFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGA'
        'oHbWVzc2FnZRgCIAEoCVIHbWVzc2FnZQ==');
