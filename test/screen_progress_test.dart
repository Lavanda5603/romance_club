import 'package:romance_club/generated/progress.pb.dart' as progress_pb;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romance_club/generated/episode.pb.dart';
import 'package:romance_club/generated/progress_api.pbgrpc.dart';
import 'package:romance_club/screens/episode_select_screen.dart';
import 'package:romance_club/screens/profile_screen.dart';
import 'package:romance_club/screens/game_screen.dart';
import 'package:romance_club/src/data/services/episode_grpc_service.dart';
import 'package:romance_club/src/data/services/progress_grpc_service.dart';
import 'package:romance_club/src/data/repositories/progress_repository_remote.dart';
import 'package:romance_club/src/domain/models/progress_model.dart';
import 'package:romance_club/src/domain/models/auth_model.dart';
import 'package:romance_club/src/domain/models/achievement_model.dart';
import 'package:romance_club/src/domain/repositories/progress_repository.dart';
import 'package:romance_club/src/domain/repositories/auth_repository.dart';
import 'package:romance_club/src/domain/repositories/achievement_repository.dart';

class _Episodes extends EpisodeGrpcService {
  int calls = 0;
  final int count;
  _Episodes(this.count);
  @override
  Future<List<Episode>> getAllEpisodes() async {
    calls++;
    return List.generate(count, (i) => Episode(id: i + 1, title: 'Эпизод ${i + 1}'));
  }
}

class _Progress implements ProgressRepository {
  Completer<Set<int>> pending = Completer<Set<int>>();
  int summaries = 0;
  int singles = 0;
  bool wasReset = false;
  @override
  Future<Set<int>> getProgressSummary(String playerId) {
    summaries++;
    return wasReset ? Future.value(<int>{}) : pending.future;
  }
  @override
  Future<ProgressModel> getProgress(String playerId, int episodeId) async {
    singles++;
    throw StateError('Поэкземплярный запрос на этом экране не нужен');
  }
  @override
  Future<int> saveProgress(ProgressModel progress) async => 1;
  @override
  Future<bool> resetProgress(String playerId) async { wasReset = true; return true; }
}

class _SlowEpisodes extends _Episodes {
  final pending = Completer<List<Episode>>();
  _SlowEpisodes() : super(1);
  @override
  Future<List<Episode>> getAllEpisodes() => pending.future;
}

class _SlowReset extends _Progress {
  int resets = 0;
  final reset = Completer<bool>();
  final refreshed = Completer<Set<int>>();
  final players = <String>[];
  @override
  Future<bool> resetProgress(String playerId) {
    resets++;
    players.add(playerId);
    return reset.future;
  }
  @override
  Future<Set<int>> getProgressSummary(String playerId) {
    summaries++;
    return resets > 0 ? refreshed.future : pending.future;
  }
}

class _CompletionSummary extends _Progress {
  @override
  Future<Set<int>> getProgressSummary(String playerId) async {
    final records = [
      ProgressModel(playerId:playerId, episodeId:1, sceneId:'scene:start', flags:{}, counters:{}),
      ProgressModel(playerId:playerId, episodeId:2, sceneId:'scene:end', completed:true, flags:{}, counters:{}),
    ];
    return records.where((p) => p.completed).map((p) => p.episodeId).toSet();
  }
}

class _RefusedReset extends _Progress {
  final bool throwsError;
  _RefusedReset(this.throwsError);
  @override
  Future<bool> resetProgress(String playerId) async {
    if (throwsError) throw StateError('БД недоступна');
    return false;
  }
}

const player = AuthModel(success: true, message: '', playerId: 'player:test', login: 'tester',
  email: 'test@example.test', createdAt: '', token: '', isAdmin: false);
class _Auth implements AuthRepository {
  int calls = 0;
  final pending = Completer<AuthModel>();
  @override
  Future<AuthModel> getPlayer(String playerId) { calls++; return pending.future; }
  @override
  Future<AuthModel> login({required String login, required String password}) async => player;
  @override
  Future<AuthModel> register({required String login, required String email, required String password}) async => player;
}
class _Achievements implements AchievementRepository {
  int calls = 0;
  final pending = Completer<List<AchievementModel>>();
  @override
  Future<List<AchievementModel>> getAchievements(String playerId) { calls++; return pending.future; }
  @override
  Future<bool> unlockAchievement(String playerId, String name) async => true;
}
class _Observer extends NavigatorObserver {
  Route<dynamic>? route;
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) { pushes++; this.route = route; }
}
class _SummaryService extends ProgressGrpcService {
  int calls = 0;
  @override
  Future<GetProgressSummaryResponse> getProgressSummary(String playerId) async {
    calls++;
    return GetProgressSummaryResponse(episodeIds: [2, 1, 2]);
  }
}

