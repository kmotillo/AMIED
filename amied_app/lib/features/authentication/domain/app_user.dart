class AppUser {
  final String uid;
  final String email;
  final String nombres;
  final String apellidos;
  final String role; // 'admin' o 'docente'

  AppUser({
    required this.uid,
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['id'] ?? '',
      email: data['email'] ?? '',
      nombres: data['nombres'] ?? '',
      apellidos: data['apellidos'] ?? '',
      role: data['role'] ?? 'docente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'email': email,
      'nombres': nombres,
      'apellidos': apellidos,
      'role': role,
    };
  }
}
