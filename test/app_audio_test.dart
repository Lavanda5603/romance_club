import 'dart:async'; // Подключаю задержку подготовки проигрывателя

import 'package:flutter/material.dart'; // Подключаю кнопки и экраны
import 'package:flutter/services.dart'; // Подключаю клавиатуру
import 'package:flutter_test/flutter_test.dart'; // Подключаю Flutter-тесты
import 'package:romance_club/generated/settings.pb.dart'; // Подключаю настройки громкости
import 'package:romance_club/main.dart'; // Подключаю жизненный цикл приложения
import 'package:romance_club/services/app_audio.dart'; // Подключаю настоящий контроллер звука
import 'package:romance_club/widgets/button_sound.dart'; // Подключаю щелчки кнопок

class _Backend implements AudioBackend {
  int prepared = 0, clicks = 0, paused = 0, closed = 0;
  bool playing = false, fail = false;
  double music = 0, sound = 0;
  Completer<void>? prepareGate;
  @override
  Future<void> prepare() async {
    prepared++;
    await prepareGate?.future;
    if (fail) throw StateError('Не читается MP3');
  }

  @override
  Future<void> volumes(double m, double s) async {
    music = m;
    sound = s;
  }

  @override
  Future<void> musicEnabled(bool enabled) async {
    playing = enabled;
  }

  @override
  Future<void> click() async {
    clicks++;
  }

  @override
  Future<void> pauseAll() async {
    paused++;
    playing = false;
  }

  @override
  Future<void> close() async {
    closed++;
    playing = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Backend backend;
  late AppAudio audio;
  setUp(() {
    backend = _Backend();
    audio = AppAudio(
      createBackend: () => backend,
      loadSettings: () async => Settings(musicVolume: 0.6, soundVolume: 0.3),
    );
    AppAudio.shared = audio;
  });
  tearDown(() {
    unawaited(audio.close());
    AppAudio.shared = AppAudio();
  });

  test('Создаю одну музыку и применяю сохранённую громкость', () async {
    await Future.wait([audio.initialize(), audio.initialize()]);
    expect(backend.prepared, 1);
    expect(backend.playing, true);
    expect(backend.music, 0.6);
    expect(backend.sound, 0.3);
  });
  test('Щелчок не перезапускает музыку', () async {
    await audio.initialize();
    await audio.click();
    await audio.click();
    expect(backend.clicks, 2);
    expect(backend.prepared, 1);
    expect(backend.playing, true);
  });
  test('Нулевая громкость выключает соответствующий звук', () async {
    await audio.initialize();
    await audio.setVolumes(0, 0.4);
    expect(backend.playing, false);
    await audio.click();
    expect(backend.clicks, 1);
    await audio.setVolumes(0.7, 0);
    await audio.click();
    expect(backend.playing, true);
    expect(backend.clicks, 1);
  });
  test('В фоне не играют музыка и отложенные щелчки', () async {
    await audio.initialize();
    final click = audio.click();
    final pause = audio.setForeground(false);
    await Future.wait([click, pause]);
    await audio.click();
    expect(backend.clicks, 0);
    expect(backend.playing, false);
    await audio.setForeground(true);
    expect(backend.playing, true);
    expect(backend.prepared, 1);
  });
  test('Поздняя подготовка не запускает музыку после сворачивания', () async {
    backend.prepareGate = Completer<void>();
    final opening = audio.initialize();
    final pausing = audio.setForeground(false);
    backend.prepareGate!.complete();
    await Future.wait([opening, pausing]);
    expect(backend.playing, false);
  });
  test('Возврат восстанавливает музыку даже при устаревшем состоянии играет', () async {
    await audio.initialize();
    final pauses = backend.paused;
    await audio.setForeground(true);
    expect(backend.paused, pauses + 1);
    expect(backend.playing, true);
    expect(backend.prepared, 1);
    await audio.setVolumes(0.4, 0.5);
    expect(backend.paused, pauses + 1);
    await audio.setVolumes(0, 0.5);
    await audio.setForeground(true);
    expect(backend.playing, false);
  });
  test('При закрытии во время подготовки не включаю музыку', () async {
    backend.prepareGate = Completer<void>();
    final opening = audio.initialize();
    await Future<void>.delayed(Duration.zero);
    final closing = audio.close();
    backend.prepareGate!.complete();
    await Future.wait([opening, closing]);
    expect(backend.playing, false);
    expect(backend.closed, 1);
    await audio.click();
    expect(backend.clicks, 0);
  });
  test('Повреждённый звук не ломает действия приложения', () async {
    backend.fail = true;
    await audio.initialize();
    expect(audio.error, isNotNull);
    var called = false;
    withButtonSound(() {
      called = true;
    })!();
    await audio.flush();
    expect(called, true);
    expect(backend.clicks, 0);
  });
  test('Громкость держу в допустимых пределах', () async {
    await audio.initialize();
    await audio.setVolumes(2, -1);
    expect(backend.music, 1);
    expect(backend.sound, 0);
    await audio.setVolumes(double.nan, double.infinity);
    expect(backend.music, 0);
    expect(backend.sound, 0);
  });
  test(
    'Сохраняю результат и асинхронную работу исходного обработчика',
    () async {
      await audio.initialize();
      expect(await withButtonSound(() async => 7)!(), 7);
      expect(withSelectionSound((int value) => value + 1)!(4), 5);
      await audio.flush();
      expect(backend.clicks, greaterThan(0));
      expect(withButtonSound<void>(null), null);
    },
  );
  testWidgets(
    'Мышь и клавиатура озвучивают кнопку, отключённая кнопка молчит',
    (tester) async {
      backend = _Backend();
      audio = AppAudio(
        createBackend: () => backend,
        loadSettings: () async => Settings(musicVolume: 0.6, soundVolume: 0.3),
      );
      AppAudio.shared = audio;
      await audio.initialize();
      var actions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  autofocus: true,
                  onPressed: withButtonSound(() {
                    actions++;
                  }),
                  child: const Text('Нажать'),
                ),
                ElevatedButton(
                  onPressed: withButtonSound<void>(null),
                  child: const Text('Отключена'),
                ),
                Slider(value: 0.5, onChanged: (_) {}),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Нажать'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(actions, 1);
      expect(backend.clicks, 1);
      await tester.tap(find.text('Отключена'));
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(backend.clicks, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(actions, 2);
      expect(backend.clicks, 2);
      unawaited(audio.close());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('Приложение передаёт сворачивание и возврат проигрывателю', (
    tester,
  ) async {
    backend = _Backend();
    audio = AppAudio(
      createBackend: () => backend,
      loadSettings: () async => Settings(musicVolume: 0.6, soundVolume: 0.3),
    );
    AppAudio.shared = audio;
    await audio.initialize();
    await tester.pumpWidget(const RomanceClubApp());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(backend.playing, false);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(backend.playing, true);
    await tester.pumpWidget(const SizedBox());
  });
}