import 'package:flutter/material.dart'; // Импорт Material UI

// Экран магазина
class ShopScreen extends StatefulWidget {
  // Конструктор класса ShopScreen
  const ShopScreen({super.key});

  // Метод createState (создание объекта состояния)
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final int _currency = 0; // Валюта игрока
  final String _episodeName = ''; // Название эпизода

  // Покупка (заглушка)
  void _buy(String item) {
    // Показываю уведомление о покупке
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Покупка: $item')),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок в стиле других экранов (тонкий)
                        const Center(
                          child: Text(
                            'МАГАЗИН',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w300, // Тонкий шрифт
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Валюта (надпись, алмазик, число)
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
                          'эпизоды', 
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300)
                        ),
                        const SizedBox(height: 16),

                        // Блок эпизода
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFFFA0A0)), // Розовая рамка
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Название эпизода
                              Text(
                                _episodeName.isEmpty ? 'эпизод "..."' : _episodeName,
                                style: const TextStyle(color: Colors.white, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              // Цена и кнопка
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('199 р.', style: TextStyle(color: Colors.white, fontSize: 16)),
                                  TextButton(
                                    onPressed: () => _buy('эпизод'),
                                    child: const Text(
                                      'купить', 
                                      style: TextStyle(color: Color(0xFFD30010), fontSize: 14)
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                              // Пункт все эпизоды
                              Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  const Text('все эпизоды', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Пункт без рекламы
                              Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  const Text('без рекламы', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Цена и кнопка
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('499 р. мес', style: TextStyle(color: Colors.white, fontSize: 16)),
                                  TextButton(
                                    onPressed: () => _buy('подписку'),
                                    child: const Text(
                                      'купить', 
                                      style: TextStyle(color: Color(0xFFD30010), fontSize: 14)
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                          child: Column(
                            children: [
                              // Три пакета валюты
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildCurrencyPackage(100, 99),
                                  _buildCurrencyPackage(250, 249),
                                  _buildCurrencyPackage(500, 499),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Кнопка купить
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _buy('валюту'),
                                  child: const Text(
                                    'купить', 
                                    style: TextStyle(color: Color(0xFFD30010), fontSize: 14)
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Пустое пространство снизу
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

  // Виджет пакета валюты (вспомогательный метод)
  Widget _buildCurrencyPackage(int amount, int price) {
    return GestureDetector(
      onTap: () => _buy('$amount алмазов за $price р.'),
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
                const Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 22), // Розовый алмазик
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
}