void main() {
  ElevatedButton control(WidgetTester tester, String label) =>
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, label));

  testWidgets('Отмена сброса возвращает кнопки и не отправляет запрос', (tester) async {
    final episodes = _Episodes(1);
    addTearDown(episodes.close);
    final progress = _SlowReset()..pending.complete({});
    await tester.pumpWidget(MaterialApp(home: EpisodeSelectScreen(
      episodeService:episodes,progressRepository:progress,loadPlayerId:()async=>'player:test')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('сбросить\nпрогресс'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(progress.resets,0);
    expect(control(tester,'продолжить').onPressed,isNotNull);
    expect(control(tester,'сбросить\nпрогресс').onPressed,isNotNull);
  });

  testWidgets('Двойное нажатие запускает только один игровой экран', (tester) async {
    final episodes = _Episodes(1);
    addTearDown(episodes.close);
    final progress = _Progress()..pending.complete({});
    final observer = _Observer();
    await tester.pumpWidget(MaterialApp(navigatorObservers:[observer],home: EpisodeSelectScreen(
      episodeService:episodes,progressRepository:progress,loadPlayerId:()async=>'player:test')));
    await tester.pumpAndSettle();
    final start = control(tester,'продолжить').onPressed!;
    start();
    start();
    expect(observer.pushes,2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Не запускаю игру и сброс до загрузки игрока и эпизодов', (tester) async {
    final episodes = _SlowEpisodes();
    addTearDown(episodes.close);
    final playerId = Completer<String>();
    final progress = _SlowReset();
    await tester.pumpWidget(MaterialApp(home: EpisodeSelectScreen(
      episodeService:episodes, progressRepository:progress, loadPlayerId:()=>playerId.future)));
    await tester.pump();
    expect(control(tester,'продолжить').onPressed,isNull);
    expect(control(tester,'сбросить\nпрогресс').onPressed,isNull);
    playerId.complete('player:test');
    await tester.pump();
    expect(control(tester,'сбросить\nпрогресс').onPressed,isNull);
    episodes.pending.complete([Episode(id:1,title:'Эпизод 1')]);
    await tester.pumpAndSettle();
    expect(control(tester,'продолжить').onPressed,isNotNull);
    expect(control(tester,'сбросить\nпрогресс').onPressed,isNotNull);
    expect(progress.resets,0);
  });

  testWidgets('Сброс блокирует повтор, игру и выбор до свежей сводки', (tester) async {
    final episodes = _Episodes(3);
    addTearDown(episodes.close);
    final progress = _SlowReset();
    await tester.pumpWidget(MaterialApp(home: EpisodeSelectScreen(
      episodeService:episodes, progressRepository:progress, loadPlayerId:()async=>'player:test')));
    await tester.pumpAndSettle();
    final reset = control(tester,'сбросить\nпрогресс').onPressed!;
    reset();
    reset();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog),findsOneWidget);
    await tester.tap(find.text('Сбросить'));
    await tester.pumpAndSettle();
    expect(progress.resets,1);
    expect(progress.players,['player:test']);
    expect(control(tester,'сбросить\nпрогресс').onPressed,isNull);
    expect(control(tester,'продолжить').onPressed,isNull);
    expect(control(tester,'Эпизод 1').onPressed,isNull);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton,Icons.arrow_back)).onPressed,isNull);
    final pop = tester.widget<PopScope>(find.byWidgetPredicate((widget) => widget is PopScope));
    expect(pop.canPop,isFalse);
    progress.pending.complete({1,2});
    await tester.pumpAndSettle();
    progress.reset.complete(true);
    await tester.pumpAndSettle();
    expect(control(tester,'продолжить').onPressed,isNull);
    progress.refreshed.complete({});
    await tester.pumpAndSettle();
    expect(control(tester,'продолжить').onPressed,isNotNull);
    expect(control(tester,'сбросить\nпрогресс').onPressed,isNotNull);
    expect(control(tester,'Эпизод 1').style!.backgroundColor!.resolve({}),const Color(0xFF534F50));
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton,Icons.arrow_back)).onPressed,isNotNull);
    expect(find.text('Прогресс сброшен'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  for(final id in ['', 'wrong', 'player:', 'player: ', '   ']) {
    testWidgets('Не отправляю сброс с неверным ID: $id', (tester) async {
      final episodes = _Episodes(1);
      addTearDown(episodes.close);
      final progress = _SlowReset();
      await tester.pumpWidget(MaterialApp(home: EpisodeSelectScreen(
        episodeService:episodes,progressRepository:progress,loadPlayerId:()async=>id)));
      await tester.pumpAndSettle();
      expect(control(tester,'сбросить\nпрогресс').onPressed,isNull);
      expect(control(tester,'продолжить').onPressed,isNull);
      expect(progress.resets,0);
      expect(progress.summaries,0);
    });
  }
  test('Поле completed сохраняется при преобразовании прогресса', () {
    final service = ProgressGrpcService();
    addTearDown(service.close);
    final repo = ProgressRepositoryRemote(service);
    expect(repo.toDomain(progress_pb.Progress(sceneId:'scene:start')).completed, isFalse);
    expect(repo.toDomain(progress_pb.Progress(sceneId:'scene:end', completed:true)).completed, isTrue);
  });
  testWidgets('Начатый эпизод не отмечаю пройденным и не считаю в профиле', (tester) async {
    final episodes = _Episodes(3);
    addTearDown(episodes.close);
    final progress = _CompletionSummary();
    await tester.pumpWidget(MaterialApp(home: EpisodeSelectScreen(
      episodeService:episodes, progressRepository:progress, loadPlayerId:() async => 'player:test')));
    await tester.pumpAndSettle();
    for (final id in [1, 2]) {
      final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Эпизод $id'));
      expect(button.style!.backgroundColor!.resolve({}), Color(id == 1 ? 0xFF534F50 : 0xFFD30010));
    }
    final auth = _Auth()..pending.complete(player);
    final achievements = _Achievements()..pending.complete([]);
    await tester.pumpWidget(MaterialApp(home: ProfileScreen(episodeService:episodes,
      progressRepository:progress, authRepository:auth, achievementRepository:achievements,
      loadPlayerId:() async => 'player:test')));
    await tester.pumpAndSettle();
    expect(find.text('пройдено эпизодов: 1/3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final throwsError in [false, true]) {
    testWidgets('Отказ сброса сохраняет отметки: ошибка=$throwsError', (tester) async {
      final episodes = _Episodes(3);
      addTearDown(episodes.close);
      final progress = _RefusedReset(throwsError)..pending.complete({1});
      await tester.pumpWidget(MaterialApp(home: EpisodeSelectScreen(
        episodeService: episodes, progressRepository: progress, loadPlayerId: () async => 'player:test')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('сбросить\nпрогресс'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сбросить'));
      await tester.pumpAndSettle();
      final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Эпизод 1'));
      expect(button.style!.backgroundColor!.resolve({}), const Color(0xFFD30010));
      expect(find.text('Прогресс сброшен'), findsNothing);
      expect(control(tester,'сбросить\nпрогресс').onPressed,isNotNull);
      expect(control(tester,'продолжить').onPressed,isNotNull);
      expect(find.textContaining('Ошибка:'), findsOneWidget);
      expect(progress.summaries, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('50 эпизодов видны до сводки, запрос прогресса только один', (tester) async {
    final episodes = _Episodes(50);
    addTearDown(episodes.close);
    final progress = _Progress();
    await tester.pumpWidget(MaterialApp(home: EpisodeSelectScreen(
      episodeService: episodes, progressRepository: progress, loadPlayerId: () async => 'player:test',
    )));
    await tester.pumpAndSettle();
    expect(find.text('Эпизод 1'), findsOneWidget);
    expect(find.text('Статус эпизодов загружается...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(progress.summaries, 1);
    expect(progress.singles, 0);
    progress.pending.complete({1, 2});
    await tester.pumpAndSettle();
    expect(find.text('Статус эпизодов загружается...'), findsNothing);
    expect(progress.singles, 0);
  });

  testWidgets('Ошибка сводки не скрывает список, повтор не вызывает N запросов', (tester) async {
    final episodes = _Episodes(50);
    addTearDown(episodes.close);
    final progress = _Progress();
    await tester.pumpWidget(MaterialApp(home: EpisodeSelectScreen(
      episodeService: episodes, progressRepository: progress, loadPlayerId: () async => 'player:test',
    )));
    await tester.pumpAndSettle();
    progress.pending.completeError(StateError('Нет связи'));
    await tester.pumpAndSettle();
    expect(find.text('Эпизод 1'), findsOneWidget);
    expect(find.textContaining('Повторить'), findsOneWidget);
    progress.pending = Completer<Set<int>>();
    await tester.tap(find.textContaining('Повторить'));
    await tester.pump();
    progress.pending.complete({1});
    await tester.pumpAndSettle();
    expect(progress.summaries, 2);
    expect(progress.singles, 0);
  });

  testWidgets('Поздняя сводка не меняет выбранный пользователем эпизод', (tester) async {
    final episodes = _Episodes(3);
    addTearDown(episodes.close);
    final progress = _Progress();
    final observer = _Observer();
    await tester.pumpWidget(MaterialApp(navigatorObservers: [observer], home: EpisodeSelectScreen(
      episodeService: episodes, progressRepository: progress, loadPlayerId: () async => 'player:test',
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Эпизод 3'));
    progress.pending.complete({1});
    await tester.pumpAndSettle();
    await tester.tap(find.text('продолжить'));
    final route = observer.route! as MaterialPageRoute;
    final game = route.builder(tester.element(find.byType(EpisodeSelectScreen))) as GameScreen;
    expect(game.episode.id, 3);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Профиль показывает игрока, пока прогресс и достижения ещё загружаются', (tester) async {
    final episodes = _Episodes(50);
    addTearDown(episodes.close);
    final progress = _Progress();
    final auth = _Auth();
    final achievements = _Achievements();
    await tester.pumpWidget(MaterialApp(home: ProfileScreen(
      episodeService: episodes, progressRepository: progress, authRepository: auth,
      achievementRepository: achievements, loadPlayerId: () async => 'player:test',
    )));
    await tester.pump();
    expect(auth.calls, 1);
    expect(episodes.calls, 1);
    expect(progress.summaries, 1);
    expect(achievements.calls, 1);
    auth.pending.complete(player);
    await tester.pumpAndSettle();
    expect(find.text('tester'), findsOneWidget);
    expect(find.text('Прогресс загружается...'), findsOneWidget);
    expect(find.text('Достижения загружаются...'), findsOneWidget);
    expect(find.textContaining('пройдено эпизодов:'), findsNothing);
    progress.pending.complete({1, 2, 999});
    achievements.pending.complete([const AchievementModel(name: 'max_points', unlockedAt: '2026-10-18')]);
    await tester.pumpAndSettle();
    expect(find.text('пройдено эпизодов: 2/50'), findsOneWidget);
    expect(progress.singles, 0);
    expect(find.byIcon(Icons.diamond), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Старая сводка не возвращает отметки после сброса прогресса', (tester) async {
    final episodes = _Episodes(3);
    addTearDown(episodes.close);
    final progress = _Progress();
    await tester.pumpWidget(MaterialApp(home: EpisodeSelectScreen(
      episodeService: episodes, progressRepository: progress, loadPlayerId: () async => 'player:test',
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('сбросить\nпрогресс'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сбросить'));
    await tester.pumpAndSettle();
    progress.pending.complete({1, 2});
    await tester.pumpAndSettle();
    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Эпизод 1'));
    expect(button.style!.backgroundColor!.resolve({}), const Color(0xFF534F50));
    expect(find.text('Статус эпизодов загружается...'), findsNothing);
    expect(progress.singles, 0);
    expect(progress.summaries, 2);
    expect(find.text('Прогресс сброшен'), findsOneWidget);
  });

  testWidgets('Ошибка необязательных данных не скрывает профиль и не выдаёт ложный ноль', (tester) async {
    final episodes = _Episodes(50);
    addTearDown(episodes.close);
    final progress = _Progress();
    final auth = _Auth()..pending.complete(player);
    final achievements = _Achievements();
    await tester.pumpWidget(MaterialApp(home: ProfileScreen(
      episodeService: episodes, progressRepository: progress, authRepository: auth,
      achievementRepository: achievements, loadPlayerId: () async => 'player:test',
    )));
    await tester.pumpAndSettle();
    progress.pending.completeError(StateError('Нет связи'));
    achievements.pending.completeError(StateError('Нет связи'));
    await tester.pumpAndSettle();
    expect(find.text('tester'), findsOneWidget);
    expect(find.text('Не удалось загрузить прогресс'), findsOneWidget);
    expect(find.text('Не удалось загрузить достижения'), findsOneWidget);
    expect(find.textContaining('пройдено эпизодов:'), findsNothing);
    expect(progress.singles, 0);
    expect(tester.takeException(), isNull);
  });

  test('Репозиторий получает сводку одним RPC и убирает повторяющиеся ID', () async {
    final service = _SummaryService();
    addTearDown(service.close);
    final summary = await ProgressRepositoryRemote(service).getProgressSummary('player:test');
    expect(summary, {1, 2});
    expect(service.calls, 1);
    expect(() => summary.add(3), throwsUnsupportedError);
  });
}
