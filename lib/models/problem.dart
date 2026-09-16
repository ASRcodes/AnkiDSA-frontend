class Problem {
  final int id, version, interval, repetitions;
  final String leetcodeUrl, title, difficulty, nextReviewDate, status;
  final List<String> tags;
  final String? notes, createdAt;
  final double easinessFactor;
  const Problem(
      {required this.id,
      required this.version,
      required this.leetcodeUrl,
      required this.title,
      required this.difficulty,
      required this.tags,
      this.notes,
      required this.easinessFactor,
      required this.interval,
      required this.repetitions,
      required this.nextReviewDate,
      required this.status,
      this.createdAt});
  factory Problem.fromJson(Map<String, dynamic> j) => Problem(
      id: (j['id'] as num).toInt(),
      version: (j['version'] as num?)?.toInt() ?? 0,
      leetcodeUrl: j['leetcodeUrl'] ?? '',
      title: j['title'] ?? '',
      difficulty: j['difficulty'] ?? 'MEDIUM',
      tags: List<String>.from(j['tags'] ?? []),
      notes: j['notes'],
      easinessFactor: (j['easinessFactor'] as num?)?.toDouble() ?? 2.5,
      interval: (j['interval'] as num?)?.toInt() ?? 0,
      repetitions: (j['repetitions'] as num?)?.toInt() ?? 0,
      nextReviewDate: j['nextReviewDate'] ?? '',
      status: j['status'] ?? 'NEW',
      createdAt: j['createdAt']);
  String get statusLabel => switch (status) {
        'NEW' => 'New',
        'LEARNING' => 'Learning',
        'REVIEW' => 'Revisiting',
        'MASTERED' => 'Mastered',
        _ => status
      };
  String get difficultyLabel =>
      difficulty[0] + difficulty.substring(1).toLowerCase();
}
