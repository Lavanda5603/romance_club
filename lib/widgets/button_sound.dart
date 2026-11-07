import 'dart:async'; // Подключаю запуск звука без задержки кнопки

import '../services/app_audio.dart'; // Подключаю общий звук приложения

// Озвучиваю само действие: работают нажатия пальцем, мышью и клавиатурой.
T Function()? withButtonSound<T>(T Function()? action) {
  if (action == null) return null; // Отключённую кнопку не озвучиваю
  return () {
    unawaited(AppAudio.shared.click());
    return action();
  };
}

// При выборе пункта передаю его значение исходному обработчику.
T Function(A)? withSelectionSound<A, T>(T Function(A)? action) {
  if (action == null) return null;
  return (value) {
    unawaited(AppAudio.shared.click());
    return action(value);
  };
}