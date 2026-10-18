import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romance_club/generated/episode.pb.dart';
import 'package:romance_club/screens/programmer_screen.dart';
import 'package:romance_club/src/data/services/episode_grpc_service.dart';

class _PendingService extends EpisodeGrpcService {
  final pending = Completer<List<Episode>>();
  bool closed = false;
  @override
  Future<List<Episode>> getAllEpisodes() => pending.future;
  @override
  Future<void> close() async {
    closed = true;
    await super.close();
  }
}

void main() {
  for (final fails in [false, true]) {
    testWidgets('После закрытия списка игнорирую ${fails ? 'ошибку' : 'ответ'} сервера', (tester) async {
      final service = _PendingService();
      await tester.pumpWidget(MaterialApp(home: ProgrammerScreen(episodeService: service)));
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(service.closed, isTrue);
      if (fails) {
        service.pending.completeError(StateError('Канал закрыт'));
      } else {
        service.pending.complete([Episode(id: 1, title: 'Эпизод')]);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
    });
  }
}
