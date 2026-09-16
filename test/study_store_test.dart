import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ankidsa/models/problem.dart';
import 'package:ankidsa/models/stats.dart';
import 'package:ankidsa/services/api_service.dart';
import 'package:ankidsa/services/auth_service.dart';
import 'package:ankidsa/services/study_store.dart';

class DelayedApi extends ApiService {
  final first = Completer<void>();
  int reads = 0;
  final saved = Problem.fromJson({
    'id': 1,
    'version': 0,
    'title': 'Two Sum',
    'difficulty': 'EASY',
    'nextReviewDate': '2026-09-16'
  });
  @override
  Future<List<Problem>> getAllProblems() async {
    reads++;
    if (reads == 1) {
      await first.future;
      return [];
    }
    return [saved];
  }

  @override
  Future<Stats> getStats() async =>
      Stats.fromJson({'today': '2026-09-16', 'totalProblems': 1});
  @override
  Future<Problem> saveProblem(Map<String, dynamic> data, {int? id}) async =>
      saved;
}

void main() {
  test(
      'an older in-flight refresh cannot leave a newly saved problem invisible',
      () async {
    final api = DelayedApi(), auth = AuthService()..token = 'session';
    final store = StudyStore(apiFactory: (_, __) => api)..attach(auth);
    await Future<void>.delayed(Duration.zero);
    final save = store.save({'title': 'Two Sum'});
    api.first.complete();
    await save;
    expect(api.reads, 2);
    expect(store.problems.single.title, 'Two Sum');
    store.dispose();
    auth.dispose();
  });
  test('an old account response cannot repopulate a signed-out collection',
      () async {
    final api = DelayedApi(), auth = AuthService()..token = 'session';
    final store = StudyStore(apiFactory: (_, __) => api)..attach(auth);
    await Future<void>.delayed(Duration.zero);
    auth.token = null;
    store.attach(auth);
    api.first.complete();
    await Future<void>.delayed(Duration.zero);
    expect(store.problems, isEmpty);
    expect(store.stats, isNull);
    store.dispose();
    auth.dispose();
  });
}
