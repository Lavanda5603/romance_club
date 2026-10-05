// This is a generated file - do not edit.
//
// Generated from shop_api.proto.

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

@$core.Deprecated('Use purchaseDescriptor instead')
const Purchase$json = {
  '1': 'Purchase',
  '2': [
    {'1': 'item_id', '3': 1, '4': 1, '5': 9, '10': 'itemId'},
    {'1': 'item_type', '3': 2, '4': 1, '5': 9, '10': 'itemType'},
    {'1': 'purchased_at', '3': 3, '4': 1, '5': 9, '10': 'purchasedAt'},
  ],
};

/// Descriptor for `Purchase`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List purchaseDescriptor = $convert.base64Decode(
    'CghQdXJjaGFzZRIXCgdpdGVtX2lkGAEgASgJUgZpdGVtSWQSGwoJaXRlbV90eXBlGAIgASgJUg'
    'hpdGVtVHlwZRIhCgxwdXJjaGFzZWRfYXQYAyABKAlSC3B1cmNoYXNlZEF0');

@$core.Deprecated('Use currencyDescriptor instead')
const Currency$json = {
  '1': 'Currency',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'diamonds', '3': 2, '4': 1, '5': 5, '10': 'diamonds'},
  ],
};

/// Descriptor for `Currency`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List currencyDescriptor = $convert.base64Decode(
    'CghDdXJyZW5jeRIbCglwbGF5ZXJfaWQYASABKAlSCHBsYXllcklkEhoKCGRpYW1vbmRzGAIgAS'
    'gFUghkaWFtb25kcw==');

@$core.Deprecated('Use getPurchasesRequestDescriptor instead')
const GetPurchasesRequest$json = {
  '1': 'GetPurchasesRequest',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
  ],
};

/// Descriptor for `GetPurchasesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPurchasesRequestDescriptor =
    $convert.base64Decode(
        'ChNHZXRQdXJjaGFzZXNSZXF1ZXN0EhsKCXBsYXllcl9pZBgBIAEoCVIIcGxheWVySWQ=');

@$core.Deprecated('Use getPurchasesResponseDescriptor instead')
const GetPurchasesResponse$json = {
  '1': 'GetPurchasesResponse',
  '2': [
    {
      '1': 'purchases',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.romance_club.Purchase',
      '10': 'purchases'
    },
  ],
};

/// Descriptor for `GetPurchasesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPurchasesResponseDescriptor = $convert.base64Decode(
    'ChRHZXRQdXJjaGFzZXNSZXNwb25zZRI0CglwdXJjaGFzZXMYASADKAsyFi5yb21hbmNlX2NsdW'
    'IuUHVyY2hhc2VSCXB1cmNoYXNlcw==');

@$core.Deprecated('Use purchaseRequestDescriptor instead')
const PurchaseRequest$json = {
  '1': 'PurchaseRequest',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'item_id', '3': 2, '4': 1, '5': 9, '10': 'itemId'},
    {'1': 'item_type', '3': 3, '4': 1, '5': 9, '10': 'itemType'},
  ],
};

/// Descriptor for `PurchaseRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List purchaseRequestDescriptor = $convert.base64Decode(
    'Cg9QdXJjaGFzZVJlcXVlc3QSGwoJcGxheWVyX2lkGAEgASgJUghwbGF5ZXJJZBIXCgdpdGVtX2'
    'lkGAIgASgJUgZpdGVtSWQSGwoJaXRlbV90eXBlGAMgASgJUghpdGVtVHlwZQ==');

@$core.Deprecated('Use purchaseResponseDescriptor instead')
const PurchaseResponse$json = {
  '1': 'PurchaseResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'currency',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.romance_club.Currency',
      '10': 'currency'
    },
  ],
};

/// Descriptor for `PurchaseResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List purchaseResponseDescriptor = $convert.base64Decode(
    'ChBQdXJjaGFzZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2FnZR'
    'gCIAEoCVIHbWVzc2FnZRIyCghjdXJyZW5jeRgDIAEoCzIWLnJvbWFuY2VfY2x1Yi5DdXJyZW5j'
    'eVIIY3VycmVuY3k=');

@$core.Deprecated('Use getCurrencyRequestDescriptor instead')
const GetCurrencyRequest$json = {
  '1': 'GetCurrencyRequest',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
  ],
};

/// Descriptor for `GetCurrencyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCurrencyRequestDescriptor =
    $convert.base64Decode(
        'ChJHZXRDdXJyZW5jeVJlcXVlc3QSGwoJcGxheWVyX2lkGAEgASgJUghwbGF5ZXJJZA==');
