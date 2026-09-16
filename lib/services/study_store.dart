import 'package:flutter/foundation.dart';
import '../models/problem.dart';
import '../models/stats.dart';
import 'api_service.dart';
import 'auth_service.dart';

class StudyStore extends ChangeNotifier {
  final ApiService Function(String token, VoidCallback expired)? apiFactory;
  StudyStore({this.apiFactory});
  ApiService? _api;
  Future<void>? _activeLoad;
  String? _token;
  int _generation = 0;
  bool loading = false;
  String? error;
  List<Problem> problems = [];
  Stats? stats;
  List<Problem> get queue {
    final today =
        stats?.today ?? DateTime.now().toIso8601String().substring(0, 10);
    return problems
        .where((p) => p.nextReviewDate.compareTo(today) <= 0)
        .toList()
      ..sort((a, b) {
        final d = a.nextReviewDate.compareTo(b.nextReviewDate);
        return d == 0 ? a.id.compareTo(b.id) : d;
      });
  }

  void attach(AuthService auth) {
    if (_token == auth.token) return;
    _token = auth.token;
    _generation++;
    _activeLoad = null;
    _api?.dispose();
    _api = null;
    problems = [];
    stats = null;
    error = null;
    loading = false;
    if (_token != null) {
      final currentToken = _token!;
      void expire() {
        if (_token == currentToken) auth.expire();
      }

      _api = apiFactory?.call(currentToken, expire) ??
          ApiService(token: currentToken, onUnauthorized: expire);
      Future.microtask(refresh);
    }
  }

  Future<void> refresh({bool silent = false, bool force = false}) async {
    final generation = _generation;
    while (_activeLoad != null) {
      await _activeLoad;
      if (!force || generation != _generation) return;
    }
    if (_api == null) return;
    final task = _load(silent);
    _activeLoad = task;
    try {
      await task;
    } finally {
      if (identical(_activeLoad, task)) _activeLoad = null;
    }
  }

  Future<void> _load(bool silent) async {
    final generation = _generation, api = _api!;
    loading = true;
    if (!silent) error = null;
    notifyListeners();
    try {
      final results =
          await Future.wait<dynamic>([api.getAllProblems(), api.getStats()]);
      if (generation != _generation) return;
      problems = results[0] as List<Problem>;
      stats = results[1] as Stats;
      error = null;
    } catch (e) {
      if (generation == _generation) error = e.toString();
    } finally {
      if (generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> save(Map<String, dynamic> data, {int? id}) async {
    final generation = _generation;
    final p = await _api!.saveProblem(data, id: id);
    if (generation != _generation) {
      throw const ApiException('Your account changed. Sign in again.');
    }
    problems = [...problems.where((item) => item.id != p.id), p];
    notifyListeners();
    await refresh(force: true);
  }

  Future<Map<String, dynamic>> review(
      Problem p, int quality, String requestId) async {
    try {
      final result = await _api!.submitReview(p, quality, requestId);
      await refresh(force: true);
      return result;
    } on ApiException catch (e) {
      if (e.status == 409) await refresh(force: true);
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    final generation = _generation;
    await _api!.deleteProblem(id);
    if (generation != _generation) {
      throw const ApiException('Your account changed. Sign in again.');
    }
    problems.removeWhere((p) => p.id == id);
    notifyListeners();
    await refresh(force: true);
  }

  @override
  void dispose() {
    _generation++;
    _api?.dispose();
    super.dispose();
  }
}
