// lib/models/exercise_type.dart
enum ExerciseType {
  // 💪 EJERCICIOS DE PECHO
  pressPlano,
  pressInclinado,
  peckDeck,
  fondos,

  // 🔥 EJERCICIOS DE BRAZOS
  extensionTriceps,
  extensionTricepsTrasNuca,

  // 🦵 EJERCICIOS DE PIERNAS
  sentadillas,

  // 🏃 EJERCICIOS CORPORALES
  flexiones,

  // 🎯 GENÉRICO
  generic,
}

extension ExerciseTypeExtension on ExerciseType {

  // 📝 NOMBRE PARA MOSTRAR
  String get displayName {
    switch (this) {
      case ExerciseType.pressPlano:
        return 'Press de Banca Plano';
      case ExerciseType.pressInclinado:
        return 'Press de Banca Inclinado';
      case ExerciseType.peckDeck:
        return 'Peck Deck';
      case ExerciseType.fondos:
        return 'Fondos en Paralelas';
      case ExerciseType.extensionTriceps:
        return 'Extensión de Triceps';
      case ExerciseType.extensionTricepsTrasNuca:
        return 'Extensión de Triceps Tras Nuca';
      case ExerciseType.sentadillas:
        return 'Sentadillas';
      case ExerciseType.flexiones:
        return 'Flexiones';
      case ExerciseType.generic:
        return 'Ejercicio Genérico';
    }
  }

  // 📹 POSICIÓN ÓPTIMA DE LA CÁMARA
  String get cameraPosition {
    switch (this) {
      case ExerciseType.pressPlano:
      case ExerciseType.pressInclinado:
      case ExerciseType.peckDeck:
        return 'lateral'; // Ver desde el lado
      case ExerciseType.fondos:
      case ExerciseType.sentadillas:
        return 'frontal'; // Ver de frente
      case ExerciseType.extensionTriceps:
      case ExerciseType.extensionTricepsTrasNuca:
        return 'lateral'; // Ver desde el lado
      case ExerciseType.flexiones:
        return 'lateral'; // Ver desde el lado
      case ExerciseType.generic:
        return 'frontal'; // Por defecto frontal
    }
  }

  List<String> get keypoints {
    switch (this) {
      case ExerciseType.pressPlano:
      case ExerciseType.pressInclinado:
        return ['left_shoulder', 'right_shoulder', 'left_elbow', 'right_elbow', 'left_wrist', 'right_wrist'];
      case ExerciseType.peckDeck:
        return ['left_shoulder', 'right_shoulder', 'left_elbow', 'right_elbow'];
      case ExerciseType.fondos:
        return ['left_shoulder', 'right_shoulder', 'left_elbow', 'right_elbow', 'left_hip', 'right_hip'];
      case ExerciseType.extensionTriceps:
      case ExerciseType.extensionTricepsTrasNuca:
        return ['left_shoulder', 'right_shoulder', 'left_elbow', 'right_elbow', 'left_wrist', 'right_wrist'];
      case ExerciseType.sentadillas:
        return ['left_hip', 'right_hip', 'left_knee', 'right_knee', 'left_ankle', 'right_ankle'];
      case ExerciseType.flexiones:
        return ['left_shoulder', 'right_shoulder', 'left_elbow', 'right_elbow', 'left_wrist', 'right_wrist', 'left_hip', 'right_hip'];
      case ExerciseType.generic:
        return ['left_shoulder', 'right_shoulder', 'left_elbow', 'right_elbow'];
    }
  }

  Map<String, double> get optimalAngles {
    switch (this) {
      case ExerciseType.pressPlano:
        return {
          'elbow_angle': 90.0, // Ángulo del codo en posición baja
          'shoulder_angle': 45.0, // Ángulo del hombro
        };
      case ExerciseType.sentadillas:
        return {
          'knee_angle': 90.0, // Ángulo de rodilla en posición baja
          'hip_angle': 90.0, // Ángulo de cadera
        };
      case ExerciseType.flexiones:
        return {
          'elbow_angle': 90.0, // Ángulo del codo en posición baja
          'body_line': 180.0, // Línea recta del cuerpo
        };
      default:
        return {
          'general_angle': 90.0,
        };
    }
  }

  Map<String, double> get scoreThresholds {
    return {
      'excellent': 9.0,  // 9.0-10.0 = Excelente
      'good': 7.0,       // 7.0-8.9 = Bueno
      'fair': 5.0,       // 5.0-6.9 = Regular
      'poor': 0.0,       // 0.0-4.9 = Malo
    };
  }
}