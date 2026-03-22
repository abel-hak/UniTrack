class AnalyticsCourse {
  final String courseId;
  final String code;
  final String title;
  final int credits;
  final String colorKey;
  final double? average;
  final String? letterGrade;
  final double? gpaPoints;
  final int gradedCount;
  final int totalCount;
  final int earnedWeight;
  final int totalWeight;

  const AnalyticsCourse({
    required this.courseId,
    required this.code,
    required this.title,
    required this.credits,
    required this.colorKey,
    required this.average,
    required this.letterGrade,
    required this.gpaPoints,
    required this.gradedCount,
    required this.totalCount,
    required this.earnedWeight,
    required this.totalWeight,
  });

  factory AnalyticsCourse.fromJson(Map<String, dynamic> json) =>
      AnalyticsCourse(
        courseId: json['courseId'] as String,
        code: json['code'] as String,
        title: json['title'] as String,
        credits: (json['credits'] as num).toInt(),
        colorKey: json['colorKey'] as String,
        average: (json['average'] as num?)?.toDouble(),
        letterGrade: json['letterGrade'] as String?,
        gpaPoints: (json['gpaPoints'] as num?)?.toDouble(),
        gradedCount: (json['gradedCount'] as num).toInt(),
        totalCount: (json['totalCount'] as num).toInt(),
        earnedWeight: (json['earnedWeight'] as num).toInt(),
        totalWeight: (json['totalWeight'] as num).toInt(),
      );
}

class AnalyticsOverview {
  final double? gpa;
  final int totalCredits;
  final int gradedCredits;
  final List<AnalyticsCourse> courses;

  const AnalyticsOverview({
    required this.gpa,
    required this.totalCredits,
    required this.gradedCredits,
    required this.courses,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) =>
      AnalyticsOverview(
        gpa: (json['gpa'] as num?)?.toDouble(),
        totalCredits: (json['totalCredits'] as num).toInt(),
        gradedCredits: (json['gradedCredits'] as num).toInt(),
        courses: (json['courses'] as List)
            .cast<Map<String, dynamic>>()
            .map(AnalyticsCourse.fromJson)
            .toList(),
      );
}

class TrendPoint {
  final DateTime date;
  final double gpa;
  final String label;
  final int pct;

  const TrendPoint({
    required this.date,
    required this.gpa,
    required this.label,
    required this.pct,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
        date: DateTime.parse(json['date'] as String),
        gpa: (json['gpa'] as num).toDouble(),
        label: json['label'] as String,
        pct: (json['pct'] as num).toInt(),
      );
}

class TargetResult {
  final String courseCode;
  final double? currentAverage;
  final double targetPct;
  final int ungradedCount;
  final double? requiredPct;
  final bool achievable;

  const TargetResult({
    required this.courseCode,
    required this.currentAverage,
    required this.targetPct,
    required this.ungradedCount,
    required this.requiredPct,
    required this.achievable,
  });

  factory TargetResult.fromJson(Map<String, dynamic> json) => TargetResult(
        courseCode: json['courseCode'] as String,
        currentAverage: (json['currentAverage'] as num?)?.toDouble(),
        targetPct: (json['targetPct'] as num).toDouble(),
        ungradedCount: (json['ungradedCount'] as num).toInt(),
        requiredPct: (json['requiredPct'] as num?)?.toDouble(),
        achievable: json['achievable'] as bool,
      );
}

class GpaProjection {
  final double? current;
  final double? optimistic;
  final double? pessimistic;

  const GpaProjection({
    required this.current,
    required this.optimistic,
    required this.pessimistic,
  });

  factory GpaProjection.fromJson(Map<String, dynamic> json) => GpaProjection(
        current: (json['current'] as num?)?.toDouble(),
        optimistic: (json['optimistic'] as num?)?.toDouble(),
        pessimistic: (json['pessimistic'] as num?)?.toDouble(),
      );
}
