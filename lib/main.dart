import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/primera_screen.dart';
import 'screens/login_screen.dart';
import 'screens/regiter_screen.dart';
import 'utils/app_colors.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';  // ← NUEVO: Para Windows
import 'dart:io';  // ← NUEVO: Para detectar plataforma
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ← NUEVO: Configuración específica para aplicaciones de escritorio
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Inicializar SQLite para aplicaciones de escritorio
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Para resetear la base de datos al iniciar la aplicación
  /*try {
    final dbHelper = DatabaseHelper();
    await dbHelper.resetDatabase();
    print('✅ Base de datos reseteada en main()');
  } catch (e) {
    print('❌ Error reseteando DB: $e');
  }*/

  debugDatabasePath();

  await databaseFactory.setDatabasesPath(await getDatabasesPath());

  // Inicializar Firebase (lo configuraremos después)
  // await Firebase.initializeApp();

  runApp(Prince());
}

void debugDatabasePath() async {
  var databasesPath = await getDatabasesPath();
  print('=== RUTA BASE DE DATOS ===');
  print(databasesPath);
  print('========================');
}

class Prince extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prince',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: AppColors.primaryBlack,
        visualDensity: VisualDensity.adaptivePlatformDensity,

        // Configurar tema oscuro por defecto
        brightness: Brightness.dark,

        // Configurar AppBar theme
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceBlack,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.white),
          titleTextStyle: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Configurar tema de botones
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pastelBlue,
            foregroundColor: AppColors.white,
            elevation: 8,
            shadowColor: AppColors.pastelBlue.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),

      // Rutas de la aplicación
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        // '/dashboard': (context) => DashboardScreen(), // Crearemos después
      },

      // Manejar rutas no encontradas
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => SplashScreen(),
        );
      },
    );
  }
}