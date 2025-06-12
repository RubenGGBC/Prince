import '../database/DatabaseHelper.dart';

class Exercise {
  final int? id;
  final String grupoMuscular;
  final String nombre;
  final DateTime horaInicio;
  final DateTime horaFin;
  final int repeticiones;
  final int series;
  final double peso;
  final String? notas;
  final DateTime fechaCreacion;

  Exercise({
    this.id,
    required this.grupoMuscular,
    required this.nombre,
    required this.horaInicio,
    required this.horaFin,
    required this.repeticiones,
    required this.series,
    required this.peso,
    this.notas,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  // 📝 Método para convertir el objeto a Map (para guardar en base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grupo_muscular': grupoMuscular,
      'nombre': nombre,
      'hora_inicio': horaInicio.toIso8601String(),
      'hora_fin': horaFin.toIso8601String(),
      'repeticiones': repeticiones,
      'series': series,
      'peso': peso,
      'notas': notas,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }


  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      grupoMuscular: map['grupo_muscular'] ?? '',
      nombre: map['nombre'] ?? '',
      horaInicio: DateTime.parse(map['hora_inicio']),
      horaFin: DateTime.parse(map['hora_fin']),
      repeticiones: map['repeticiones'] ?? 0,
      series: map['series'] ?? 0,
      peso: map['peso']?.toDouble() ?? 0.0,
      notas: map['notas'],
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
    );
  }

  Duration get duracion {
    return horaFin.difference(horaInicio);
  }

  double get volumenTotal {
    return series * repeticiones * peso;
  }

  String get duracionFormateada {
    final duracion = this.duracion;
    final minutos = duracion.inMinutes;
    final segundos = duracion.inSeconds % 60;
    return '${minutos}m ${segundos}s';
  }

  Exercise copyWith({
    int? id,
    String? grupoMuscular,
    String? nombre,
    DateTime? horaInicio,
    DateTime? horaFin,
    int? repeticiones,
    int? series,
    double? peso,
    String? notas,
    DateTime? fechaCreacion,
  }) {
    return Exercise(
      id: id ?? this.id,
      grupoMuscular: grupoMuscular ?? this.grupoMuscular,
      nombre: nombre ?? this.nombre,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      repeticiones: repeticiones ?? this.repeticiones,
      series: series ?? this.series,
      peso: peso ?? this.peso,
      notas: notas ?? this.notas,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  String toString() {
    return 'Exercise(id: $id, nombre: $nombre, grupoMuscular: $grupoMuscular, '
        'series: $series, repeticiones: $repeticiones, peso: ${peso}kg)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}