import '../src/data/services/rpc_policy.dart'; // Импорт сроков ожидания и ошибок сети
import '../src/domain/repositories/asset_repository.dart'; // Импорт интерфейса репозитория ассетов
import 'package:flutter/material.dart'; // Импорт Material UI
import 'package:file_picker/file_picker.dart'; // Импорт выбора файла
import 'dart:io'; // Импорт File
import 'dart:typed_data'; // Импорт Uint8List
import '../src/data/repositories/asset_repository_remote.dart'; // Импорт репозитория ассетов
import '../src/data/repositories/admin_repository_remote.dart'; // Импорт админ-репозитория
import '../src/data/services/asset_grpc_service.dart'; // Импорт gRPC-сервиса ассетов
import '../src/data/services/admin_grpc_service.dart'; // Импорт админ-сервиса
import '../src/domain/models/asset_model.dart'; // Импорт доменной модели

// Экран выбора ассета (фона или персонажа)
class AssetPickerScreen extends StatefulWidget {
  final AssetRepository? repository;
  final String type; // Тип: background или character
  final String title; // Заголовок экрана
  final String episodeId; // ID эпизода (для фильтра)

  // Конструктор
  const AssetPickerScreen({
    super.key,
    required this.type,
    this.repository,
    required this.title,
    this.episodeId = '',
  });

  @override
  State<AssetPickerScreen> createState() => _AssetPickerScreenState();
}

class _AssetPickerScreenState extends State<AssetPickerScreen> {
  late AssetGrpcService _service; // gRPC-сервис ассетов
  late AdminGrpcService _adminService; // gRPC-сервис админа
  late AssetRepository _repository; // Репозиторий ассетов
  late AdminRepositoryRemote _adminRepository; // Админ-репозиторий

  List<AssetModel> _assets = []; // Список ассетов
  bool _isLoading = true; // Флаг загрузки
  bool _isUploading = false; // Флаг загрузки файла
  String _error = ''; // Ошибка
  String _nextCursor = '';
  bool _loadingPage = false;

  @override
  void initState() {
    super.initState();
    // Создаю сервисы и репозитории
    _service = AssetGrpcService();
    _adminService = AdminGrpcService();
    _repository = widget.repository ?? AssetRepositoryRemote(_service);
    _adminRepository = AdminRepositoryRemote(_adminService);
    // Загружаю ассеты
    _loadAssets();
  }

  @override
  void dispose() {
    // Закрываю соединения
    _service.close();
    _adminService.close();
    super.dispose();
  }

