// lib/services/smart_notifications_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/form_feedback.dart';
import '../domain/user.dart';
import '../domain/exercise.dart';
import 'ai_form_coach.dart';

/// 📱 SERVICIO DE NOTIFICACIONES INTELIGENTES CON IA
class SmartNotificationsService {
  static final SmartNotificationsService _instance = SmartNotificationsService._internal();
  factory SmartNotificationsService() => _instance;
  SmartNotificationsService._internal();

  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  final AIFormCoach _aiCoach = AIFormCoach();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  // 🎯 Configuración de notificaciones
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyLastWorkoutDate = 'last_workout_date';
  static const String _keyWorkoutStreak = 'workout_streak';
  static const String _keyUserProgress = 'user_progress';

  // 📊 Tipos de notificaciones
  static const int _notificationIdWorkoutReminder = 1001;
  static const int _notificationIdTechniqueImprovement = 1002;
  static const int _notificationIdMotivational = 1003;
  static const int _notificationIdProgressReport = 1004;
  static const int _notificationIdRestReminder = 1005;

  /// 🚀 INICIALIZAR SERVICIO
  Future<bool> initialize() async {
    try {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Configuración Android
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración iOS
      final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      // Configuración general
      final InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Inicializar plugin
      await _flutterLocalNotificationsPlugin!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Cargar configuración
      await _loadSettings();

      // Solicitar permisos
      await _requestPermissions();

      _isInitialized = true;
      print('✅ SmartNotificationsService inicializado');

      // Programar notificaciones inteligentes
      await _scheduleSmartNotifications();

      return true;

    } catch (e) {
      print('❌ Error inicializando notificaciones: $e');
      return false;
    }
  }

