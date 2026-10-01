// Класс для описания состояний асинхронных операций
class AsyncState<T> {
  final bool isLoading; // Загрузка
  final T? data; // Данные
  final String? error; // Ошибка

  // Конструктор класса AsyncState
  const AsyncState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  // Состояние ничего не происходит
  factory AsyncState.idle() => const AsyncState();

  // Состояние загрузка
  factory AsyncState.loading() => const AsyncState(isLoading: true);

  // Состояние успех
  factory AsyncState.success(T data) => AsyncState(data: data);

  // Состояние ошибка
  factory AsyncState.failure(String error) => AsyncState(error: error);
}