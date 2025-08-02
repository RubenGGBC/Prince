class Performed_exercise {
  final String id;
  final int? exerciseId;
  final double time;
  final int series;
  final int reps;
  final double weight;
  final DateTime date;

  Performed_exercise({
    required this.id,
    required this.exerciseId,
    required this.time,
    required this.series,
    required this.reps,
    required this.weight,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'time': time,
      'series': series,
      'reps': reps,
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }

  factory Performed_exercise.fromMap(Map<String, dynamic> map) {
    return Performed_exercise(
      id: map['id'],
      exerciseId: map['exerciseId'],
      time: map['time']?.toDouble() ?? 0.0,
      series: map['series'] ?? 0,
      reps: map['reps'] ?? 0,
      weight: map['weight']?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
    );
  }

}