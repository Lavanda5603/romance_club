import 'package:flutter/material.dart'; // Импорт Material UI
import 'package:file_picker/file_picker.dart'; // Импорт выбора файла
import 'dart:io'; // Импорт File
import 'dart:typed_data'; // Импорт Uint8List
import '../src/data/repositories/asset_repository_remote.dart'; // Импорт репозитория ассетов
import '../src/data/services/asset_grpc_service.dart'; // Импорт gRPC-сервиса
import '../src/domain/models/asset_model.dart'; // Импорт доменной модели

// Экран выбора ассета (фона или персонажа)
class AssetPickerScreen extends StatefulWidget {
  final String type; // Тип: background или character
  final String title; // Заголовок экрана
  final String episodeId; // ID эпизода (для фильтра)

  // Конструктор класса AssetPickerScreen
  const AssetPickerScreen({
    super.key,
    required this.type,
    required this.title,
    this.episodeId = '',
  });

  // Метод createState (создание объекта состояния)
  @override
  State<AssetPickerScreen> createState() => _AssetPickerScreenState();
}

class _AssetPickerScreenState extends State<AssetPickerScreen> {
  late AssetGrpcService _service; // gRPC-сервис
  late AssetRepositoryRemote _repository; // Репозиторий

  List<AssetModel> _assets = []; // Список ассетов
  bool _isLoading = true; // Флаг загрузки
  bool _isUploading = false; // Флаг загрузки файла
  String _error = ''; // Ошибка

  @override
  void initState() {
    super.initState();
    // Создаю сервис и репозиторий
    _service = AssetGrpcService();
    _repository = AssetRepositoryRemote(_service);
    // Загружаю ассеты
    _loadAssets();
  }

  @override
  void dispose() {
    // Закрываю соединение
    _service.close();
    super.dispose();
  }

  // Загрузка ассетов с сервера
  Future<void> _loadAssets() async {
    try {
      final assets = await _repository.getAssets(
        widget.type,
        episodeId: widget.episodeId,
      );

      if (!mounted) return;

      setState(() {
        _assets = assets;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Загрузка нового ассета
  Future<void> _uploadNewAsset() async {
    // Открываю диалог выбора файла
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    // Получаю байты
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

    // Контроллеры для диалога
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

    setState(() => _isUploading = true);

    final fullName = widget.type == 'background' ? 'ep1/$name' : name;

    final asset = await _repository.uploadAsset(
      type: widget.type,
      name: fullName,
      emotion: emotionController.text.trim(),
      displayName: displayController.text.trim(),
      episodeId: widget.episodeId,
      fileData: bytes,
      fileName: file.name,
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (asset != null) {
      setState(() {
        _assets.add(asset);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ассет загружен')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки')),
      );
    }
  }

  // Удалить ассет (с подтверждением)
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

    // Отправляю на сервер
    final success = await _repository.deleteAsset(asset.id);

    if (!mounted) return;

    if (success) {
      setState(() {
        _assets.removeWhere((a) => a.id == asset.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ассет удалён')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка удаления')),
      );
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
                        onPressed: () {
                          Navigator.pop(context, null);
                        },
                      ),
                      Text(
                        widget.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.upload, color: Color(0xFFD30010), size: 28),
                        onPressed: _uploadNewAsset,
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
                        else if (_error.isNotEmpty)
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
                                  onTap: () => Navigator.pop(context, asset),
                                  child: Stack(
                                    children: [
                                      // Карточка
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
                                                child: asset.fileData.isEmpty
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
                                                        Uint8List.fromList(asset.fileData),
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
                                      // Кнопка удаления (корзина)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _deleteAsset(asset),
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