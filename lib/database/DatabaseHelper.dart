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
    // Crear tabla de usuarios
    await db.execute('''
     CREATE TABLE users(
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       email TEXT UNIQUE NOT NULL,
       password TEXT NOT NULL,
       created_at TEXT NOT NULL
     )
   ''');

    // Crear tabla de ejercicios
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

    // Crear tabla de rutinas
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

    // 🔥 NUEVO: Insertar ejercicios predefinidos cuando se crea la BD
    print('📝 Insertando ejercicios predefinidos...');
    await _insertPredefinedExercises(db);
    await _insertPredefinedRoutines(db);
    print('✅ Ejercicios y rutinas predefinidos insertados');
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

      // Insertar ejercicios predefinidos también en upgrade
      await _insertPredefinedExercises(db);
      await _insertPredefinedRoutines(db);
    }
  }

  // 🔥 NUEVO MÉTODO: Insertar ejercicios predefinidos
  Future<void> _insertPredefinedExercises(Database db) async {
    final predefinedExercises = [
      // PECHO 💪
      {
        'grupo_muscular': 'Pecho',
        'nombre': 'Press banca',
        'peso_sugerido': 60.0,
        'series': 4,
        'repeticiones': 10
      },
      {
        'grupo_muscular': 'Pecho',
        'nombre': 'Press inclinado',
        'peso_sugerido': 50.0,
        'series': 3,
        'repeticiones': 12
      },
      {
        'grupo_muscular': 'Pecho',
        'nombre': 'Flexiones',
        'peso_sugerido': 0.0,
        'series': 3,
        'repeticiones': 15
      },
      {
        'grupo_muscular': 'Pecho',
        'nombre': 'Aperturas con mancuernas',
        'peso_sugerido': 20.0,
        'series': 3,
        'repeticiones': 12
      },
      {
        'grupo_muscular': 'Pecho',
        'nombre': 'Press con mancuernas',
        'peso_sugerido': 30.0,
        'series': 4,
        'repeticiones': 10
      },

      // ESPALDA 🏋️
      {
        'grupo_muscular': 'Espalda',
        'nombre': 'Dominadas',
        'peso_sugerido': 0.0,
        'series': 3,
        'repeticiones': 8
      },
      {
        'grupo_muscular': 'Espalda',
        'nombre': 'Remo con barra',
        'peso_sugerido': 40.0,
        'series': 4,
        'repeticiones': 10
      },
      {
        'grupo_muscular': 'Espalda',
        'nombre': 'Jalones al pecho',
        'peso_sugerido': 35.0,
        'series': 3,
        'repeticiones': 12
      },
      {
        'grupo_muscular': 'Espalda',
        'nombre': 'Peso muerto',
        'peso_sugerido': 80.0,
        'series': 4,
        'repeticiones': 6
      },
      {
        'grupo_muscular': 'Espalda',
        'nombre': 'Remo con mancuerna',
        'peso_sugerido': 25.0,
        'series': 3,
        'repeticiones': 12
      },

      // PIERNAS 🦵
      {
        'grupo_muscular': 'Piernas',
        'nombre': 'Sentadillas',
        'peso_sugerido': 70.0,
        'series': 4,
        'repeticiones': 12
      },
      {
        'grupo_muscular': 'Piernas',
        'nombre': 'Prensa de piernas',
        'peso_sugerido': 100.0,
        'series': 3,
        'repeticiones': 15
      },
      {
        'grupo_muscular': 'Piernas',
        'nombre': 'Extensiones de cuádriceps',
        'peso_sugerido': 30.0,
        'series': 3,
        'repeticiones': 15
      },
      {
        'grupo_muscular': 'Piernas',
        'nombre': 'Curl femoral',
        'peso_sugerido': 25.0,
        'series': 3,
        'repeticiones': 12
      },
      {
        'grupo_muscular': 'Piernas',
        'nombre': 'Zancadas',
        'peso_sugerido': 20.0,
        'series': 3,
        'repeticiones': 12
      },

      // HOMBROS 🤸
      {
        'grupo_muscular': 'Hombros',
        'nombre': 'Press militar',
        'peso_sugerido': 30.0,
        'series': 4,
        'repeticiones': 10
      },
      {
        'grupo_muscular': 'Hombros',
        'nombre': 'Elevaciones laterales',
        'peso_sugerido': 12.0,
        'series': 3,
        'repeticiones': 15
      },
      {
        'grupo_muscular': 'Hombros',
        'nombre': 'Elevaciones frontales',
        'peso_sugerido': 10.0,
        'series': 3,
        'repeticiones': 12
      },
      {
        'grupo_muscular': 'Hombros',
        'nombre': 'Pájaros',
        'peso_sugerido': 8.0,
        'series': 3,
        'repeticiones': 15
      },
      {
        'grupo_muscular': 'Hombros',
        'nombre': 'Press con mancuernas',
        'peso_sugerido': 15.0,
        'series': 3,
        'repeticiones': 12
      },

      // BRAZOS 💪
      {
        'grupo_muscular': 'Brazos',
        'nombre': 'Curl de bíceps',
        'peso_sugerido': 15.0,
        'series': 3,
        'repeticiones': 12
      },
      {
        'grupo_muscular': 'Brazos',
        'nombre': 'Press francés',
        'peso_sugerido': 20.0,
        'series': 3,
        'repeticiones': 10
      },
      {
        'grupo_muscular': 'Brazos',
        'nombre': 'Fondos en paralelas',
        'peso_sugerido': 0.0,
        'series': 3,
        'repeticiones': 12
      },
      {
        'grupo_muscular': 'Brazos',
        'nombre': 'Curl martillo',
        'peso_sugerido': 12.0,
        'series': 3,
        'repeticiones': 12
      },
      {
        'grupo_muscular': 'Brazos',
        'nombre': 'Tríceps en polea',
        'peso_sugerido': 20.0,
        'series': 3,
        'repeticiones': 15
      },

      // CARDIO 🏃
      {
        'grupo_muscular': 'Cardio',
        'nombre': 'Burpees',
        'peso_sugerido': 0.0,
        'series': 3,
        'repeticiones': 10
      },
      {
        'grupo_muscular': 'Cardio',
        'nombre': 'Mountain climbers',
        'peso_sugerido': 0.0,
        'series': 3,
        'repeticiones': 20
      },
      {
        'grupo_muscular': 'Cardio',
        'nombre': 'Jumping jacks',
        'peso_sugerido': 0.0,
        'series': 3,
        'repeticiones': 30
      },
      {
        'grupo_muscular': 'Cardio',
        'nombre': 'High knees',
        'peso_sugerido': 0.0,
        'series': 3,
        'repeticiones': 20
      },
    ];

    final now = DateTime.now();
    for (var exerciseData in predefinedExercises) {
      await db.insert('exercises', {
        'grupo_muscular': exerciseData['grupo_muscular'],
        'nombre': exerciseData['nombre'],
        'hora_inicio': now.subtract(Duration(minutes: 30)).toIso8601String(),
        'hora_fin': now.toIso8601String(),
        'repeticiones': exerciseData['repeticiones'],
        'series': exerciseData['series'],
        'peso': exerciseData['peso_sugerido'],
        'notas': 'Ejercicio predefinido',
        'fecha_creacion': now.toIso8601String(),
      });
    }
  }

  // 🔥 NUEVO MÉTODO: Insertar rutinas predefinidas
  Future<void> _insertPredefinedRoutines(Database db) async {
    final predefinedRoutines = [
      {
        'nombre': 'Push (Empuje)',
        'descripcion': 'Pecho, hombros y tríceps - Día de empuje completo',
        'ejercicio_ids': '1,2,5,16,20,22', // Press banca, press inclinado, press mancuernas, press militar, press francés, tríceps polea
        'duracion_estimada': 75,
        'categoria': 'Fuerza',
        'fecha_creacion': DateTime.now().toIso8601String(),
      },
      {
        'nombre': 'Pull (Tracción)',
        'descripcion': 'Espalda y bíceps - Día de tracción completo',
        'ejercicio_ids': '6,7,8,9,10,21,24', // Dominadas, remo barra, jalones, peso muerto, remo mancuerna, curl bíceps, curl martillo
        'duracion_estimada': 70,
        'categoria': 'Fuerza',
        'fecha_creacion': DateTime.now().toIso8601String(),
      },
      {
        'nombre': 'Legs (Piernas)',
        'descripcion': 'Tren inferior completo - Cuádriceps, glúteos y isquios',
        'ejercicio_ids': '11,12,13,14,15', // Sentadillas, prensa, extensiones, curl femoral, zancadas
        'duracion_estimada': 80,
        'categoria': 'Fuerza',
        'fecha_creacion': DateTime.now().toIso8601String(),
      },
      {
        'nombre': 'Full Body Principiante',
        'descripcion': 'Rutina completa para empezar en el gimnasio',
        'ejercicio_ids': '3,6,11,16,21', // Flexiones, dominadas, sentadillas, press militar, curl bíceps
        'duracion_estimada': 45,
        'categoria': 'Principiante',
        'fecha_creacion': DateTime.now().toIso8601String(),
      },
      {
        'nombre': 'HIIT Cardio Quema Grasa',
        'descripcion': 'Alta intensidad para quemar calorías rápidamente',
        'ejercicio_ids': '26,27,28,29,3,23', // Burpees, mountain climbers, jumping jacks, high knees, flexiones, fondos
        'duracion_estimada': 30,
        'categoria': 'Cardio',
        'fecha_creacion': DateTime.now().toIso8601String(),
      },
      {
        'nombre': 'Upper Body (Tren Superior)',
        'descripcion': 'Enfoque completo en pecho, espalda, hombros y brazos',
        'ejercicio_ids': '1,6,16,17,21,22', // Press banca, dominadas, press militar, elevaciones laterales, curl bíceps, press francés
        'duracion_estimada': 65,
        'categoria': 'Fuerza',
        'fecha_creacion': DateTime.now().toIso8601String(),
      },
    ];

    for (var routine in predefinedRoutines) {
      await db.insert('rutinas', routine);
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
    final result = await db.query('exercises', orderBy: 'grupo_muscular, nombre');
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
    final result = await db.query('rutinas', orderBy: 'fecha_creacion DESC');
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

  // 🔥 NUEVO MÉTODO: Limpiar y reinsertar ejercicios (útil para desarrollo)
  Future<void> resetPredefinedData() async {
    final db = await database;
    await db.delete('exercises');
    await db.delete('rutinas');
    await _insertPredefinedExercises(db);
    await _insertPredefinedRoutines(db);
    print('✅ Datos predefinidos reiniciados');
  }
}