// ✅ Sin imports circulares - User no necesita conocer DatabaseHelper


class User {
  final String email;
  final String password;
  final DateTime createdAt;
  final String genre;
  final String name;
  double weight;
  double height;
  int age;

  User({
    required this.email,
    required this.password,
    required this.createdAt,
    required this.genre,
    required this.name,
    required this.weight,
    required this.height,
    required this.age,
  });

  // 📝 Método para convertir el objeto a Map (para guardar en base de datos)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'created_at': createdAt.toIso8601String(),
      'genre': genre,
      'name': name,
      'weight': weight,
      'height': height,
      'age': age,
    };
  }

  // 📝 Método para crear objeto desde Map (para leer de base de datos)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      genre: map['genre'] ?? '',
      name: map['name'] ?? '',
      weight: map['weight']?.toDouble() ?? 0.0,
      height: map['height']?.toDouble() ?? 0.0,
      age: map['age']?.toInt() ?? 0,
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
      genre: this.genre,
      name: this.name,
      weight: this.weight,
      height: this.height,
      age: this.age,
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

  // Getter for compatibility (some code expects 'nombre')
  String get nombre => name;

  // Additional properties for AI chat functionality
  String? get experienceLevel => 'Beginner'; // Default experience level
  List<String>? get goals => ['Fitness general']; // Default goals
}