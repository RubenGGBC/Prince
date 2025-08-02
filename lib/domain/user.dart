// ✅ Sin imports circulares - User no necesita conocer DatabaseHelper
import 'user_record.dart';
import 'dart:convert';

class User {
  final String email;
  final String password;
  final DateTime createdAt;
  final String genre;
  final String name;
  double weight;
  double height;
  int age;
  User_record user_record;

  User({
    required this.email,
    required this.password,
    required this.createdAt,
    required this.genre,
    required this.name,
    required this.weight,
    required this.height,
    required this.age,
    required this.user_record,
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
      'user_record': jsonEncode(user_record.toMap()), // 📝 Convertir a JSON string
    };
  }

  // 📝 Método para crear objeto desde Map (para leer de base de datos) - CORREGIDO
  factory User.fromMap(Map<String, dynamic> map) {
    print("DEBUG User.fromMap - Datos recibidos: $map"); // Debug
    print("DEBUG User.fromMap - user_record tipo: ${map['user_record'].runtimeType}"); // Debug

    User_record userRecord;

    try {
      if (map['user_record'] != null) {
        // Si user_record es un String (JSON), parsearlo
        if (map['user_record'] is String) {
          print("DEBUG: user_record es String, parseando JSON..."); // Debug
          final jsonMap = jsonDecode(map['user_record'] as String) as Map<String, dynamic>;
          userRecord = User_record.fromMap(jsonMap);
        }
        // Si user_record ya es un Map
        else if (map['user_record'] is Map<String, dynamic>) {
          print("DEBUG: user_record ya es Map..."); // Debug
          userRecord = User_record.fromMap(map['user_record'] as Map<String, dynamic>);
        }
        // Si es otro tipo, crear uno por defecto
        else {
          print("DEBUG: user_record es tipo desconocido: ${map['user_record'].runtimeType}"); // Debug
          userRecord = User_record(
            record: [],
            totalTrainingDays: 0,
            consecutiveTrainingDays: 0,
            recordDates: [],
          );
        }
      } else {
        print("DEBUG: user_record es null, creando por defecto..."); // Debug
        userRecord = User_record(
          record: [],
          totalTrainingDays: 0,
          consecutiveTrainingDays: 0,
          recordDates: [],
        );
      }
    } catch (e) {
      print("ERROR parseando user_record: $e"); // Debug
      // En caso de error, crear un user_record por defecto
      userRecord = User_record(
        record: [],
        totalTrainingDays: 0,
        consecutiveTrainingDays: 0,
        recordDates: [],
      );
    }

    return User(
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      genre: map['genre'] ?? '',
      name: map['name'] ?? '',
      weight: map['weight']?.toDouble() ?? 0.0,
      height: map['height']?.toDouble() ?? 0.0,
      age: map['age']?.toInt() ?? 0,
      user_record: userRecord,
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
      user_record: this.user_record,
    );
  }

  int get id {
    // Asumiendo que el email es único, podemos usarlo como ID
    return email.hashCode; // Usar hashCode como ID único
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