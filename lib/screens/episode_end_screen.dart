import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../src/data/services/episode_grpc_service.dart'; // Импорт gRPC-сервиса эпизодов
import 'episode_select_screen.dart'; // Импорт экрана выбора эпизода
import 'game_screen.dart'; // Импорт игрового экрана

// Экран окончания эпизода
class EpisodeEndScreen extends StatefulWidget {
  final Episode currentEpisode; // Текущий (пройденный) эпизод

  // Конструктор класса EpisodeEndScreen
  const EpisodeEndScreen({
    super.key,
    required this.currentEpisode,
  });

  // Метод createState (создание объекта состояния)
  @override
  State<EpisodeEndScreen> createState() => _EpisodeEndScreenState();
}

class _EpisodeEndScreenState extends State<EpisodeEndScreen> {
  // Следующий эпизод (может быть null)
  Episode? _nextEpisode;

  // Флаг загрузки
  bool _isLoading = true;

  // gRPC-сервис
  late EpisodeGrpcService _service;

  @override
  void initState() {
    super.initState();
    // Создаю gRPC-сервис
    _service = EpisodeGrpcService();
    // Загружаю следующий эпизод
    _loadNextEpisode();
  }

  @override
  void dispose() {
    // Закрываю соединение
    _service.close();
    super.dispose();
  }

  // Загрузка следующего эпизода
  Future<void> _loadNextEpisode() async {
    try {
      // Загружаю все эпизоды
      final episodes = await _service.getAllEpisodes();

      if (!mounted) return;

      // Ищу следующий эпизод (по id)
      Episode? next;
      for (final ep in episodes) {
        if (ep.id > widget.currentEpisode.id) {
          // Первый эпизод с большим id - следующий
          if (next == null || ep.id < next.id) {
            next = ep;
          }
        }
      }

      setState(() {
        _nextEpisode = next;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Заголовок
                      const Text(
                        'Клуб романтики',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Основной блок
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Заголовок
                          const Center(
                            child: Text(
                              'КОНЕЦ\nЭПИЗОДА',
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

                          // Название пройденного эпизода
                          Text(
                            widget.currentEpisode.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFFA0A0),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Если загрузка - показываю крутилку
                          if (_isLoading)
                            const CircularProgressIndicator(color: Color(0xFFD30010))
                          // Если есть следующий эпизод
                          else if (_nextEpisode != null) ...[
                            // Кнопка следующий эпизод
                            SizedBox(
                              width: 260,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Переход на следующий эпизод
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GameScreen(
                                        episode: _nextEpisode!,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD30010),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'следующий эпизод',
                                  style: TextStyle(
                                    color: Color(0xFF3F0404),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ]
                          // Если следующего эпизода нет
                          else
                            const Text(
                              'Конец сезона!',
                              style: TextStyle(
                                color: Color(0xFFFFA0A0),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 12),

                          // Кнопка в меню
                          SizedBox(
                            width: 200,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                // Переход на экран выбора эпизода
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EpisodeSelectScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF534F50), // Серый
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'в меню',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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