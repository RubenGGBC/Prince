import 'dart:ffi';

import 'rutina.dart';

class User_record {
  List<int> record; // Mantengo List<int> según tu declaración original
  List<DateTime> recordDates;
  int totalTrainingDays;
  int consecutiveTrainingDays;

  User_record({
    required this.record,
    required this.totalTrainingDays,
    required this.consecutiveTrainingDays,
    required this.recordDates,
  });

  // 📝 Método para convertir el objeto a Map
  Map<String, dynamic> toMap() {
    return {
      'record': record,
      'record_dates': recordDates.map((date) => date.toIso8601String()).toList(),
      'total_training_days': totalTrainingDays,
      'consecutive_training_days': consecutiveTrainingDays,
    };
  }

  // 📝 Método para crear objeto desde Map (con mejor manejo de errores)
  factory User_record.fromMap(Map<String, dynamic> map) {
    try {
      // Manejo más seguro de la lista record
      List<int> recordList = [];
      if (map['record'] != null) {
        if (map['record'] is List) {
          recordList = (map['record'] as List).map((item) {
            if (item is int) return item;
            if (item is String) return int.tryParse(item) ?? 0;
            return 0;
          }).toList();
        }
      }

      // Manejo más seguro de las fechas
      List<DateTime> datesList = [];
      if (map['record_dates'] != null && map['record_dates'] is List) {
        datesList = (map['record_dates'] as List).map((date) {
          try {
            if (date is String) {
              return DateTime.parse(date);
            }
            return DateTime.now(); // Fecha por defecto si hay error
          } catch (e) {
            return DateTime.now();
          }
        }).toList();
      }

      return User_record(
        record: recordList,
        recordDates: datesList,
        totalTrainingDays: _safeIntParse(map['total_training_days']),
        consecutiveTrainingDays: _safeIntParse(map['consecutive_training_days']),
      );
    } catch (e) {
      // En caso de error, devolver un objeto con valores por defecto
      return User_record(
        record: [],
        recordDates: [],
        totalTrainingDays: 0,
        consecutiveTrainingDays: 0,
      );
    }
  }

  // Método auxiliar para parsing seguro de enteros
  static int _safeIntParse(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // 📝 Método para crear una copia modificada del objeto (CORREGIDO)
  User_record copyWith({
    List<int>? record, // Cambiado de List<Rutina>? a List<int>?
    List<DateTime>? recordDates,
    int? totalTrainingDays,
    int? consecutiveTrainingDays,
  }) {
    return User_record(
      record: record ?? this.record,
      recordDates: recordDates ?? this.recordDates,
      totalTrainingDays: totalTrainingDays ?? this.totalTrainingDays,
      consecutiveTrainingDays: consecutiveTrainingDays ?? this.consecutiveTrainingDays,
    );
  }

  @override
  String toString() {
    return 'User_record(totalTrainingDays: $totalTrainingDays, consecutiveTrainingDays: $consecutiveTrainingDays, recordCount: ${record.length})';
  }
}