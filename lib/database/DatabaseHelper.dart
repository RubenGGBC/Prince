import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// ✅ Imports corregidos - nombres consistentes en minúsculas
import '../domain/user.dart';     // Cambiado de 'user.dart' a 'user.dart'
import '../domain/exercise.dart'; // Ya estaba correcto
import '../domain/rutina.dart';   // Ya estaba correcto

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
    String path = join(await getDatabasesPath(), 'fitness_app.db'); // 📝 Nombre más específico
    print('🗄️ Inicializando base de datos en: $path'); // 🔍 Debug

    return await openDatabase(
      path,
      version: 3, // 📝 Incrementé la versión para forzar recreación
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🏗️ Creando tablas de base de datos...'); // 🔍 Debug

    // 📝 Crear tabla de usuarios
    await db.execute('''
     CREATE TABLE users(
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       email TEXT UNIQUE NOT NULL,
       password TEXT NOT NULL,
       created_at TEXT NOT NULL
     )
   ''');
    print('✅ Tabla users creada'); // 🔍 Debug

    // 📝 Crear tabla de ejercicios
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
    print('✅ Tabla exercises creada'); // 🔍 Debug

    // 📝 Crear tabla de rutinas
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
    print('✅ Tabla rutinas creada'); // 🔍 Debug

    // 📝 Insertar datos predefinidos
    await _insertPredefinedExercises(db);
    await _insertPredefinedRoutines(db);

    print('🎉 Base de datos inicializada completamente'); // 🔍 Debug
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Actualizando base de datos de versión $oldVersion a $newVersion'); // 🔍 Debug

    if (oldVersion < 3) {
      // Eliminar tablas existentes y recrear
      await db.execute('DROP TABLE IF EXISTS exercises');
      await db.execute('DROP TABLE IF EXISTS rutinas');

      // Recrear tablas
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

      // 📝 Insertar datos predefinidos para upgrades
      await _insertPredefinedExercises(db);
      await _insertPredefinedRoutines(db);
    }
  }

  // 📝 MÉTODOS DE ENCRIPTACIÓN
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 📝 MÉTODOS DE USUARIOS
  Future<int> registerUser(User user) async {
    final db = await database;
    final existingUser = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [user.email],
    );

    if (existingUser.isNotEmpty) {
      throw Exception('Usuario ya existe con este email');
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

  // 📝 MÉTODOS DE EJERCICIOS
  Future<int> addExercise(Exercise exercise) async {
    try {
      print('💾 Guardando ejercicio: ${exercise.nombre}'); // 🔍 Debug
      final db = await database;
      final id = await db.insert('exercises', exercise.toMap());
      print('✅ Ejercicio guardado con ID: $id'); // 🔍 Debug
      return id;
    } catch (e) {
      print('❌ Error guardando ejercicio: $e'); // 🔍 Debug
      rethrow;
    }
  }

  Future<List<Exercise>> getAllExercises() async {
    try {
      print('📖 Cargando todos los ejercicios...'); // 🔍 Debug
      final db = await database;
      final result = await db.query('exercises', orderBy: 'fecha_creacion DESC');
      print('✅ Encontrados ${result.length} ejercicios'); // 🔍 Debug

      final exercises = result.map((map) => Exercise.fromMap(map)).toList();

      // 🔍 Debug - mostrar algunos ejercicios
      for (int i = 0; i < (exercises.length > 3 ? 3 : exercises.length); i++) {
        print('📋 Ejercicio ${i + 1}: ${exercises[i].nombre} (${exercises[i].grupoMuscular})');
      }

      return exercises;
    } catch (e) {
      print('❌ Error cargando ejercicios: $e'); // 🔍 Debug
      rethrow;
    }
  }

  Future<void> deleteExercise(int id) async {
    try {
      print('🗑️ Eliminando ejercicio con ID: $id'); // 🔍 Debug
      final db = await database;
      await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
      print('✅ Ejercicio eliminado'); // 🔍 Debug
    } catch (e) {
      print('❌ Error eliminando ejercicio: $e'); // 🔍 Debug
      rethrow;
    }
  }

  // 📝 MÉTODOS DE RUTINAS
  Future<int> addRutina(Rutina rutina) async {
    try {
      print('💾 Guardando rutina: ${rutina.nombre}'); // 🔍 Debug
      final db = await database;
      final id = await db.insert('rutinas', rutina.toMap());
      print('✅ Rutina guardada con ID: $id'); // 🔍 Debug
      return id;
    } catch (e) {
      print('❌ Error guardando rutina: $e'); // 🔍 Debug
      rethrow;
    }
  }

  Future<List<Rutina>> getAllRutinas() async {
    try {
      print('📖 Cargando todas las rutinas...'); // 🔍 Debug
      final db = await database;
      final result = await db.query('rutinas', orderBy: 'fecha_creacion DESC');
      print('✅ Encontradas ${result.length} rutinas'); // 🔍 Debug
      return result.map((map) => Rutina.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error cargando rutinas: $e'); // 🔍 Debug
      rethrow;
    }
  }

  Future<void> deleteRutina(int id) async {
    try {
      print('🗑️ Eliminando rutina con ID: $id'); // 🔍 Debug
      final db = await database;
      await db.delete('rutinas', where: 'id = ?', whereArgs: [id]);
      print('✅ Rutina eliminada'); // 🔍 Debug
    } catch (e) {
      print('❌ Error eliminando rutina: $e'); // 🔍 Debug
      rethrow;
    }
  }

  Future<void> updateRutina(Rutina rutina) async {
    try {
      print('🔄 Actualizando rutina: ${rutina.nombre}'); // 🔍 Debug
      final db = await database;
      await db.update('rutinas', rutina.toMap(), where: 'id = ?', whereArgs: [rutina.id]);
      print('✅ Rutina actualizada'); // 🔍 Debug
    } catch (e) {
      print('❌ Error actualizando rutina: $e'); // 🔍 Debug
      rethrow;
    }
  }

  Future<List<Exercise>> getExercisesByIds(List<int> ids) async {
    try {
      if (ids.isEmpty) return [];

      print('📖 Cargando ejercicios por IDs: $ids'); // 🔍 Debug
      final db = await database;
      final placeholders = ids.map((e) => '?').join(',');
      final result = await db.query(
        'exercises',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
      print('✅ Encontrados ${result.length} ejercicios por IDs'); // 🔍 Debug
      return result.map((map) => Exercise.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error cargando ejercicios por IDs: $e'); // 🔍 Debug
      rethrow;
    }
  }

  // 📝 INSERTAR EJERCICIOS PREDEFINIDOS
  Future<void> _insertPredefinedExercises(Database db) async {
    print('📝 Insertando ejercicios predefinidos...'); // 🔍 Debug

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

      // CARDIO
      {'grupo_muscular': 'Cardio', 'nombre': 'Correr', 'peso_sugerido': 0.0},
      {'grupo_muscular': 'Cardio', 'nombre': 'Bicicleta', 'peso_sugerido': 0.0},
      {'grupo_muscular': 'Cardio', 'nombre': 'Elíptica', 'peso_sugerido': 0.0},
      {'grupo_muscular': 'Cardio', 'nombre': 'Burpees', 'peso_sugerido': 0.0},
    ];

    final now = DateTime.now();
    int insertedCount = 0;

    for (var exerciseData in predefinedExercises) {
      try {
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
        insertedCount++;
      } catch (e) {
        print('❌ Error insertando ejercicio ${exerciseData['nombre']}: $e'); // 🔍 Debug
      }
    }

    print('✅ Insertados $insertedCount ejercicios predefinidos'); // 🔍 Debug
  }

  // 📝 INSERTAR RUTINAS PREDEFINIDAS
  Future<void> _insertPredefinedRoutines(Database db) async {
    print('📝 Insertando rutinas predefinidas...'); // 🔍 Debug

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
        'ejercicio_ids': '21,22,23,24', // Ejercicios de cardio
        'duracion_estimada': 30,
        'categoria': 'Cardio',
        'fecha_creacion': DateTime.now().toIso8601String(),
      },
    ];

    int insertedCount = 0;
    for (var routine in predefinedRoutines) {
      try {
        await db.insert('rutinas', routine);
        insertedCount++;
      } catch (e) {
        print('❌ Error insertando rutina ${routine['nombre']}: $e'); // 🔍 Debug
      }
    }

    print('✅ Insertadas $insertedCount rutinas predefinidas'); // 🔍 Debug
  }

  // 📝 MÉTODO PARA LIMPIAR/RESETEAR BASE DE DATOS (útil para desarrollo)
  Future<void> resetDatabase() async {
    try {
      print('🔄 Reseteando base de datos...'); // 🔍 Debug
      final db = await database;

      // Eliminar todos los datos
      await db.delete('exercises');
      await db.delete('rutinas');
      await db.delete('users');

      // Reinsertar datos predefinidos
      await _insertPredefinedExercises(db);
      await _insertPredefinedRoutines(db);

      print('✅ Base de datos reseteada correctamente'); // 🔍 Debug
    } catch (e) {
      print('❌ Error reseteando base de datos: $e'); // 🔍 Debug
      rethrow;
    }
  }

  // 📝 MÉTODO PARA DEBUG - Contar registros
  Future<Map<String, int>> getTableCounts() async {
    try {
      final db = await database;

      final exerciseCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM exercises')
      ) ?? 0;

      final rutinaCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM rutinas')
      ) ?? 0;

      final userCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users')
      ) ?? 0;

      return {
        'exercises': exerciseCount,
        'rutinas': rutinaCount,
        'users': userCount,
      };
    } catch (e) {
      print('❌ Error contando registros: $e'); // 🔍 Debug
      return {'exercises': 0, 'rutinas': 0, 'users': 0};
    }
  }
}