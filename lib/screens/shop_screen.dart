import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../services/storage_service.dart'; // Импорт сервиса хранения
import '../src/data/repositories/shop_repository_remote.dart'; // Импорт репозитория магазина
import '../src/data/services/episode_grpc_service.dart'; // Импорт gRPC-сервиса эпизодов
import '../src/data/services/shop_grpc_service.dart'; // Импорт gRPC-сервиса магазина
import 'game_screen.dart'; // Импорт игрового экрана

// Экран магазина
class ShopScreen extends StatefulWidget {
  // Конструктор класса ShopScreen
  const ShopScreen({super.key});

  // Метод createState (создание объекта состояния)
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // Валюта игрока
  int _currency = 0;

  // Куплена ли подписка
  bool _hasSubscription = false;

  // Список эпизодов (появляется после покупки подписки)
  final List<Episode> _episodes = [];

  // Флаг загрузки
  bool _isLoading = true;

  // ID игрока
  String _playerId = '';

  // gRPC-сервисы
  late ShopGrpcService _shopService;
  late EpisodeGrpcService _episodeService;

  // Репозиторий магазина
  late ShopRepositoryRemote _shopRepository;

  @override
  void initState() {
    super.initState();
    // Создаю сервисы и репозиторий
    _shopService = ShopGrpcService();
    _episodeService = EpisodeGrpcService();
    _shopRepository = ShopRepositoryRemote(_shopService);
    // Загружаю данные
    _loadData();
  }

  @override
  void dispose() {
    // Закрываю соединения
    _shopService.close();
    _episodeService.close();
    super.dispose();
  }

  // Загрузка данных (баланс, подписка, эпизоды если подписка есть)
  Future<void> _loadData() async {
    try {
      // Загружаю player_id из Storage
      _playerId = await StorageService.loadPlayerId();

      if (_playerId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Загружаю баланс
      final currency = await _shopRepository.getCurrency(_playerId);

      // Загружаю покупки
      final purchases = await _shopRepository.getPurchases(_playerId);
      bool hasSub = false;
      for (final p in purchases) {
        if (p.itemId == 'subscription') {
          hasSub = true;
          break;
        }
      }

      // Если подписка есть - загружаю эпизоды
      final episodes = <Episode>[];
      if (hasSub) {
        final loadedEpisodes = await _episodeService.getAllEpisodes();
        episodes.addAll(loadedEpisodes);
      }

      if (!mounted) return;

      setState(() {
        _currency = currency.diamonds;
        _hasSubscription = hasSub;
        _episodes.clear();
        _episodes.addAll(episodes);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Покупка подписки
  Future<void> _buySubscription() async {
    if (_playerId.isEmpty) return;

    // Показываю диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Купить подписку?'),
          content: const Text('Вы уверены, что хотите купить подписку за 500 алмазов?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Купить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final newCurrency = await _shopRepository.purchase(
        playerId: _playerId,
        itemId: 'subscription',
        itemType: 'subscription',
      );

      if (!mounted) return;

      if (newCurrency == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось купить (не хватает алмазов или уже куплено)')),
        );
        return;
      }

      // Загружаю эпизоды после покупки подписки
      final episodes = await _episodeService.getAllEpisodes();

      if (!mounted) return;

      setState(() {
        _currency = newCurrency.diamonds;
        _hasSubscription = true;
        _episodes.clear();
        _episodes.addAll(episodes);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Подписка куплена!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  // Покупка пакета валюты
  Future<void> _buyCurrency(int amount) async {
    if (_playerId.isEmpty) return;

    try {
      final newCurrency = await _shopRepository.purchase(
        playerId: _playerId,
        itemId: 'diamonds_$amount',
        itemType: 'currency',
      );

      if (!mounted) return;

      if (newCurrency == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось купить')),
        );
        return;
      }

      setState(() {
        _currency = newCurrency.diamonds;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Начислено $amount алмазов!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  // Виджет пакета валюты (вспомогательный метод)
  Widget _buildCurrencyPackage(int amount, int price) {
    return GestureDetector(
      onTap: () => _buyCurrency(amount),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Иконка и количество
            Row(
              children: [
                const Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 22),
                const SizedBox(width: 4),
                Text('$amount', style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            // Цена
            Text('$price р.', style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
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
                          Navigator.pop(context);
                        },
                      ),

                      // Заголовок
                      const Text(
                        'Клуб романтики',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),

                      // Пустой контейнер для симметрии
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Основной блок
                Expanded(
                  child: _isLoading
                      // Если идёт загрузка
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFD30010)))
                      // Если загружено
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Заголовок
                              const Center(
                                child: Text(
                                  'МАГАЗИН',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w300,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Валюта
                              Row(
                                children: [
                                  const Text(
                                    'валюта: ',
                                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300)
                                  ),
                                  const Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 24),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_currency',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300)
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Заголовок
                              const Text(
                                'подписка',
                                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300)
                              ),
                              const SizedBox(height: 16),

                              // Блок подписки
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFFFA0A0)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                                        const SizedBox(width: 8),
                                        const Text('все эпизоды разблокированы', style: TextStyle(color: Colors.white, fontSize: 16)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                                        const SizedBox(width: 8),
                                        const Text('без рекламы', style: TextStyle(color: Colors.white, fontSize: 16)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: const [
                                            Text('500 ', style: TextStyle(color: Colors.white, fontSize: 16)),
                                            Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 16),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: _hasSubscription ? null : _buySubscription,
                                          child: Text(
                                            _hasSubscription ? 'активна' : 'купить',
                                            style: TextStyle(
                                              color: _hasSubscription ? Colors.grey : const Color(0xFFD30010),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Если подписка активна - показываю список эпизодов
                              if (_hasSubscription) ...[
                                const SizedBox(height: 32),
                                const Text(
                                  'все эпизоды',
                                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300)
                                ),
                                const SizedBox(height: 16),

                                // Список эпизодов
                                if (_episodes.isEmpty)
                                  const Text(
                                    'нет эпизодов',
                                    style: TextStyle(color: Colors.white),
                                  )
                                else
                                  ..._episodes.map((episode) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          // Название эпизода (розовое)
                                          Expanded(
                                            child: Text(
                                              episode.title,
                                              style: const TextStyle(
                                                color: Color(0xFFFFA0A0),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          // Маленькая белая кнопка
                                          SizedBox(
                                            width: 100,
                                            height: 36,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => GameScreen(
                                                      episode: episode,
                                                      startFromBeginning: true,
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                elevation: 0,
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: const Text(
                                                'играть',
                                                style: TextStyle(
                                                  color: Color(0xFF3F0404),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],

                              const SizedBox(height: 32),

                              // Заголовок
                              const Text(
                                'пакеты валюты',
                                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300)
                              ),
                              const SizedBox(height: 16),

                              // Блок пакетов
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFFFA0A0)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildCurrencyPackage(100, 99),
                                    _buildCurrencyPackage(250, 249),
                                    _buildCurrencyPackage(500, 499),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 100),
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