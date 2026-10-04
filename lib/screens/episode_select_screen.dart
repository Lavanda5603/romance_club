import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/episode.pb.dart'; // Импорт Protobuf-модели Episode
import '../src/data/services/episode_grpc_service.dart'; // Импорт gRPC-сервиса
import 'game_screen.dart'; // Импорт игрового экрана

// Экран выбора эпизода
class EpisodeSelectScreen extends StatefulWidget {
  // Конструктор класса EpisodeSelectScreen
  const EpisodeSelectScreen({super.key});

  // Метод createState (создание объекта состояния)
  @override
  State<EpisodeSelectScreen> createState() => _EpisodeSelectScreenState();
}

class _EpisodeSelectScreenState extends State<EpisodeSelectScreen> {
  // Список эпизодов (Protobuf-модели)
  final List<Episode> _episodes = [];

  // Выбранный эпизод
  int _selectedIndex = 0;

  // Флаг загрузки
  bool _isLoading = true;

  // Ошибка загрузки
  String? _error;

  // gRPC-сервис
  late EpisodeGrpcService _service;

  @override
  void initState() {
    super.initState();
    // Создаю gRPC-сервис
    _service = EpisodeGrpcService();
    // Загружаю эпизоды при открытии экрана
    _loadEpisodes();
  }

  @override
  void dispose() {
    // Закрываю соединение
    _service.close();
    super.dispose();
  }

  // Загрузка эпизодов с сервера
  Future<void> _loadEpisodes() async {
    try {
      // Запрашиваю эпизоды с сервера
      final episodes = await _service.getAllEpisodes();

      setState(() {
        _episodes.clear(); // Очищаю текущий список
        _episodes.addAll(episodes); // Добавляю загруженные эпизоды
        _isLoading = false; // Загрузка завершена
      });
    } catch (e) {
      setState(() {
        _error = e.toString(); // Сохраняю ошибку
        _isLoading = false; // Загрузка завершена
      });
    }
  }

  // Сброс прогресса
  Future<void> _resetProgress() async {
    // Показываю диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog( // Всплывающее окно
          title: const Text('Сбросить прогресс?'),
          content: const Text(
            'Вы точно уверены, что хотите сбросить весь прогресс? Это действие нельзя отменить.',
          ),
          actions: [
            TextButton( // Кнопка без фона
              onPressed: () => Navigator.pop(context, false), // Отмена
              child: const Text('Отмена'),
            ),
            TextButton( // Кнопка без фона
              onPressed: () => Navigator.pop(context, true), // Подтверждение
              child: const Text('Сбросить'),
            ),
          ],
        );
      },
    );

    // Если пользователь подтвердил - сбрасываю прогресс
    if (confirmed == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Прогресс сброшен')),
      );
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок
                        const Center(
                          child: Text(
                            'ВЫБОР\nЭПИЗОДА',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w300, // Тонкий шрифт
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Список эпизодов
                        Expanded(
                          child: _isLoading
                              // Если идёт загрузка
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD30010)))
                              // Если ошибка
                              : _error != null
                                  ? Center(
                                      child: Text(
                                        'Ошибка: $_error',
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    )
                                  // Если эпизодов нет
                                  : _episodes.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'нет эпизодов',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        )
                                      // Список эпизодов
                                      : ListView.builder(
                                          itemCount: _episodes.length,
                                          itemBuilder: (context, index) {
                                            // ignore: unused_local_variable
                                            final isSelected = index == _selectedIndex;
                                            // Логика прогресса: первый эпизод пройден (красный), остальные серые
                                            final isPassed = index == 0;
                                            
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: SizedBox(
                                                width: 220,
                                                height: 55,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedIndex = index; // Выбираю эпизод
                                                    });
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    // Красный, если пройден, серый, если нет
                                                    backgroundColor: isPassed 
                                                        ? const Color(0xFFD30010) 
                                                        : const Color(0xFF534F50),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  child: Text(
                                                    _episodes[index].title, // Название эпизода
                                                    style: const TextStyle(
                                                      color: Color(0xFF3F0404), 
                                                      fontSize: 18, 
                                                      fontWeight: FontWeight.bold
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                        ),
                        
                        const SizedBox(height: 8),

                        // Кнопка продолжить
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                // Если эпизодов нет - не перехожу
                                if (_episodes.isEmpty) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GameScreen(
                                      episode: _episodes[_selectedIndex], // Передаю выбранный эпизод
                                    ),
                                  )
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
                                'продолжить',
                                style: TextStyle(
                                  color: Color(0xFF3F0404), 
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),

                        // Кнопка сбросить прогресс
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _resetProgress, // Сброс прогресса
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF534F50), // Серый
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'сбросить\nпрогресс',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF3F0404), // Тёмно-красный
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Пустое пространство снизу, чтобы поднять кнопки выше
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