  /// 🔔 SOLICITAR PERMISOS
  Future<void> _requestPermissions() async {
    final plugin = _flutterLocalNotificationsPlugin!;

    // Permisos Android
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Permisos iOS
    await plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// ⚙️ CARGAR CONFIGURACIÓN
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  /// 💾 GUARDAR CONFIGURACIÓN
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, _notificationsEnabled);
  }

  /// 🎯 MANEJAR TAP EN NOTIFICACIÓN
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('🔔 Notificación tocada: ${notificationResponse.payload}');

    final payload = notificationResponse.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        _handleNotificationAction(data);
      } catch (e) {
        print('❌ Error procesando payload: $e');
      }
    }
  }

  /// 🎬 MANEJAR ACCIÓN DE NOTIFICACIÓN
  void _handleNotificationAction(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'workout_reminder':
      // Navegar a pantalla de rutinas
        break;
      case 'technique_improvement':
      // Navegar a análisis de progreso
        break;
      case 'motivational':
      // Mostrar mensaje motivacional
        break;
      case 'progress_report':
      // Navegar a estadísticas
        break;
    }
  }

  /// 🏋️ NOTIFICAR INICIO DE ENTRENAMIENTO
  Future<void> notifyWorkoutStarted(Exercise exercise, User? user) async {
    if (!_isInitialized || !_notificationsEnabled) return;

    try {
      // Actualizar última fecha de entrenamiento
      await _updateLastWorkoutDate();

      // Generar mensaje motivacional personalizado
      String message = '💪 ¡A entrenar ${exercise.nombre}!';

      if (user != null) {
        message = '¡Hola ${user.nombre}! Es hora de ${exercise.nombre}. ¡Vamos a mejorar tu técnica! 🔥';
      }

      await _showNotification(
        id: _notificationIdWorkoutReminder,
        title: '🏋️ Entrenamiento Iniciado',
        body: message,
        payload: jsonEncode({
          'type': 'workout_started',
          'exercise': exercise.nombre,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

    } catch (e) {
      print('❌ Error en notificación de inicio: $e');
    }
  }

  /// 📊 NOTIFICAR ANÁLISIS DE TÉCNICA
  Future<void> notifyTechniqueAnalysis(FormFeedback feedback, Exercise exercise) async {
    if (!_isInitialized || !_notificationsEnabled) return;

    try {
      String title;
      String message;

      if (feedback.averageScore >= 8.0) {
        title = '🔥 ¡Técnica Excelente!';
        message = '${exercise.nombre}: ${feedback.averageScore.toStringAsFixed(1)}/10. ¡Sigue así, campeón!';
      } else if (feedback.averageScore >= 6.0) {
        title = '💪 ¡Buen Trabajo!';
        message = '${exercise.nombre}: ${feedback.averageScore.toStringAsFixed(1)}/10. ${feedback.mainTip ?? "Sigue mejorando"}';
      } else {
        title = '🎯 Oportunidad de Mejora';
        message = '${exercise.nombre}: Técnica en desarrollo. ${feedback.mainTip ?? "Sigue practicando"}';
      }

      await _showNotification(
        id: _notificationIdTechniqueImprovement,
        title: title,
        body: message,
        payload: jsonEncode({
          'type': 'technique_analysis',
          'exercise': exercise.nombre,
          'score': feedback.averageScore,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

    } catch (e) {
      print('❌ Error en notificación de análisis: $e');
    }
  }

  /// 🎉 NOTIFICAR LOGROS Y PROGRESO
  Future<void> notifyAchievement(String achievement, {String? description}) async {
    if (!_isInitialized || !_notificationsEnabled) return;

    try {
      await _showNotification(
        id: _notificationIdProgressReport,
        title: '🏆 ¡Logro Desbloqueado!',
        body: description ?? achievement,
        payload: jsonEncode({
          'type': 'achievement',
          'achievement': achievement,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

    } catch (e) {
      print('❌ Error en notificación de logro: $e');
    }
  }

  /// 😴 NOTIFICAR RECORDATORIO DE DESCANSO
  Future<void> notifyRestReminder(int restSeconds) async {
    if (!_isInitialized || !_notificationsEnabled) return;

    try {
      final message = restSeconds > 60
          ? 'Descanso completado. ¡Tiempo del siguiente set! 💪'
          : 'Últimos $restSeconds segundos de descanso ⏰';

      await _showNotification(
        id: _notificationIdRestReminder,
        title: '⏰ Recordatorio de Descanso',
        body: message,
        payload: jsonEncode({
          'type': 'rest_reminder',
          'restSeconds': restSeconds,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

    } catch (e) {
      print('❌ Error en notificación de descanso: $e');
    }
  }

  /// 🤖 NOTIFICACIONES INTELIGENTES PROGRAMADAS
  Future<void> _scheduleSmartNotifications() async {
    if (!_isInitialized || !_notificationsEnabled) return;

    try {
      // Cancelar notificaciones programadas anteriores
      await _flutterLocalNotificationsPlugin!.cancelAll();

      // Programar recordatorios de entrenamiento inteligentes
      await _scheduleWorkoutReminders();

      // Programar reportes de progreso semanales
      await _scheduleProgressReports();

      // Programar motivación diaria
      await _scheduleDailyMotivation();

    } catch (e) {
      print('❌ Error programando notificaciones: $e');
    }
  }

  /// 🏋️ PROGRAMAR RECORDATORIOS DE ENTRENAMIENTO
  Future<void> _scheduleWorkoutReminders() async {
    // Recordatorio diario si no ha entrenado
    await _scheduleRepeatingNotification(
      id: _notificationIdWorkoutReminder,
      title: '💪 ¡Hora de entrenar!',
      body: 'Tu técnica te está esperando. ¡Vamos a mejorar juntos!',
      hour: 18, // 6 PM
      minute: 0,
      payload: jsonEncode({
        'type': 'workout_reminder',
        'scheduled': true,
      }),
    );
  }

  /// 📊 PROGRAMAR REPORTES DE PROGRESO
  Future<void> _scheduleProgressReports() async {
    // Reporte semanal los domingos
    await _scheduleWeeklyNotification(
      id: _notificationIdProgressReport,
      title: '📊 Resumen Semanal',
      body: '¡Revisa tu progreso de esta semana con PrinceIA!',
      dayOfWeek: DateTime.sunday,
      hour: 10,
      minute: 0,
      payload: jsonEncode({
        'type': 'progress_report',
        'period': 'weekly',
      }),
    );
  }

  /// 🌅 PROGRAMAR MOTIVACIÓN DIARIA
  Future<void> _scheduleDailyMotivation() async {
    final motivationalMessages = [
      '🌟 Cada día es una nueva oportunidad para mejorar',
      '💪 La constancia vence al talento cuando el talento no es constante',
      '🔥 Tu único competidor eres tú mismo de ayer',
      '🎯 Los resultados vienen a quienes se mantienen consistentes',
      '⚡ El poder está en tus manos, úsalo sabiamente',
    ];

    for (int i = 0; i < 7; i++) {
      final message = motivationalMessages[i % motivationalMessages.length];

      await _scheduleDailyNotification(
        id: _notificationIdMotivational + i,
        title: '🌅 Buenos días, atleta',
        body: message,
        hour: 8,
        minute: 0,
        payload: jsonEncode({
          'type': 'motivational',
          'message': message,
        }),
      );
    }
  }

  /// 🔔 MOSTRAR NOTIFICACIÓN INMEDIATA
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'fitness_channel',
      'Entrenamientos y Progreso',
      channelDescription: 'Notificaciones sobre entrenamientos y análisis de técnica',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin!.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// ⏰ PROGRAMAR NOTIFICACIÓN REPETITIVA
  Future<void> _scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _flutterLocalNotificationsPlugin!.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fitness_reminders',
          'Recordatorios de Entrenamiento',
          channelDescription: 'Recordatorios para mantener consistencia',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// 📅 PROGRAMAR NOTIFICACIÓN SEMANAL
  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _flutterLocalNotificationsPlugin!.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfDayOfWeek(dayOfWeek, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fitness_reports',
          'Reportes de Progreso',
          channelDescription: 'Reportes semanales y análisis de progreso',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  /// 🌅 PROGRAMAR NOTIFICACIÓN DIARIA
  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _scheduleRepeatingNotification(
      id: id,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      payload: payload,
    );
  }

  // MÉTODOS DE UTILIDAD

  /// 📅 PRÓXIMA INSTANCIA DE HORA
  DateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 📅 PRÓXIMA INSTANCIA DE DÍA DE LA SEMANA
  DateTime _nextInstanceOfDayOfWeek(int dayOfWeek, int hour, int minute) {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 📝 ACTUALIZAR ÚLTIMA FECHA DE ENTRENAMIENTO
  Future<void> _updateLastWorkoutDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastWorkoutDate, DateTime.now().toIso8601String());

    // Actualizar racha de entrenamientos
    await _updateWorkoutStreak();
  }

  /// 🔥 ACTUALIZAR RACHA DE ENTRENAMIENTOS
  Future<void> _updateWorkoutStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastWorkoutStr = prefs.getString(_keyLastWorkoutDate);

    if (lastWorkoutStr != null) {
      final lastWorkout = DateTime.parse(lastWorkoutStr);
      final daysSinceLastWorkout = DateTime.now().difference(lastWorkout).inDays;

      int currentStreak = prefs.getInt(_keyWorkoutStreak) ?? 0;

      if (daysSinceLastWorkout == 0) {
        // Mismo día, mantener racha
      } else if (daysSinceLastWorkout == 1) {
        // Día consecutivo, incrementar racha
        currentStreak++;
        await prefs.setInt(_keyWorkoutStreak, currentStreak);

        // Notificar logro de racha
        if (currentStreak % 7 == 0) {
          await notifyAchievement(
            'Racha de $currentStreak días',
            description: '🔥 ¡Increíble constancia! Llevas $currentStreak días entrenando',
          );
        }
      } else {
        // Racha rota, reiniciar
        currentStreak = 1;
        await prefs.setInt(_keyWorkoutStreak, currentStreak);
      }
    }
  }

  // CONFIGURACIÓN PÚBLICA

  /// ✅ HABILITAR/DESHABILITAR NOTIFICACIONES
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveSettings();

    if (enabled) {
      await _scheduleSmartNotifications();
    } else {
      await _flutterLocalNotificationsPlugin!.cancelAll();
    }
  }

  /// 🔍 VERIFICAR ESTADO
  bool get isEnabled => _notificationsEnabled;
  bool get isInitialized => _isInitialized;

  /// 📊 OBTENER ESTADÍSTICAS DE NOTIFICACIONES
  Future<Map<String, dynamic>> getNotificationStats() async {
    final prefs = await SharedPreferences.getInstance();
    final lastWorkoutStr = prefs.getString(_keyLastWorkoutDate);
    final streak = prefs.getInt(_keyWorkoutStreak) ?? 0;

    return {
      'enabled': _notificationsEnabled,
      'lastWorkout': lastWorkoutStr,
      'currentStreak': streak,
      'isInitialized': _isInitialized,
    };
  }

  /// 🧹 LIMPIAR RECURSOS
  Future<void> dispose() async {
    await _flutterLocalNotificationsPlugin?.cancelAll();
    print('🧹 SmartNotificationsService disposed');
  }
}