  // Получаю одну страницу, уже показанную сетку не скрываю
  Future<void> _loadAssets({bool reset = true}) async {
    if (_loadingPage) return;
    _loadingPage = true;
    setState(() { _error = ''; if (reset) _isLoading = true; });
    try {
      final page = await _repository.getAssetPage(widget.type,
        episodeId: widget.episodeId, cursor: reset ? '' : _nextCursor);
      if (!mounted) return;
      setState(() {
        final known = reset ? <String>{} : _assets.map((a) => a.id).toSet();
        _assets = [if (!reset) ..._assets, ...page.assets.where((a) => known.add(a.id))];
        _nextCursor = page.nextCursor;
      });
    } catch (e) {
      if (mounted) setState(() => _error = networkError(e));
    } finally {
      _loadingPage = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Оригинал нужен только после выбора картинки
  Future<void> _selectAsset(AssetModel asset) async {
    if (_isUploading) return;
    setState(() => _isUploading = true);
    try {
      final original = await _repository.getAsset(id: asset.id, type: asset.type, version: asset.version);
      if (mounted) Navigator.pop(context, original);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки: ${networkError(e)}')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Загрузка нового ассета
  Future<void> _uploadNewAsset() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (!mounted) return;
    if (file.size > AssetGrpcService.maxUploadBytes) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Файл больше 5 MiB (5 242 880 байт)')));
      return;
    }
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось прочитать файл')),
      );
      return;
    }

    if (!mounted) return;

    if (bytes.length > AssetGrpcService.maxUploadBytes) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Файл больше 5 MiB (5 242 880 байт)')));
      return;
    }
    final nameController = TextEditingController();
    final displayController = TextEditingController(text: file.name);
    final emotionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Новый ассет'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя (латиницей, без пробелов)',
                    hintText: 'например: new_bg, marinet',
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.type == 'character')
                  TextField(
                    controller: emotionController,
                    decoration: const InputDecoration(
                      labelText: 'Эмоция (латиницей)',
                      hintText: 'например: happy, sad',
                    ),
                  ),
                if (widget.type == 'character')
                  const SizedBox(height: 8),
                TextField(
                  controller: displayController,
                  decoration: const InputDecoration(
                    labelText: 'Название (для отображения)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Загрузить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя обязательно')),
      );
      return;
    }

    // Проверяю на дубликат
    final emotionCheck = emotionController.text.trim();

    final alreadyExists = _assets.any((a) =>
        a.name == name && a.emotion == emotionCheck && a.episodeId == widget.episodeId);

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ассет с таким именем и эмоцией уже существует')),
      );
      return;
    }

    setState(() => _isUploading = true);

    // Эпизод передаю отдельно, имя не привязываю к ep1

    try {
      final asset = await _repository.uploadAsset(
        type: widget.type, name: name, emotion: emotionController.text.trim(),
        displayName: displayController.text.trim(), episodeId: widget.episodeId,
        fileData: bytes, fileName: file.name,
      );
      if (asset == null) throw StateError('Не удалось загрузить ассет');
      if (!mounted) return;
      await _loadAssets();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ассет загружен')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(networkError(e))));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Удалить ассет (через админ-репозиторий)
  Future<void> _deleteAsset(AssetModel asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить ассет?'),
          content: Text('Удалить "${asset.displayName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Вызываю Админ-репозиторий (проверка прав на сервере)
    setState(() => _isUploading = true);
    try {
      final success = await _adminRepository.deleteAsset(asset.id);
      if (!mounted) return;
      if (success) await _loadAssets();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        success ? 'Ассет удалён' : 'Нет прав на удаление')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(networkError(e))));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1A1A),
              child: Image.asset(
                'assets/images/main_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFFD30010), size: 28),
                        onPressed: () => Navigator.pop(context, null),
                      ),
                      Text(
                        widget.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.upload, color: Color(0xFFD30010), size: 28),
                        onPressed: _loadingPage || _isUploading ? null : _uploadNewAsset,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            widget.title.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isLoading)
                          const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(color: Color(0xFFD30010)),
                            ),
                          )
                        else if (_error.isNotEmpty && _assets.isEmpty)
                          Expanded(
                            child: Center(
                              child: Text(
                                'Ошибка: $_error',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else if (_assets.isEmpty)
                          const Expanded(
                            child: Center(
                              child: Text(
                                'нет ассетов',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: _assets.length,
                              itemBuilder: (context, index) {
                                final asset = _assets[index];
                                return GestureDetector(
                                  onTap: () => _selectAsset(asset),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3F0404),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFFFA0A0),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(11),
                                                ),
                                                child: (asset.previewData == null || asset.previewData!.isEmpty)
                                                    ? Container(
                                                        color: const Color(0xFF333333),
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.image_not_supported,
                                                            color: Colors.white,
                                                            size: 24,
                                                          ),
                                                        ),
                                                      )
                                                    : Image.memory(
                                                        asset.previewData!,
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            color: const Color(0xFF333333),
                                                            child: const Center(
                                                              child: Icon(
                                                                Icons.broken_image,
                                                                color: Colors.white,
                                                                size: 24,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Text(
                                                asset.displayName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: _loadingPage || _isUploading ? null : () => _deleteAsset(asset),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.7),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              color: Color(0xFFD30010),
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        if (!_isLoading && _assets.isEmpty && _error.isNotEmpty)
                          TextButton(onPressed: () => _loadAssets(), child: const Text('Повторить')),
                        if (!_isLoading && _assets.isNotEmpty && (_nextCursor.isNotEmpty || _error.isNotEmpty))
                          Column(children: [
                            if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
                            TextButton(onPressed: _loadingPage ? null : () => _loadAssets(reset: false),
                              child: Text(_loadingPage ? 'Загрузка...' : 'Загрузить ещё')),
                          ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD30010)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}