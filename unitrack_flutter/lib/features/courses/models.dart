class Course {
  final String id;
  final String code;
  final String title;
  final int credits;
  final String colorKey;

  const Course({
    required this.id,
    required this.code,
    required this.title,
    required this.credits,
    required this.colorKey,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        code: json['code'] as String,
        title: json['title'] as String,
        credits: (json['credits'] as num).toInt(),
        colorKey: json['colorKey'] as String,
      );
}

