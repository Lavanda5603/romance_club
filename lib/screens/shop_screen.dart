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
      body: SingleChildScrollView( // Прокрутка
        child: Padding( // Отступы
          padding: const EdgeInsets.all(16),
          child: Column( // Вертикальный список
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text( // Большой заголовок
                'МАГАЗИН',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              // Валюта (надпись, алмазик, число)
              Row( // Горизонтальный список
                children: [
                  const Text('валюта: ', style: TextStyle(color: Colors.white, fontSize: 18)), // Надпись
                  Icon(Icons.diamond, color: Color(0xFFFFA0A0), size: 24), // Алмаз
                  const SizedBox(width: 4),
                  Text('$_currency', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), // Число
                ],
              ),
              const SizedBox(height: 32),
              // Заголовок
              const Text('эпизоды', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Блок эпизода
              Container( // Контейнер
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFFFA0A0)), // Розовая рамка
                  borderRadius: BorderRadius.circular(12), // Круглые углы
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
                        const Text('199 р.', style: TextStyle(color: Colors.white, fontSize: 16)), // Цена
                        TextButton( // Кнопка без фона
                          onPressed: () => _buy('эпизод'), // Купить эпизод
                          child: const Text('купить', style: TextStyle(color: Color(0xFFD30010), fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Заголовок
              const Text('подписка', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Блок подписки
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFFFA0A0)), // Розовая рамка
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Пункт все эпизоды
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)), // Серый кругляшок
                        const SizedBox(width: 8),
                        const Text('все эпизоды', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Пункт без рекламы
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)), // Серый кругляшок
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
                        TextButton( // Кнопка без фона
                          onPressed: () => _buy('подписку'), // Купить подписку
                          child: const Text('купить', style: TextStyle(color: Color(0xFFD30010), fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Заголовок
              const Text('пакеты валюты', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Блок пакетов
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFFFA0A0)), // Розовая рамка
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Три пакета валюты
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCurrencyPackage(100, 99), // 100 алмазов
                        _buildCurrencyPackage(250, 249), // 250 алмазов
                        _buildCurrencyPackage(500, 499), // 500 алмазов
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Кнопка купить
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _buy('валюту'), // Купить валюту
                        child: const Text('купить', style: TextStyle(color: Color(0xFFD30010), fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Виджет пакета валюты (вспомогательный метод)
  Widget _buildCurrencyPackage(int amount, int price) {
    return GestureDetector( // Обработка нажатия
      onTap: () => _buy('$amount алмазов за $price р.'), // Покупка пакета
      child: Container( // Контейнер
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white), // Белая рамка
          borderRadius: BorderRadius.circular(12), // Круглые углы
        ),
        child: Column(
          children: [
            // Иконка и количество
            Row(
              children: [
                Icon(Icons.diamond, color: Colors.white, size: 20), // Белый алмаз
                const SizedBox(width: 4),
                Text('$amount', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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