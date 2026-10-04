import 'package:flutter/material.dart'; // Импорт Material UI
import '../generated/settings.pb.dart'; // Импорт Protobuf-модели Settings
import '../services/storage_service.dart'; // Импорт сервиса хранения

// Экран настроек
class SettingsScreen extends StatefulWidget {
  // Конструктор класса SettingsScreen
  const SettingsScreen({super.key});

  // Метод createState (создание объекта состояния)
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _musicVolume = 0.6; // Громкость музыки (0.0 - 1.0)
  double _soundVolume = 0.3; // Громкость звуков (0.0 - 1.0)

  @override
  void initState() {
    super.initState();
    // Загружаю сохранённые настройки
    _loadSettings();
  }

  // Загрузка настроек из файла
  Future<void> _loadSettings() async {
    final settings = await StorageService.loadSettings(); // Загружаю
    setState(() {
      _musicVolume = settings.musicVolume; // Громкость музыки
      _soundVolume = settings.soundVolume; // Громкость звуков
    });
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок
                        const Center(
                          child: Text(
                            'НАСТРОЙКИ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w300, // Тонкий шрифт
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Подпись
                        const Text(
                          'Громкость музыки:',
                          style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        
                        // Слайдер музыки и процент
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _musicVolume,
                                onChanged: (value) {
                                  setState(() {
                                    _musicVolume = value;
                                  });
                                },
                                activeColor: Colors.white,
                                inactiveColor: Colors.grey,
                              ),
                            ),
                            Text(
                              '${(_musicVolume * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Подпись
                        const Text(
                          'Громкость звуков:',
                          style: TextStyle(color: Color(0xFFFFA0A0), fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        
                        // Слайдер звуков и процент
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _soundVolume,
                                onChanged: (value) {
                                  setState(() {
                                    _soundVolume = value;
                                  });
                                },
                                activeColor: Colors.white,
                                inactiveColor: Colors.grey,
                              ),
                            ),
                            Text(
                              '${(_soundVolume * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Кнопка сохранить
                        SizedBox(
                          width: 200, // Уже
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Создаю объект настроек
                              final settings = Settings(
                                musicVolume: _musicVolume,
                                soundVolume: _soundVolume,
                              );

                              // Сохраняю в файл
                              await StorageService.saveSettings(settings);

                              // Показываю уведомление
                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Настройки сохранены')),
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
                              'сохранить',
                              style: TextStyle(
                                color: Color(0xFF3F0404), 
                                fontSize: 18, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),

                        // Пустое пространство снизу, чтобы поднять кнопку выше
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