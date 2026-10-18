import 'dart:typed_data';
import 'dart:convert';
import '../../domain/models/asset_model.dart';
import '../../domain/repositories/asset_repository.dart';
import '../services/asset_grpc_service.dart';
import '../../../generated/asset_api.pbgrpc.dart';
import 'asset_cache.dart';

class AssetRepositoryRemote implements AssetRepository {
  final AssetGrpcService _service;
  static final _pages = AssetCache<AssetPage>(maxBytes: 8 * 1024 * 1024, maxEntries: 16);
  static final _originals = AssetCache<AssetModel>(maxBytes: 24 * 1024 * 1024);
  static final _lookups = AssetCache<String>(maxBytes: 64 * 1024, maxEntries: 256);
  static int _generation = 0;
  AssetRepositoryRemote(this._service);

  // Сбрасываю все страницы типа, включая фильтры других эпизодов
  static void invalidateCache([String? type]) {
    _generation++;
    _pages.invalidate(type);
    _originals.invalidate(type);
    _lookups.invalidate(type);
  }

  @override
  Future<AssetPage> getAssetPage(String type, {String episodeId = '', String cursor = '', int limit = 24}) async {
    final scope = await _service.cacheScope();
    final key = '$scope|$type|$episodeId|$limit|$cursor';
    final cached = _pages.get(key);
    if (cached != null) return cached;
    final generation = _generation;
    final response = await _service.getAssetPage(type, episodeId: episodeId, cursor: cursor, limit: limit);
    final page = AssetPage(List.unmodifiable(response.assets.map(toDomain)), response.nextCursor);
    if (generation == _generation) {
      _pages.put(key, type, page, page.assets.fold<int>(0, (n, a) => n + (a.previewData?.length ?? 0)));
    }
    return page;
  }

  @override
  Future<AssetModel> getAsset({String id = '', String type = '', String name = '', String emotion = '', String episodeId = '', String version = '', String variant = '', int targetWidth = 0, int targetHeight = 0}) async {
    final scope = await _service.cacheScope();
    String originalKey(String assetId, String revision) => jsonEncode([scope, assetId, revision, variant, targetWidth, targetHeight]);
    final lookup = jsonEncode(id.isEmpty ? [scope, 'name', type, episodeId, name, emotion, variant, targetWidth, targetHeight] : [scope, 'id', id, variant, targetWidth, targetHeight]);
    final knownKey = id.isNotEmpty && version.isNotEmpty ? originalKey(id, version) : _lookups.get(lookup);
    if (knownKey != null) {
      final cached = _originals.get(knownKey);
      if (cached != null) return cached;
    }
    final generation = _generation;
    var targetId = id;
    if (id.isEmpty) {
      // По имени получаю только ID и версию, без каталога и байтов картинки
      final metadata = await _service.getAsset(type: type, name: name, emotion: emotion, episodeId: episodeId, metadataOnly: true);
      targetId = metadata.id;
      final key = originalKey(metadata.id, metadata.version);
      final cached = _originals.get(key);
      if (cached != null) {
        if (generation == _generation) _lookups.put(lookup, cached.type, key, key.length * 2);
        return cached;
      }
    }
    final response = await _service.getAsset(id: targetId, variant: variant, targetWidth: targetWidth, targetHeight: targetHeight);
    final model = toDomain(response);
    if (generation == _generation) {
      // Каждый размер храню отдельно, чтобы не подменить его оригиналом
      final key = originalKey(model.id, model.version);
      _originals.put(key, model.type, model, model.fileData.length + (model.previewData?.length ?? 0));
      _lookups.put(lookup, model.type, key, key.length * 2);
      _lookups.put(jsonEncode([scope, 'id', model.id, variant, targetWidth, targetHeight]), model.type, key, key.length * 2);
    }
    return model;
  }

  @override
  Future<AssetModel?> uploadAsset({required String type, required String name, required String emotion,
    required String displayName, required String episodeId, required Uint8List fileData, required String fileName}) async {
    final response = await _service.uploadAsset(type: type, name: name, emotion: emotion,
      displayName: displayName, episodeId: episodeId, fileData: fileData, fileName: fileName);
    if (!response.success || !response.hasAsset()) return null;
    invalidateCache(type);
    return toDomain(response.asset);
  }

  @override
  Future<bool> deleteAsset(String id) async {
    final response = await _service.deleteAsset(id);
    if (response.success) invalidateCache();
    return response.success;
  }

  AssetModel toDomain(Asset asset) => AssetModel(id: asset.id, type: asset.type, name: asset.name,
    emotion: asset.emotion, url: asset.url, displayName: asset.displayName, episodeId: asset.episodeId,
    fileData: Uint8List.fromList(asset.fileData), previewData: Uint8List.fromList(asset.previewData), version: asset.version);
}