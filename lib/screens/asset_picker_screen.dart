import 'package:flutter/material.dart'; // Импорт Material UI
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

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Каркас экрана
      backgroundColor: const Color(0xFF1A1A1A), // Фон экрана

      // Использую Stack, чтобы наложить контент на фон
      body: Stack(
        children: [
          // Слой для фона
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1A1A), // Цвет фона-заглушки
              // Картинка фона
              child: Image.asset(
                'assets/images/main_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Основной контент
          SafeArea(
            child: Column(
              children: [
                // Верхняя панель
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Кнопка назад
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFFD30010), size: 28),
                        onPressed: () {
                          Navigator.pop(context, null); // Возвращаю null (отмена)
                        },
                      ),

                      // Заголовок
                      Text(
                        widget.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),

                      // Пустой контейнер для симметрии
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Основной блок
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок
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

                        // Если загрузка
                        if (_isLoading)
                          const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(color: Color(0xFFD30010)),
                            ),
                          )
                        // Если ошибка
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
                        // Если пусто
                        else if (_assets.isEmpty)
                          const Expanded(
                            child: Center(
                              child: Text(
                                'нет ассетов',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        // Сетка картинок
                        else
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 2 колонки
                                crossAxisSpacing: 12, // Отступ между колонками
                                mainAxisSpacing: 12, // Отступ между строками
                                childAspectRatio: 1.2, // Соотношение сторон
                              ),
                              itemCount: _assets.length,
                              itemBuilder: (context, index) {
                                final asset = _assets[index];
                                return GestureDetector(
                                  // Клик по картинке - возвращаю ассет
                                  onTap: () => Navigator.pop(context, asset),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3F0404),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFFFA0A0),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        // Картинка
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(15),
                                            ),
                                            child: Image.asset(
                                              asset.url,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              // Заглушка, если файла нет
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: const Color(0xFF333333),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.white,
                                                      size: 40,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        // Название
                                        Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(
                                            asset.displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
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
        ],
      ),
    );
  }
}