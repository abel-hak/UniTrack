import '../courses/models.dart';

class TimelineAnnouncement {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String authorName;

  const TimelineAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.authorName,
  });

  factory TimelineAnnouncement.fromJson(Map<String, dynamic> json) =>
      TimelineAnnouncement(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        authorName: (json['author'] as Map<String, dynamic>)['name'] as String,
      );
}

class TimelineAssignment {
  final String id;
  final String title;
  final String type;
  final int? weight;
  final DateTime dueAt;
  final String status;
  final int? gradePct;
  final Course course;

  const TimelineAssignment({
    required this.id,
    required this.title,
    required this.type,
    required this.weight,
    required this.dueAt,
    required this.status,
    required this.gradePct,
    required this.course,
  });

  factory TimelineAssignment.fromJson(Map<String, dynamic> json) =>
      TimelineAssignment(
        id: json['id'] as String,
        title: json['title'] as String,
        type: json['type'] as String,
        weight: (json['weight'] as num?)?.toInt(),
        dueAt: DateTime.parse(json['dueAt'] as String),
        status: json['status'] as String,
        gradePct: (json['gradePct'] as num?)?.toInt(),
        course: Course.fromJson(json['course'] as Map<String, dynamic>),
      );
}

class TimelineBundle {
  final List<TimelineAssignment> assignments;
  final List<TimelineAnnouncement> announcements;

  const TimelineBundle({required this.assignments, required this.announcements});
}

