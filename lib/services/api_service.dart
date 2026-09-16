import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/problem.dart';
import '../models/stats.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiService {
  final String? token;
  final void Function()? onUnauthorized;
  final http.Client client;
  final String baseUrl;
  ApiService(
      {this.token, this.onUnauthorized, http.Client? client, String? baseUrl})
      : client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConstants.baseUrl;
  Future<dynamic> request(String path,
      {String method = 'GET', Map<String, dynamic>? body}) async {
    try {
      final req = http.Request(method, Uri.parse('$baseUrl$path'))
        ..headers.addAll({
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token'
        });
      if (body != null) req.body = jsonEncode(body);
      final response =
          await (() async => http.Response.fromStream(await client.send(req)))()
              .timeout(const Duration(seconds: 15));
      dynamic data;
      try {
        data = response.body.isEmpty ? null : jsonDecode(response.body);
      } catch (_) {
        data = null;
      }
      if (response.statusCode >= 400) {
        if (response.statusCode == 401 && token != null) onUnauthorized?.call();
        throw ApiException(
            data is Map
                ? data['message'] ?? 'Please try again.'
                : 'The server could not complete this request.',
            response.statusCode);
      }
      if (response.statusCode != 204 && data == null) {
        throw const ApiException('The server returned an unreadable response.');
      }
      return data;
    } on TimeoutException {
      throw const ApiException('The server took too long. Please try again.');
    } on http.ClientException {
      throw const ApiException(
          'Cannot reach AnkiDSA. Check your connection and try again.');
    }
  }

  Future<List<Problem>> getAllProblems() async =>
      (await request('/api/problems') as List)
          .map((j) => Problem.fromJson(j))
          .toList();
  Future<Stats> getStats() async => Stats.fromJson(await request('/api/stats'));
  Future<Problem> saveProblem(Map<String, dynamic> data, {int? id}) async =>
      Problem.fromJson(await request(
          id == null ? '/api/problems' : '/api/problems/$id',
          method: id == null ? 'POST' : 'PUT',
          body: data));
  Future<Map<String, dynamic>> submitReview(
          Problem p, int quality, String requestId) async =>
      Map<String, dynamic>.from(
          await request('/api/problems/review', method: 'POST', body: {
        'problemId': p.id,
        'version': p.version,
        'qualityRating': quality,
        'requestId': requestId
      }));
  Future<void> deleteProblem(int id) async {
    await request('/api/problems/$id', method: 'DELETE');
  }

  void dispose() => client.close();
}
