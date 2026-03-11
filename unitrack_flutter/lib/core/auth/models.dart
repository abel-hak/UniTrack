class AuthUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String batchId;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.batchId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        batchId: json['batchId'] as String,
      );
}

class AuthState {
  final String? token;
  final AuthUser? user;

  const AuthState({required this.token, required this.user});

  bool get isAuthed => token != null && user != null;

  AuthState copyWith({String? token, AuthUser? user}) =>
      AuthState(token: token ?? this.token, user: user ?? this.user);

  static const signedOut = AuthState(token: null, user: null);
}

class Batch {
  final String id;
  final String name;
  final String semester;
  final int year;

  const Batch({
    required this.id,
    required this.name,
    required this.semester,
    required this.year,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
        id: json['id'] as String,
        name: json['name'] as String,
        semester: json['semester'] as String,
        year: (json['year'] as num).toInt(),
      );

  String get displayName => '$name · $semester $year';
}
