// lib/models/form_score.dart
import 'package:flutter/material.dart';

class FormScore {
  final double score;           // Puntuación 0.0 - 10.0
  final DateTime timestamp;    // Cuándo se calculó
  final double confidence;     // Qué tan confiable es (0.0 - 1.0)
  final String? feedback;      // Mensaje opcional

  FormScore({
    required this.score,
    required this.timestamp,
    required this.confidence,
    this.feedback,
  });

  bool get isReliable => confidence > 0.6;

  Color get color {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    if (score >= 4.0) return Colors.yellow;
    return Colors.red;
  }

  String get message {
    if (feedback != null) return feedback!;

    if (score >= 9.0) return '¡Técnica perfecta! 🔥';
    if (score >= 8.0) return '¡Excelente forma! 💪';
    if (score >= 7.0) return 'Muy bien, pequeños ajustes';
    if (score >= 6.0) return 'Buen trabajo, sigue así';
    if (score >= 5.0) return 'Mejorando, enfócate en la técnica';
    if (score >= 4.0) return 'Sigue practicando';
    return 'Revisa tu postura';
  }

  String get emoji {
    if (score >= 8.0) return '🔥';
    if (score >= 6.0) return '💪';
    if (score >= 4.0) return '👍';
    return '⚠️';
  }

  String get level {
    if (score >= 9.0) return 'PERFECTO';
    if (score >= 8.0) return 'EXCELENTE';
    if (score >= 7.0) return 'MUY BUENO';
    if (score >= 6.0) return 'BUENO';
    if (score >= 5.0) return 'REGULAR';
    return 'NECESITA MEJORA';
  }

  @override
  String toString() {
    return 'FormScore(score: $score, confidence: $confidence, timestamp: $timestamp)';
  }
}