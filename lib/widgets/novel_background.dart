import 'package:flutter/material.dart'; // Импорт общего фона экранов

import '../services/active_novel.dart'; // Импорт оформления выбранной истории
import '../src/data/services/asset_grpc_service.dart'; // Импорт картинок из библиотеки

import 'dart:typed_data'; // Импорт байтов картинки

class NovelBackground extends StatelessWidget {
  const NovelBackground({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ActiveNovel.shared,
    builder: (_, child) {
      final active = ActiveNovel.shared;
      if (active.background != null) {
        return Image.memory(
          active.background!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
      if (active.id == ActiveNovel.legacyId) {
        return Image.asset(
          'assets/images/main_background.png',
          fit: BoxFit.cover,
        );
      }
      return const ColoredBox(color: Color(0xFF1A1A1A));
    },
  );
}

class NovelImage extends StatefulWidget {
  final String id;
  final BoxFit fit;
  final int size;
  const NovelImage({
    super.key,
    required this.id,
    this.fit = BoxFit.contain,
    this.size = 720,
  });
  @override
  State<NovelImage> createState() => _NovelImageState();
}

class _NovelImageState extends State<NovelImage> {
  final _service = AssetGrpcService();
  late Future<Uint8List?> _bytes;
  @override
  void initState() {
    super.initState();
    _bytes = _load();
  }

  @override
  void didUpdateWidget(covariant NovelImage old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id || old.size != widget.size) _bytes = _load();
  }

  Future<Uint8List?> _load() async {
    if (widget.id.isEmpty) return null;
    try {
      final asset = await _service.getAsset(
        id: widget.id,
        variant: 'screen',
        targetWidth: widget.size,
        targetHeight: widget.size * 2,
      );
      return Uint8List.fromList(asset.fileData);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _bytes,
    builder: (_, snapshot) => snapshot.data != null && snapshot.data!.isNotEmpty
        ? Image.memory(
            snapshot.data!,
            fit: widget.fit,
            errorBuilder: (_, error, stack) =>
                const Icon(Icons.image_outlined, color: Color(0xFFFFA0A0)),
          )
        : const Icon(Icons.image_outlined, color: Color(0xFFFFA0A0), size: 48),
  );
}