import 'performed_exercise.dart';

class Training {
  final int? id;
  final int? rutinaId;
  final List<Performed_exercise> performedExercises;
  final DateTime date;
  final double? totalTime; // Total time in seconds

  Training({
    this.id,
    this.rutinaId,
    required this.performedExercises,
    DateTime? date,
    this.totalTime,
  }) : date = date ?? DateTime.now();

  // 📝 Método para convertir el objeto a Map (para guardar en base de datos)})
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rutina_id': rutinaId,
      'performed_exercises': performedExercises.map((e) => e.toMap()).toList(),
      'date': date.toIso8601String(),
      'total_time': totalTime,
    };
  }

  // 📝 Método para crear objeto desde Map (para leer de base de datos)
  factory Training.fromMap(Map<String, dynamic> map) {
    return Training(
      id: map['id'],
      rutinaId: map['rutina_id'],
      performedExercises: (map['performed_exercises'] as List<dynamic>?)
          ?.map((item) => Performed_exercise.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      date: DateTime.parse(map['date']),
      totalTime: map['total_time']?.toDouble(),
    );
  }

  // 📝 Método para crear una copia modificada del objeto
  Training copyWith({
    int? id,
    int? rutinaId,
    List<Performed_exercise>? performedExercises,
    DateTime? date,
    double? totalTime,
  }) {
    return Training(
      id: id ?? this.id,
      rutinaId: rutinaId ?? this.rutinaId,
      performedExercises: performedExercises ?? this.performedExercises,
      date: date ?? this.date,
      totalTime: totalTime ?? this.totalTime,
    );
  }
  @override
  String toString() {
    return 'Training(id: $id, rutinaId: $rutinaId, performedExercises: ${performedExercises.length}, date: $date, totalTime: $totalTime)';
  }
}