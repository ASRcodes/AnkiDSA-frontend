class Stats {
  final int totalProblems,
      easyCount,
      mediumCount,
      hardCount,
      dueToday,
      overdueCount,
      masteredCount,
      learningCount,
      totalReviews,
      reviewsToday,
      streak;
  final double? averageQuality, retentionRate;
  final Map<String, int> activity;
  final String today;
  Stats.fromJson(Map<String, dynamic> j)
      : totalProblems = j['totalProblems'] ?? 0,
        easyCount = j['easyCount'] ?? 0,
        mediumCount = j['mediumCount'] ?? 0,
        hardCount = j['hardCount'] ?? 0,
        dueToday = j['dueToday'] ?? 0,
        overdueCount = j['overdueCount'] ?? 0,
        masteredCount = j['masteredCount'] ?? 0,
        learningCount = j['learningCount'] ?? 0,
        totalReviews = j['totalReviews'] ?? 0,
        reviewsToday = j['reviewsToday'] ?? 0,
        streak = j['streak'] ?? 0,
        averageQuality = (j['averageQuality'] as num?)?.toDouble(),
        retentionRate = (j['retentionRate'] as num?)?.toDouble(),
        today = j['today'] ?? DateTime.now().toIso8601String().substring(0, 10),
        activity = Map<String, int>.from(j['activity'] ?? {});
}
