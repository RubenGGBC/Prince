// lib/models/form_feedback.dart
import 'package:flutter/material.dart';

class FormFeedback {
  final double averageScore;        // Puntuación promedio de la serie (0.0 - 10.0)
  final String mainComment;        // Comentario principal
  final List<String> tips;         // Lista de consejos específicos
  final Map<String, dynamic> detailedScores; // Puntuaciones detalladas
  final int totalReps;            // Repeticiones detectadas

  FormFeedback({
    required this.averageScore,
    required this.mainComment,
    required this.tips,
    required this.detailedScores,
    required this.totalReps,
  });

  Color get color {
    if (averageScore >= 8.5) return Colors.green;
    if (averageScore >= 7.0) return Colors.lightGreen;
    if (averageScore >= 5.5) return Colors.orange;
    if (averageScore >= 4.0) return Colors.deepOrange;
    return Colors.red;
  }

  String get shortComment {
    if (averageScore >= 8.5) return '¡Excelente! 🔥';
    if (averageScore >= 7.0) return '¡Muy bien! 💪';
    if (averageScore >= 5.5) return 'Buen trabajo 👍';
    if (averageScore >= 4.0) return 'Sigue practicando 🎯';
    return 'Necesita mejorar 📚';
  }

  String get emoji {
    if (averageScore >= 8.5) return '🔥';
    if (averageScore >= 7.0) return '💪';
    if (averageScore >= 5.5) return '👍';
    if (averageScore >= 4.0) return '🎯';
    return '📚';
  }

  String get level {
    if (averageScore >= 9.0) return 'PERFECTO';
    if (averageScore >= 8.0) return 'EXCELENTE';
    if (averageScore >= 7.0) return 'MUY BUENO';
    if (averageScore >= 6.0) return 'BUENO';
    if (averageScore >= 5.0) return 'REGULAR';
    if (averageScore >= 4.0) return 'ACEPTABLE';
    return 'NECESITA MEJORA';
  }

  int get stars {
    if (averageScore >= 9.0) return 5;
    if (averageScore >= 7.5) return 4;
    if (averageScore >= 6.0) return 3;
    if (averageScore >= 4.5) return 2;
    return 1;
  }

  int get percentage => (averageScore * 10).round().clamp(0, 100);

  bool get isExcellent => averageScore >= 8.0;

  bool get needsImprovement => averageScore < 5.0;

  String? get celebrationMessage {
    if (averageScore >= 9.5) return '¡TÉCNICA PERFECTA! ¡Eres un maestro! 🏆';
    if (averageScore >= 9.0) return '¡INCREÍBLE! ¡Técnica casi perfecta! 🌟';
    if (averageScore >= 8.5) return '¡EXCELENTE! ¡Sigue así! 🔥';
    if (averageScore >= 8.0) return '¡MUY BIEN! ¡Gran técnica! 💪';
    return null;
  }

  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('${shortComment} (${percentage}%)');
    buffer.writeln(mainComment);

    if (totalReps > 0) {
      buffer.writeln('Repeticiones detectadas: $totalReps');
    }

    if (tips.isNotEmpty) {
      buffer.writeln('\nConsejos:');
      for (final tip in tips) {
        buffer.writeln('• $tip');
      }
    }

    return buffer.toString();
  }

  /// 💡 Consejo principal (el más importante)
  String? get mainTip => tips.isNotEmpty ? tips.first : null;

  @override
  String toString() {
    return 'FormFeedback(score: $averageScore, reps: $totalReps, comment: $mainComment)';
  }

  FormFeedback copyWith({
    double? averageScore,
    String? mainComment,
    List<String>? tips,
    Map<String, dynamic>? detailedScores,
    int? totalReps,
  }) {
    return FormFeedback(
      averageScore: averageScore ?? this.averageScore,
      mainComment: mainComment ?? this.mainComment,
      tips: tips ?? this.tips,
      detailedScores: detailedScores ?? this.detailedScores,
      totalReps: totalReps ?? this.totalReps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageScore': averageScore,
      'mainComment': mainComment,
      'tips': tips,
      'detailedScores': detailedScores,
      'totalReps': totalReps,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  factory FormFeedback.fromMap(Map<String, dynamic> map) {
    return FormFeedback(
      averageScore: map['averageScore']?.toDouble() ?? 0.0,
      mainComment: map['mainComment'] ?? '',
      tips: List<String>.from(map['tips'] ?? []),
      detailedScores: Map<String, dynamic>.from(map['detailedScores'] ?? {}),
      totalReps: map['totalReps']?.toInt() ?? 0,
    );
  }
}

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

  /// ✅ Si el punto es visible y confiable
  bool get isVisible => confidence > 0.5;

  /// 🎯 Si el punto es muy confiable
  bool get isHighConfidence => confidence > 0.8;

  @override
  String toString() {
    return 'BodyKeypoint($name: x=$x, y=$y, conf=$confidence)';
  }
}

