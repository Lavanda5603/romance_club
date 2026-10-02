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
      appBar: AppBar( // Верхняя панель
        backgroundColor: Colors.transparent, // Прозрачный фон
        elevation: 0, // Без тени
        leading: IconButton( // Кнопка с иконкой
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD30010)), // Кнопка назад
          onPressed: () {
            Navigator.pop(context); // Закрыть экран
          },
        ),
        title: const Text( // Текст (маленький, в AppBar)
          'Клуб романтики',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true, // По центру
      ),
      body: Padding( // Отступы
        padding: const EdgeInsets.all(16),
        child: Column( // Вертикальный список
          children: [
            const Text( // Большой заголовок
              'ВЫБОР ЭПИЗОДА',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            // Список эпизодов
            Expanded( // Растягивание
              child: _isLoading
                  // Если идёт загрузка
                  ? const Center(child: CircularProgressIndicator())
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
                                final isSelected = index == _selectedIndex;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ElevatedButton( // Кнопка с фоном
                                    onPressed: () {
                                      setState(() {
                                        _selectedIndex = index; // Выбираю эпизод
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelected ? const Color(0xFFD30010) : const Color(0xFF333333),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _episodes[index].title, // Название эпизода
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            const SizedBox(height: 16),
            // Кнопка продолжить
            SizedBox( // Контейнер
              width: double.infinity, // На всю ширину
              child: ElevatedButton( // Кнопка с фоном
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'продолжить',
                  style: TextStyle(color: Color(0xFF3F0404), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Кнопка сбросить прогресс
            SizedBox( // Контейнер
              width: double.infinity, // На всю ширину
              child: ElevatedButton( // Кнопка с фоном
                onPressed: _resetProgress, // Сброс прогресса
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'сбросить прогресс',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}