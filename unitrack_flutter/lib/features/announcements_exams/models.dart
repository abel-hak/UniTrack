import '../courses/models.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String authorName;
  final String authorRole;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.authorName,
    required this.authorRole,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        authorName:
            (json['author'] as Map<String, dynamic>)['name'] as String? ?? '',
        authorRole:
            (json['author'] as Map<String, dynamic>)['role'] as String? ?? '',
      );
}

class Exam {
  final String id;
  final String kind;
  final DateTime startsAt;
  final String? location;
  final String? notes;
  final Course course;

  Exam({
    required this.id,
    required this.kind,
    required this.startsAt,
    required this.location,
    required this.notes,
    required this.course,
  });

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'] as String,
        kind: json['kind'] as String,
        startsAt: DateTime.parse(json['startsAt'] as String),
        location: json['location'] as String?,
        notes: json['notes'] as String?,
        course: Course.fromJson(json['course'] as Map<String, dynamic>),
      );
}

