import 'package:flutter/material.dart'; // Импорт Material UI
import '../../data/repositories/episode_repository_remote.dart'; // Импорт репозитория
import '../../data/services/episode_grpc_service.dart'; // Импорт gRPC-сервиса
import '../game/game_view_model.dart'; // Импорт ViewModel

// Тестовый экран для проверки связи с сервером
class TestScreen extends StatefulWidget {
  // Конструктор класса TestScreen
  const TestScreen({super.key});

  // Метод createState (создание объекта состояния)
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late GameViewModel _viewModel; // ViewModel
  late EpisodeGrpcService _service; // gRPC-сервис

  @override
  void initState() {
    super.initState();
    // Создаю gRPC-сервис
    _service = EpisodeGrpcService();
    // Создаю репозиторий
    final repository = EpisodeRepositoryRemote(_service);
    // Создаю ViewModel
    _viewModel = GameViewModel(repository);
  }

  @override
  void dispose() {
    // Закрываю соединение
    _service.close();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Каркас экрана
      backgroundColor: const Color(0xFF1A1A1A), // Фон
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Тест', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Кнопка Загрузить эпизод 1
            ElevatedButton(
              onPressed: () {
                _viewModel.loadEpisode(1); // Загружаю эпизод с ID 1
              },
              child: const Text('Загрузить эпизод 1'),
            ),
            const SizedBox(height: 16),
            // Показываю состояние
            ListenableBuilder(
              listenable: _viewModel, // Слушаю ViewModel
              builder: (context, _) {
                final state = _viewModel.state; // Текущее состояние

                // Если загрузка
                if (state.isLoading) {
                  return const CircularProgressIndicator();
                }

                // Если ошибка
                if (state.error != null) {
                  return Text(
                    'Ошибка: ${state.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }

                // Если успех
                if (state.data != null) {
                  return Text(
                    'Эпизод: ${state.data!.title}',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  );
                }

                // Если ничего не происходит
                return const Text(
                  'Нажми кнопку',
                  style: TextStyle(color: Colors.white),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}