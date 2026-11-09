import 'package:audioplayers/audioplayers.dart'; // Подключаю состояния Android-проигрывателя
import 'package:flutter/material.dart'; // Подключаю настоящие кнопки и навигацию
import 'package:flutter/services.dart'; // Подключаю проверку паузы на стороне Android
import 'package:flutter_test/flutter_test.dart'; // Подключаю проверки интерфейса
import 'package:integration_test/integration_test.dart'; // Подключаю проверку на устройстве
import 'package:romance_club/screens/settings_screen.dart'; // Подключаю настоящий экран настроек
import 'package:romance_club/services/app_audio.dart'; // Подключаю общую музыку и щелчки
import 'package:romance_club/services/storage_service.dart'; // Подключаю сохранение громкости
import 'package:romance_club/widgets/button_sound.dart'; // Подключаю щелчок кнопок

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Два MP3, навигация, громкость и пауза работают на Android', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final original = await StorageService.loadSettings(); // Возвращаю настройки пользователя после проверки
      final backend = AudioPlayersBackend();
      final audio = AppAudio(createBackend: () => backend);
      AppAudio.shared = audio;
      final soundStates = <PlayerState>[];
      final subscription = backend.sound.onPlayerStateChanged.listen(
        soundStates.add,
      );
      try {
        debugPrint('AUDIO_STEP: prepare');
        await audio.initialize().timeout(const Duration(seconds: 30));
        debugPrint('AUDIO_STEP: prepared');
        expect(audio.ready, true);
        expect(audio.error, null);
        await audio.setVolumes(0.4, 0.5);
        final duration = await backend.music.getDuration();
        final clickDuration = await backend.sound.getDuration();
        expect(duration!.inMilliseconds, greaterThan(0));
        expect(clickDuration!.inMilliseconds, greaterThan(0));
        expect(backend.music.releaseMode, ReleaseMode.loop);
        expect(backend.music.state, PlayerState.playing);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: withButtonSound(
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                    child: const Text('Открыть настройки'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        debugPrint('AUDIO_STEP: frame drawn');
        await Future<void>.delayed(const Duration(milliseconds: 500));
        debugPrint('AUDIO_STEP: timer');
        final before = await backend.music.getCurrentPosition();
        final musicId = backend.music.playerId;
        await tester.tap(find.text('Открыть настройки'));
        await tester.pump(const Duration(milliseconds: 500));
        debugPrint('AUDIO_STEP: frame drawn');
        await audio.flush();
        debugPrint('AUDIO_STEP: commands settled');
        final after = await backend.music.getCurrentPosition();
        expect(backend.music.playerId, musicId);
        expect(after!.inMilliseconds, greaterThan(before!.inMilliseconds));
        expect(soundStates, contains(PlayerState.playing));
        expect(backend.music.state, PlayerState.playing);

        await waitFor(
          tester,
          () =>
              find.byType(Slider).evaluate().length == 2 &&
              tester.widget<Slider>(find.byType(Slider).first).onChanged !=
                  null,
        );
        // На настоящем экране проверяю мгновенное отключение обеих громкостей.
        tester.widget<Slider>(find.byType(Slider).first).onChanged!(0);
        tester.widget<Slider>(find.byType(Slider).last).onChanged!(0);
        await tester.pump(const Duration(milliseconds: 500));
        debugPrint('AUDIO_STEP: frame drawn');
        await audio.flush();
        debugPrint('AUDIO_STEP: commands settled');
        expect(backend.music.volume, 0);
        expect(backend.sound.volume, 0);
        expect(backend.music.state, PlayerState.paused);
        final played = soundStates
            .where((s) => s == PlayerState.playing)
            .length;
        await audio.click();
        expect(
          soundStates.where((s) => s == PlayerState.playing).length,
          played,
        );
        await tester.ensureVisible(find.text('сохранить'));
        await tester.tap(find.text('сохранить'));
        await tester.pump(const Duration(milliseconds: 500));
        debugPrint('AUDIO_STEP: frame drawn');
        await waitFor(
          tester,
          () => find.text('Настройки сохранены').evaluate().isNotEmpty,
        );
        final saved = await StorageService.loadSettings();
        expect(saved.musicVolume, 0);
        expect(saved.soundVolume, 0);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pump(const Duration(milliseconds: 500));
        debugPrint('AUDIO_STEP: frame drawn');
        await audio.flush();
        debugPrint('AUDIO_STEP: commands settled');

        // Свернувшийся экран не оставляет звук в фоне, возврат продолжает музыку.
        await audio.setVolumes(0.4, 0.5);
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await audio.setForeground(false);
        expect(backend.music.state, PlayerState.paused);
        final paused = await backend.music.getCurrentPosition();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        final still = await backend.music.getCurrentPosition();
        expect((still! - paused!).inMilliseconds.abs(), lessThan(100));
        await audio.setForeground(true);
        expect(backend.music.state, PlayerState.playing);
        final resumed = await backend.music.getCurrentPosition();
        expect(
          resumed!.inMilliseconds,
          greaterThanOrEqualTo(paused.inMilliseconds - 100),
        );
        expect(audio.error, null);
        // Воспроизвожу зависшую паузу Android при устаревшем состоянии Dart «играет».
        await const MethodChannel('xyz.luan/audioplayers').invokeMethod<void>('pause', {'playerId': backend.music.playerId});
        expect(backend.music.state, PlayerState.playing);
        final stalled = await backend.music.getCurrentPosition();
        await audio.setForeground(true);
        await Future<void>.delayed(const Duration(milliseconds: 350));
        final recovered = await backend.music.getCurrentPosition();
        expect(recovered!.inMilliseconds, greaterThan(stalled!.inMilliseconds + 100));
        debugPrint(
          'AUDIO_CHECK: music=${duration.inMilliseconds}ms, click=${clickDuration.inMilliseconds}ms; navigation, mute, save, pause and resume passed',
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await StorageService.saveSettings(original);
        await subscription.cancel();
        await audio.close();
        AppAudio.shared = AppAudio();
      }
    });
  });
}

// Дожидаюсь конкретного результата, а не окончания всех анимаций Android.
Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Не дождалась результата на экране');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }
}