import 'dart:async'; // Подключаю очередь команд и сообщения об ошибках

import 'package:audioplayers/audioplayers.dart'; // Подключаю проигрывание MP3
import 'package:flutter/foundation.dart'; // Подключаю сообщения для отладки

import '../generated/settings.pb.dart'; // Подключаю настройки громкости
import 'storage_service.dart'; // Подключаю сохранённые настройки

// Отделяю проигрыватель от логики, чтобы проверять её без настоящих динамиков.
abstract class AudioBackend {
  Future<void> prepare();
  Future<void> volumes(double music, double sound);
  Future<void> musicEnabled(bool enabled);
  Future<void> click();
  Future<void> pauseAll();
  Future<void> close();
}

// Одну музыку и один короткий эффект держу в разных проигрывателях.
class AudioPlayersBackend implements AudioBackend {
  final music = AudioPlayer(); // Общая музыка приложения
  final sound = AudioPlayer(); // Щелчок кнопки

  @override
  Future<void> prepare() async {
    await music.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.gain),
      ),
    );
    // Щелчок не запрашивает новый фокус и не останавливает музыку.
    await sound.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      ),
    );
    await music.setReleaseMode(ReleaseMode.loop);
    await sound.setReleaseMode(ReleaseMode.stop);
    await music.setSource(AssetSource('audio/background_music.mp3'));
    await sound.setSource(AssetSource('audio/button_click.mp3'));
  }

  @override
  Future<void> volumes(double musicVolume, double soundVolume) async {
    await music.setVolume(musicVolume);
    await sound.setVolume(soundVolume);
  }

  @override
  Future<void> musicEnabled(bool enabled) async {
    if (enabled && music.state != PlayerState.playing) {
      await music.resume(); // Продолжаю с прежнего места
    } else if (!enabled && music.state == PlayerState.playing) {
      await music.pause();
    }
  }

  @override
  Future<void> click() async {
    await sound.seek(Duration.zero);
    await sound.resume();
  }

  @override
  Future<void> pauseAll() async {
    await musicEnabled(false);
    await sound.stop();
  }

  @override
  Future<void> close() async {
    try {
      await music.dispose();
    } finally {
      await sound.dispose();
    }
  }
}

// Управляю звуком всего приложения, а не отдельного экрана.
class AppAudio {
  static AppAudio shared = AppAudio();
  final AudioBackend Function() _createBackend;
  final Future<Settings> Function() _loadSettings;
  final _errors = StreamController<String>.broadcast();
  AudioBackend? _backend;
  Future<void>? _initializing;
  Future<void> _queue = Future.value();
  Future<void>? _closing;
  bool _closed = false;
  bool _prepared = false;
  bool _foreground = true;
  int _clickRequest = 0;
  double musicVolume = 0.6;
  double soundVolume = 0.3;
  String? error;
  bool get ready => _prepared && !_closed;
  Stream<String> get errors => _errors.stream;

  AppAudio({
    AudioBackend Function()? createBackend,
    Future<Settings> Function()? loadSettings,
  }) : _createBackend = createBackend ?? AudioPlayersBackend.new,
       _loadSettings = loadSettings ?? StorageService.loadSettings;

  // Повторное обращение не создаёт ещё одну музыку.
  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    try {
      final settings = await _loadSettings();
      if (_closed) return;
      musicVolume = _volume(settings.musicVolume);
      soundVolume = _volume(settings.soundVolume);
      _backend = _createBackend();
      await _backend!.prepare();
      _prepared = true;
      if (_closed) return;
      await _apply();
    } catch (problem) {
      _report(problem);
    }
  }

  double _volume(double value) => value.isFinite ? value.clamp(0.0, 1.0) : 0.0;

  void _report(Object problem) {
    if (_closed) return;
    error = 'Не удалось включить звук';
    debugPrint('$error: $problem');
    _errors.add(error!);
  }

  // Все команды проходят по очереди: поздний щелчок не возобновит звук в фоне.
  Future<void> _command(Future<void> Function(AudioBackend) action) {
    if (_closed || _initializing == null) return Future.value();
    _queue = _queue.then((_) async {
      await _initializing;
      if (_closed || !ready) return;
      try {
        await action(_backend!);
        error = null;
      } catch (problem) {
        _report(problem);
      }
    });
    return _queue;
  }

  Future<void> _apply() async {
    await _backend!.volumes(musicVolume, soundVolume);
    if (_foreground) {
      await _backend!.musicEnabled(musicVolume > 0);
    } else {
      await _backend!.pauseAll();
    }
  }

  Future<void> setVolumes(double music, double sound) {
    musicVolume = _volume(music);
    soundVolume = _volume(sound);
    return _command((_) => _apply());
  }

  Future<void> setForeground(bool foreground) {
    _foreground = foreground;
    _clickRequest++;
    return _command((backend) async {
      // После возврата сбрасываю устаревшее «играет», если Android потерял аудиофокус.
      if (foreground && _foreground) await backend.pauseAll();
      await _apply(); // Продолжаю с прежней позиции и сохранённой громкостью
    });
  }

  Future<void> click() {
    final request = ++_clickRequest;
    return _command((backend) async {
      if (!_foreground || soundVolume == 0 || request != _clickRequest) return;
      await backend.click();
    });
  }

  Future<void> flush() => _queue;

  // Закрываю оба проигрывателя только вместе с приложением.
  Future<void> close() => _closing ??= _close();
  Future<void> _close() async {
    _closed = true;
    await _initializing;
    await _queue;
    try {
      await _backend?.close();
    } catch (problem) {
      debugPrint('Не удалось закрыть звук: $problem');
    } finally {
      _backend = null;
      _prepared = false;
      await _errors.close();
    }
  }
}