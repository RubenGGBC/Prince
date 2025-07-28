import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';


import '../domain/user.dart';
import '../domain/exercise.dart';
import '../domain/rutina.dart';
import '../domain/nutricion.dart';

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
      version: 6, // 📝 Incrementé la versión para incluir tabla de nutrición
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
       created_at TEXT NOT NULL,
       genre TEXT NOT NULL,
       name TEXT NOT NULL,
       weight REAL NOT NULL,
       height REAL NOT NULL,
       age INTEGER NOT NULL  
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

    // 📝 Crear tabla de nutrición
    await db.execute('''
     CREATE TABLE nutrition(
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       name TEXT NOT NULL,
       calorias REAL NOT NULL,
       proteinas REAL NOT NULL,
       grasas REAL NOT NULL,
       carbohidratos REAL NOT NULL,
       categoria TEXT NOT NULL DEFAULT 'General',
       image_path TEXT,
       descripcion TEXT,
       fecha_creacion TEXT NOT NULL
     )
   ''');
    print('✅ Tabla nutrition creada'); // 🔍 Debug

    // 📝 Insertar datos predefinidos
    await _insertPredefinedExercises(db);
    await _insertPredefinedRoutines(db);
    await _insertPredefinedNutrition(db);

    print('🎉 Base de datos inicializada completamente'); // 🔍 Debug
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Actualizando base de datos de versión $oldVersion a $newVersion'); // 🔍 Debug

    if (oldVersion < 6) {
      // Eliminar tablas existentes y recrear
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS exercises');
      await db.execute('DROP TABLE IF EXISTS rutinas');
      await db.execute('DROP TABLE IF EXISTS nutrition');

      // Recrear tablas

      await db.execute('''
       CREATE TABLE users(
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         email TEXT UNIQUE NOT NULL,
         password TEXT NOT NULL,
         created_at TEXT NOT NULL,
         genre TEXT NOT NULL,
         name TEXT NOT NULL,
         weight REAL NOT NULL,
         height REAL NOT NULL,
         age INTEGER NOT NULL  
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

      await db.execute('''
       CREATE TABLE nutrition(
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         name TEXT NOT NULL,
         calorias REAL NOT NULL,
         proteinas REAL NOT NULL,
         grasas REAL NOT NULL,
         carbohidratos REAL NOT NULL,
         categoria TEXT NOT NULL DEFAULT 'General',
         image_path TEXT,
         descripcion TEXT,
         fecha_creacion TEXT NOT NULL
       )
     ''');

      // 📝 Insertar datos predefinidos para upgrades
      await _insertPredefinedExercises(db);
      await _insertPredefinedRoutines(db);
      await _insertPredefinedNutrition(db);
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
      throw Exception('Ya existe un usuario con este email');
    }

    final userWithHashedPassword = User(
      email: user.email,
      password: _hashPassword(user.password),
      createdAt: user.createdAt,
      genre: user.genre,
      name: user.name,
      weight: user.weight,
      height: user.height,
      age: user.age,
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

      print('Base de datos reseteada correctamente'); // 🔍 Debug
    } catch (e) {
      print(' Error reseteando base de datos: $e'); // 🔍 Debug
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
      print(' Error contando registros: $e'); // 🔍 Debug
      return {'exercises': 0, 'rutinas': 0, 'users': 0};
    }
  }

  // 📝 MÉTODOS DE NUTRICIÓN
  Future<int> addNutrition(Nutricion nutrition) async {
    final db = await database;
    try {
      return await db.insert('nutrition', nutrition.toMap());
    } catch (e) {
      print(' Error agregando nutrición: $e');
      throw Exception('Error al agregar alimento');
    }
  }

  Future<List<Nutricion>> getAllNutrition() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('nutrition');
      return List.generate(maps.length, (i) => Nutricion.fromMap(maps[i]));
    } catch (e) {
      print(' Error obteniendo nutrición: $e');
      return [];
    }
  }

  Future<void> deleteNutrition(int id) async {
    final db = await database;
    try {
      await db.delete('nutrition', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error eliminando nutrición: $e');
      throw Exception('Error al eliminar alimento');
    }
  }

  Future<void> _insertPredefinedNutrition(Database db) async {
    print('📝 Insertando alimentos predefinidos...'); // Debug

    final predefinedNutrition = [
      {
        'name': 'Pollo a la plancha (100g)',
        'calorias': 165.0,
        'proteinas': 31.0,
        'grasas': 3.6,
        'carbohidratos': 0.0,
        'categoria': 'Almuerzo',
        'descripcion': 'Pechuga de pollo sin piel a la plancha',
      },
      {
        'name': 'Arroz integral (100g)',
        'calorias': 111.0,
        'proteinas': 2.6,
        'grasas': 0.9,
        'carbohidratos': 23.0,
        'categoria': 'Almuerzo',
        'descripcion': 'Arroz integral cocido',
      },
      {
        'name': 'Avena con frutas',
        'calorias': 280.0,
        'proteinas': 12.0,
        'grasas': 8.0,
        'carbohidratos': 42.0,
        'categoria': 'Desayuno',
        'descripcion': 'Avena en hojuelas con plátano y fresas',
      },
      {
        'name': 'Salmón a la plancha (100g)',
        'calorias': 206.0,
        'proteinas': 22.0,
        'grasas': 12.0,
        'carbohidratos': 0.0,
        'categoria': 'Cena',
        'descripcion': 'Filete de salmón fresco a la plancha',
      },
      {
        'name': 'Ensalada de atún',
        'calorias': 320.0,
        'proteinas': 28.0,
        'grasas': 15.0,
        'carbohidratos': 18.0,
        'categoria': 'Almuerzo',
        'descripcion': 'Ensalada mixta con atún en agua',
      },
      {
        'name': 'Batido de proteína',
        'calorias': 220.0,
        'proteinas': 25.0,
        'grasas': 4.0,
        'carbohidratos': 18.0,
        'categoria': 'Snack',
        'descripcion': 'Batido con proteína en polvo y leche',
      },
      {
        'name': 'Huevos revueltos (2 unidades)',
        'calorias': 140.0,
        'proteinas': 12.0,
        'grasas': 10.0,
        'carbohidratos': 1.0,
        'categoria': 'Desayuno',
        'descripcion': 'Dos huevos revueltos con poca grasa',
      },
      {
        'name': 'Quinoa cocida (100g)',
        'calorias': 120.0,
        'proteinas': 4.4,
        'grasas': 1.9,
        'carbohidratos': 22.0,
        'categoria': 'Almuerzo',
        'descripcion': 'Quinoa cocida en agua',
      },
    ];

    final now = DateTime.now();
    int insertedCount = 0;

    for (var nutritionData in predefinedNutrition) {
      try {
        await db.insert('nutrition', {
          'name': nutritionData['name'],
          'calorias': nutritionData['calorias'],
          'proteinas': nutritionData['proteinas'],
          'grasas': nutritionData['grasas'],
          'carbohidratos': nutritionData['carbohidratos'],
          'categoria': nutritionData['categoria'],
          'descripcion': nutritionData['descripcion'],
          'fecha_creacion': now.toIso8601String(),
        });
        insertedCount++;
      } catch (e) {
        print('❌ Error insertando alimento ${nutritionData['name']}: $e');
      }
    }

    print('✅ Insertados $insertedCount alimentos predefinidos');
  }
}