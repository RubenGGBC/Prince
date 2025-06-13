// ✅ Sin imports circulares - User no necesita conocer DatabaseHelper

class User {
  final String email;
  final String password;
  final DateTime createdAt;

  User({
    required this.email,
    required this.password,
    required this.createdAt,
  });

  // 📝 Método para convertir el objeto a Map (para guardar en base de datos)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // 📝 Método para crear objeto desde Map (para leer de base de datos)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // 📝 Método para crear una copia modificada del objeto
  User copyWith({
    String? email,
    String? password,
    DateTime? createdAt,
  }) {
    return User(
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // 📝 Método toString para debugging
  @override
  String toString() {
    return 'User(email: $email, createdAt: $createdAt)';
  }

  // 📝 Operadores de igualdad
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.email == email;
  }

  @override
  int get hashCode => email.hashCode;
}