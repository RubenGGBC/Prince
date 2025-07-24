class Nutricion {
  final int? id;
  final String name;
  final double calorias;
  final double proteinas;
  final double grasas;
  final double carbohidratos;
  final String categoria;
  final String? imagePath;
  final String? descripcion;
  final DateTime fechaCreacion;

  Nutricion({
    this.id,
    required this.name,
    required this.calorias,
    required this.proteinas,
    required this.grasas,
    required this.carbohidratos,
    this.categoria = 'General',
    this.imagePath,
    this.descripcion,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calorias': calorias,
      'proteinas': proteinas,
      'grasas': grasas,
      'carbohidratos': carbohidratos,
      'categoria': categoria,
      'image_path': imagePath,
      'descripcion': descripcion,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  // Create from Map
  factory Nutricion.fromMap(Map<String, dynamic> map) {
    return Nutricion(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      calorias: map['calorias']?.toDouble() ?? 0.0,
      proteinas: map['proteinas']?.toDouble() ?? 0.0,
      grasas: map['grasas']?.toDouble() ?? 0.0,
      carbohidratos: map['carbohidratos']?.toDouble() ?? 0.0,
      categoria: map['categoria'] ?? 'General',
      imagePath: map['image_path'],
      descripcion: map['descripcion'],
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
    );
  }

  @override
  String toString() {
    return 'Nutricion(id: $id, name: $name, calorias: $calorias)';
  }
}