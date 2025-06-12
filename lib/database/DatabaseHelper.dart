import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../domain/User.dart';
import '../domain/exercise.dart';
import '../domain/rutina.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'users.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
     CREATE TABLE users(
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       email TEXT UNIQUE NOT NULL,
       password TEXT NOT NULL,
       created_at TEXT NOT NULL
     )
   ''');

    await db.execute('''
     CREATE TABLE exercises(
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       grupo_muscular TEXT NOT NULL,
       nombre TEXT NOT NULL,
       hora_inicio TEXT NOT NULL,
       hora_fin TEXT NOT NULL,
       repeticiones INTEGER NOT NULL,
       series INTEGER NOT NULL,
       peso REAL NOT NULL,
       notas TEXT,
       fecha_creacion TEXT NOT NULL
     )
   ''');

    await db.execute('''
     CREATE TABLE rutinas(
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       nombre TEXT NOT NULL,
       descripcion TEXT NOT NULL,
       ejercicio_ids TEXT NOT NULL,
       duracion_estimada INTEGER NOT NULL,
       categoria TEXT NOT NULL,
       fecha_creacion TEXT NOT NULL
     )
   ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
       CREATE TABLE exercises(
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         grupo_muscular TEXT NOT NULL,
         nombre TEXT NOT NULL,
         hora_inicio TEXT NOT NULL,
         hora_fin TEXT NOT NULL,
         repeticiones INTEGER NOT NULL,
         series INTEGER NOT NULL,
         peso REAL NOT NULL,
         notas TEXT,
         fecha_creacion TEXT NOT NULL
       )
     ''');

      await db.execute('''
       CREATE TABLE rutinas(
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         nombre TEXT NOT NULL,
         descripcion TEXT NOT NULL,
         ejercicio_ids TEXT NOT NULL,
         duracion_estimada INTEGER NOT NULL,
         categoria TEXT NOT NULL,
         fecha_creacion TEXT NOT NULL
       )
     ''');
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<int> registerUser(User user) async {
    final db = await database;
    final existingUser = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [user.email],
    );

    if (existingUser.isNotEmpty) {
      throw Exception('Usuario o email ya existe');
    }

    final userWithHashedPassword = User(
      email: user.email,
      password: _hashPassword(user.password),
      createdAt: user.createdAt,
    );

    return await db.insert('users', userWithHashedPassword.toMap());
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    final hashedPassword = _hashPassword(password);

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<void> addExercise(Exercise exercise) async {
    final db = await database;
    await db.insert('exercises', exercise.toMap());
  }

  Future<List<Exercise>> getAllExercises() async {
    final db = await database;
    final result = await db.query('exercises');
    return result.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<void> deleteExercise(int id) async {
    final db = await database;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addRutina(Rutina rutina) async {
    final db = await database;
    return await db.insert('rutinas', rutina.toMap());
  }

  Future<List<Rutina>> getAllRutinas() async {
    final db = await database;
    final result = await db.query('rutinas');
    return result.map((map) => Rutina.fromMap(map)).toList();
  }

  Future<void> deleteRutina(int id) async {
    final db = await database;
    await db.delete('rutinas', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateRutina(Rutina rutina) async {
    final db = await database;
    await db.update('rutinas', rutina.toMap(), where: 'id = ?', whereArgs: [rutina.id]);
  }

  Future<List<Exercise>> getExercisesByIds(List<int> ids) async {
    final db = await database;
    final placeholders = ids.map((e) => '?').join(',');
    final result = await db.query(
      'exercises',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return result.map((map) => Exercise.fromMap(map)).toList();
  }
  Future<void> _insertPredefinedExercises(Database db) async {
    final predefinedExercises = [
      // PECHO
      {
        'grupo_muscular': 'Pecho',
        'nombre': 'Press banca',
        'peso_sugerido': 60.0
      },
      {
        'grupo_muscular': 'Pecho',
        'nombre': 'Press inclinado',
        'peso_sugerido': 50.0
      },
      {'grupo_muscular': 'Pecho', 'nombre': 'Flexiones', 'peso_sugerido': 0.0},
      {'grupo_muscular': 'Pecho', 'nombre': 'Aperturas', 'peso_sugerido': 20.0},

      // ESPALDA
      {
        'grupo_muscular': 'Espalda',
        'nombre': 'Dominadas',
        'peso_sugerido': 0.0
      },
      {
        'grupo_muscular': 'Espalda',
        'nombre': 'Remo con barra',
        'peso_sugerido': 40.0
      },
      {'grupo_muscular': 'Espalda', 'nombre': 'Jalones', 'peso_sugerido': 35.0},
      {
        'grupo_muscular': 'Espalda',
        'nombre': 'Peso muerto',
        'peso_sugerido': 80.0
      },

      // PIERNAS
      {
        'grupo_muscular': 'Piernas',
        'nombre': 'Sentadillas',
        'peso_sugerido': 70.0
      },
      {'grupo_muscular': 'Piernas', 'nombre': 'Prensa', 'peso_sugerido': 100.0},
      {
        'grupo_muscular': 'Piernas',
        'nombre': 'Extensiones',
        'peso_sugerido': 30.0
      },
      {
        'grupo_muscular': 'Piernas',
        'nombre': 'Curl femoral',
        'peso_sugerido': 25.0
      },

      // HOMBROS
      {
        'grupo_muscular': 'Hombros',
        'nombre': 'Press militar',
        'peso_sugerido': 30.0
      },
      {
        'grupo_muscular': 'Hombros',
        'nombre': 'Elevaciones laterales',
        'peso_sugerido': 12.0
      },
      {
        'grupo_muscular': 'Hombros',
        'nombre': 'Elevaciones frontales',
        'peso_sugerido': 10.0
      },
      {'grupo_muscular': 'Hombros', 'nombre': 'Pajaros', 'peso_sugerido': 8.0},

      // BRAZOS
      {
        'grupo_muscular': 'Brazos',
        'nombre': 'Curl biceps',
        'peso_sugerido': 15.0
      },
      {
        'grupo_muscular': 'Brazos',
        'nombre': 'Press frances',
        'peso_sugerido': 20.0
      },
      {'grupo_muscular': 'Brazos', 'nombre': 'Fondos', 'peso_sugerido': 0.0},
      {'grupo_muscular': 'Brazos', 'nombre': 'Martillo', 'peso_sugerido': 12.0},
    ];

    final now = DateTime.now();
    for (var exerciseData in predefinedExercises) {
      await db.insert('exercises', {
        'grupo_muscular': exerciseData['grupo_muscular'],
        'nombre': exerciseData['nombre'],
        'hora_inicio': now.subtract(Duration(minutes: 30)).toIso8601String(),
        'hora_fin': now.toIso8601String(),
        'repeticiones': 12,
        'series': 3,
        'peso': exerciseData['peso_sugerido'],
        'notas': 'Ejercicio predefinido',
        'fecha_creacion': now.toIso8601String(),
      });
    }
  }
  Future<void> _insertPredefinedRoutines(Database db) async {
    final predefinedRoutines = [
      {
        'nombre': 'Push (Empuje)',
        'descripcion': 'Pecho, hombros y tríceps',
        'ejercicio_ids': '1,2,3,13,14,18', // IDs de ejercicios de empuje
        'duracion_estimada': 60,
        'categoria': 'Fuerza',
        'fecha_creacion': DateTime.now().toIso8601String(),
      },
      {
        'nombre': 'Pull (Tracción)',
        'descripcion': 'Espalda y bíceps',
        'ejercicio_ids': '5,6,7,8,17,20', // IDs de ejercicios de tracción
        'duracion_estimada': 55,
        'categoria': 'Fuerza',
        'fecha_creacion': DateTime.now().toIso8601String(),
      },
      {
        'nombre': 'Legs (Piernas)',
        'descripcion': 'Cuádriceps, glúteos y pantorrillas',
        'ejercicio_ids': '9,10,11,12', // IDs de ejercicios de piernas
        'duracion_estimada': 70,
        'categoria': 'Fuerza',
        'fecha_creacion': DateTime.now().toIso8601String(),
      },
      {
        'nombre': 'Full Body Principiante',
        'descripcion': 'Rutina completa para empezar',
        'ejercicio_ids': '3,5,9,13,17', // Flexiones, dominadas, sentadillas, press militar, curl
        'duracion_estimada': 45,
        'categoria': 'Principiante',
        'fecha_creacion': DateTime.now().toIso8601String(),
      },
      {
        'nombre': 'HIIT Cardio',
        'descripcion': 'Alta intensidad para quemar grasa',
        'ejercicio_ids': '3,9,19', // Flexiones, sentadillas, fondos
        'duracion_estimada': 30,
        'categoria': 'Cardio',
        'fecha_creacion': DateTime.now().toIso8601String(),
      },
    ];

    for (var routine in predefinedRoutines) {
      await db.insert('rutinas', routine);
    }
  }
  }