enum ExerciseType {
  pressPlano,           // Press de pecho plano
  peckDeck,            // Máquina peck deck
  pressInclinado,      // Press inclinado
  fondos,              // Fondos (dips)
  extensionTriceps,    // Extensión de tríceps
  extensionTricepsTrasNuca,  // Extensión tríceps tras nuca
  sentadillas,         // Sentadillas
  flexiones,           // Flexiones
  generic,             // Análisis genérico
}

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

  String get cameraPosition {
    switch (this) {
      case ExerciseType.fondos:
        return 'trasera';  // Desde atrás
      case ExerciseType.extensionTriceps:
      case ExerciseType.extensionTricepsTrasNuca:
        return 'lateral';  // Desde el lateral
      default:
        return 'frontal';  // Posición frontal por defecto
    }
  }

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

  String get description {
    switch (this) {
      case ExerciseType.pressPlano:
        return 'Ejercicio de empuje horizontal para pecho, hombros y tríceps';
      case ExerciseType.peckDeck:
        return 'Ejercicio de aislamiento para pecho usando máquina';
      case ExerciseType.pressInclinado:
        return 'Variante del press de pecho con énfasis en la parte superior';
      case ExerciseType.fondos:
        return 'Ejercicio de peso corporal para pecho, hombros y tríceps';
      case ExerciseType.extensionTriceps:
        return 'Ejercicio de aislamiento para la parte posterior del brazo';
      case ExerciseType.extensionTricepsTrasNuca:
        return 'Variante de extensión de tríceps con mayor rango de movimiento';
      case ExerciseType.sentadillas:
        return 'Ejercicio fundamental para piernas y glúteos';
      case ExerciseType.flexiones:
        return 'Ejercicio de peso corporal para la parte superior del cuerpo';
      case ExerciseType.generic:
        return 'Análisis general de postura y movimiento';
    }
  }

  /// 🎯 Consejos específicos para cada ejercicio
  List<String> get specificTips {
    switch (this) {
      case ExerciseType.pressPlano:
        return [
          'Mantén los pies firmes en el suelo',
          'No arquees excesivamente la espalda',
          'Controla el descenso del peso'
        ];
      case ExerciseType.sentadillas:
        return [
          'Baja hasta que tus muslos estén paralelos al suelo',
          'Mantén el peso en los talones',
          'No permitas que las rodillas se vayan hacia adentro'
        ];
      case ExerciseType.flexiones:
        return [
          'Mantén el cuerpo en línea recta',
          'Baja hasta que el pecho casi toque el suelo',
          'Mantén los codos cerca del cuerpo'
        ];
      default:
        return [
          'Concéntrate en el control del movimiento',
          'Mantén una postura estable',
          'Respira de manera controlada'
        ];
    }
  }
}

class PostWorkoutAnalysis {
  final String aiAnalysis;
  final List<String> strengthsIdentified;
  final List<String> weaknessesIdentified;
  final String nextSessionFocus;
  final DateTime timestamp;
  final Map<String, dynamic> sessionStats;

  PostWorkoutAnalysis({
    required this.aiAnalysis,
    required this.strengthsIdentified,
    required this.weaknessesIdentified,
    required this.nextSessionFocus,
    DateTime? timestamp,
    Map<String, dynamic>? sessionStats,
  }) : timestamp = timestamp ?? DateTime.now(),
       sessionStats = sessionStats ?? {};

  Map<String, dynamic> toMap() {
    return {
      'aiAnalysis': aiAnalysis,
      'strengthsIdentified': strengthsIdentified,
      'weaknessesIdentified': weaknessesIdentified,
      'nextSessionFocus': nextSessionFocus,
      'timestamp': timestamp.toIso8601String(),
      'sessionStats': sessionStats,
    };
  }

  factory PostWorkoutAnalysis.fromMap(Map<String, dynamic> map) {
    return PostWorkoutAnalysis(
      aiAnalysis: map['aiAnalysis'] ?? '',
      strengthsIdentified: List<String>.from(map['strengthsIdentified'] ?? []),
      weaknessesIdentified: List<String>.from(map['weaknessesIdentified'] ?? []),
      nextSessionFocus: map['nextSessionFocus'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      sessionStats: Map<String, dynamic>.from(map['sessionStats'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'PostWorkoutAnalysis(aiAnalysis: $aiAnalysis, strengths: ${strengthsIdentified.length}, weaknesses: ${weaknessesIdentified.length})';
  }
}