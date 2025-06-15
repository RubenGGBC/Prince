// lib/models/form_feedback.dart
// 📊 MODELO PARA EL PUNTAJE DE TÉCNICA EN TIEMPO REAL
class FormScore {
  final double score;          // Puntaje de 0.0 a 10.0
  final DateTime timestamp;    // Cuándo se tomó esta medición
  final double confidence;     // Qué tan confiable es (0.0 a 1.0)

  FormScore({
    required this.score,
    required this.timestamp,
    required this.confidence,
  });

  // ✅ Determinar si el score es confiable
  bool get isReliable => confidence > 0.7;

  // 🎯 Clasificar el nivel de técnica
  String get gradeText {
    if (score >= 9.0) return 'EXCELENTE';
    if (score >= 7.5) return 'MUY BUENA';
    if (score >= 6.0) return 'BUENA';
    if (score >= 4.5) return 'REGULAR';
    return 'NECESITA MEJORAR';
  }

  // 🎨 Color asociado al puntaje
  String get gradeColor {
    if (score >= 9.0) return '#4CAF50';      // Verde brillante
    if (score >= 7.5) return '#8BC34A';      // Verde claro
    if (score >= 6.0) return '#FFC107';      // Amarillo
    if (score >= 4.5) return '#FF9800';      // Naranja
    return '#F44336';                        // Rojo
  }
}

// 💬 MODELO PARA EL FEEDBACK FINAL DE LA SERIE
class FormFeedback {
  final double averageScore;      // Puntaje promedio de toda la serie
  final String mainComment;       // Comentario principal sobre la técnica
  final List<String> tips;        // Consejos específicos para mejorar
  final Map<String, double> detailedScores;  // Puntajes por aspecto (ej: postura, velocidad)
  final int totalReps;           // Repeticiones detectadas por la IA

  FormFeedback({
    required this.averageScore,
    required this.mainComment,
    required this.tips,
    required this.detailedScores,
    required this.totalReps,
  });

  // 🏆 Obtener emoji según el puntaje
  String get emoji {
    if (averageScore >= 9.0) return '🔥';
    if (averageScore >= 7.5) return '💪';
    if (averageScore >= 6.0) return '👍';
    if (averageScore >= 4.5) return '⚡';
    return '🎯';
  }

  // 📈 Mensaje motivacional
  String get motivationalMessage {
    if (averageScore >= 9.0) return '¡Técnica perfecta! Sigue así.';
    if (averageScore >= 7.5) return '¡Muy bien! Solo pequeños ajustes.';
    if (averageScore >= 6.0) return 'Buen trabajo, puedes mejorar más.';
    if (averageScore >= 4.5) return 'Vas por buen camino, sigue practicando.';
    return 'Enfócate en la técnica más que en el peso.';
  }
}

// 📍 MODELO PARA PUNTOS CLAVE DEL CUERPO
class BodyKeypoint {
  final String name;           // Nombre del punto (ej: "leftShoulder")
  final double x;             // Posición X en la pantalla
  final double y;             // Posición Y en la pantalla
  final double confidence;    // Qué tan seguro está la IA (0.0 a 1.0)

  BodyKeypoint({
    required this.name,
    required this.x,
    required this.y,
    required this.confidence,
  });

  // ✅ Si el punto es visible y confiable
  bool get isVisible => confidence > 0.5;
}

// 🏋️ ENUM PARA TIPOS DE EJERCICIOS SOPORTADOS
enum ExerciseType {
  pressPlano,           // Press de pecho plano
  peckDeck,            // Máquina peck deck
  pressInclinado,      // Press inclinado
  fondos,              // Fondos (dips)
  extensionTriceps,    // Extensión de tríceps
  extensionTricepsTrasNuca,  // Extensión tríceps tras nuca
  sentadillas,         // Sentadillas (ya implementado)
  flexiones,           // Flexiones (ya implementado)
  generic,             // Análisis genérico
}

// 🎯 EXTENSIÓN PARA OBTENER INFO DE CADA EJERCICIO
extension ExerciseTypeExtension on ExerciseType {
  String get displayName {
    switch (this) {
      case ExerciseType.pressPlano:
        return 'Press de Pecho';
      case ExerciseType.peckDeck:
        return 'Peck Deck';
      case ExerciseType.pressInclinado:
        return 'Press Inclinado';
      case ExerciseType.fondos:
        return 'Fondos';
      case ExerciseType.extensionTriceps:
        return 'Extensión Tríceps';
      case ExerciseType.extensionTricepsTrasNuca:
        return 'Extensión Tríceps Tras Nuca';
      case ExerciseType.sentadillas:
        return 'Sentadillas';
      case ExerciseType.flexiones:
        return 'Flexiones';
      case ExerciseType.generic:
        return 'Ejercicio Genérico';
    }
  }

  // 📹 Posición recomendada de la cámara
  String get cameraPosition {
    switch (this) {
      case ExerciseType.fondos:
        return 'trasera';  // Desde atrás como pidió el usuario
      case ExerciseType.extensionTriceps:
      case ExerciseType.extensionTricepsTrasNuca:
        return 'lateral';  // Desde el lateral como pidió el usuario
      default:
        return 'frontal';  // Posición frontal por defecto
    }
  }

  // 🎯 Puntos clave que debe analizar cada ejercicio
  List<String> get keypoints {
    switch (this) {
      case ExerciseType.pressPlano:
      case ExerciseType.pressInclinado:
        return ['leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow', 'leftWrist', 'rightWrist'];
      case ExerciseType.peckDeck:
        return ['leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow'];
      case ExerciseType.fondos:
        return ['leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow', 'leftHip', 'rightHip'];
      case ExerciseType.extensionTriceps:
      case ExerciseType.extensionTricepsTrasNuca:
        return ['leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow', 'leftWrist', 'rightWrist'];
      case ExerciseType.sentadillas:
        return ['leftHip', 'rightHip', 'leftKnee', 'rightKnee', 'leftAnkle', 'rightAnkle'];
      case ExerciseType.flexiones:
        return ['leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow', 'leftWrist', 'rightWrist', 'leftHip', 'rightHip'];
      default:
        return ['leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow'];
    }
  }
}