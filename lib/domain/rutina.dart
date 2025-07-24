import 'exercise.dart';

class Rutina {
  final int? id;
  final String nombre;
  final String descripcion;
  final List<int> ejercicioIds;
  final int duracionEstimada;
  final String categoria;
  final DateTime fechaCreacion;

  Rutina({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.ejercicioIds,
    required this.duracionEstimada,
    required this.categoria,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'ejercicio_ids': ejercicioIds.join(','),
      'duracion_estimada': duracionEstimada,
      'categoria': categoria,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Rutina.fromMap(Map<String, dynamic> map) {
    return Rutina(
      id: map['id'],
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      ejercicioIds: map['ejercicio_ids'] != null && map['ejercicio_ids'].isNotEmpty
          ? map['ejercicio_ids'].split(',').map<int>((e) => int.parse(e)).toList()
          : [],
      duracionEstimada: map['duracion_estimada'] ?? 0,
      categoria: map['categoria'] ?? '',
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
    );
  }

  int get cantidadEjercicios => ejercicioIds.length;

  String get duracionFormateada {
    final horas = duracionEstimada ~/ 60;
    final minutos = duracionEstimada % 60;
    if (horas > 0) {
      return '${horas}h ${minutos}m';
    }
    return '${minutos}m';
  }

  Rutina copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    List<int>? ejercicioIds,
    int? duracionEstimada,
    String? dificultad,
    String? categoria,
    DateTime? fechaCreacion,
    bool? esPublica,
  }) {
    return Rutina(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      ejercicioIds: ejercicioIds ?? this.ejercicioIds,
      duracionEstimada: duracionEstimada ?? this.duracionEstimada,
      categoria: categoria ?? this.categoria,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  String toString() {
    return 'Rutina(id: $id, nombre: $nombre, ejercicios: ${cantidadEjercicios})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rutina && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}