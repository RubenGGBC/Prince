// lib/models/exercise_analyzer.dart
import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/form_feedback.dart' hide FormScore;
import '../models/form_score.dart';

class ExerciseAnalyzer {
  int _repCount = 0;
  bool _isInDownPosition = false;
  double _lastAngle = 0.0;

  int get currentRepCount => _repCount;

  void resetForNewSet() {
    _repCount = 0;
    _isInDownPosition = false;
    _lastAngle = 0.0;
  }

  FormScore analyzeExerciseFrame(ExerciseType exerciseType, Pose pose) {
    try {
      final keypoints = _convertPoseToKeypoints(pose);

      final requiredPoints = exerciseType.keypoints;
      final visiblePoints = keypoints.where((kp) =>
      requiredPoints.contains(kp.name) && kp.isVisible
      ).length;

      if (visiblePoints < requiredPoints.length * 0.6) {
        return FormScore(
          score: 0.0,
          timestamp: DateTime.now(),
          confidence: 0.0,
        );
      }

      switch (exerciseType) {
        case ExerciseType.pressPlano:
          return _analyzePressPlano(keypoints);
        case ExerciseType.peckDeck:
          return _analyzePeckDeck(keypoints);
        case ExerciseType.pressInclinado:
          return _analyzePressInclinado(keypoints);
        case ExerciseType.fondos:
          return _analyzeFondos(keypoints);
        case ExerciseType.extensionTriceps:
          return _analyzeExtensionTriceps(keypoints);
        case ExerciseType.extensionTricepsTrasNuca:
          return _analyzeExtensionTricepsTrasNuca(keypoints);
        case ExerciseType.sentadillas:
          return _analyzeSentadillas(keypoints);
        case ExerciseType.flexiones:
          return _analyzeFlexiones(keypoints);
        default:
          return _analyzeGenerico(keypoints);
      }
    } catch (e) {
      print('❌ Error analizando ejercicio: $e');
      return FormScore(
        score: 0.0,
        timestamp: DateTime.now(),
        confidence: 0.0,
      );
    }
  }

  // 🏋️ ANÁLISIS ESPECÍFICOS POR EJERCICIO

  FormScore _analyzePressPlano(List<BodyKeypoint> keypoints) {
    final leftShoulder = _getKeypoint(keypoints, 'leftShoulder');
    final rightShoulder = _getKeypoint(keypoints, 'rightShoulder');
    final leftElbow = _getKeypoint(keypoints, 'leftElbow');
    final rightElbow = _getKeypoint(keypoints, 'rightElbow');
    final leftWrist = _getKeypoint(keypoints, 'leftWrist');
    final rightWrist = _getKeypoint(keypoints, 'rightWrist');

    if (!_allPointsVisible([leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist])) {
      return FormScore(score: 0.0, timestamp: DateTime.now(), confidence: 0.0);
    }

    double score = 10.0;
    final confidence = _calculateAverageConfidence([leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist]);

    // 1. Verificar simetría de los brazos
    final leftElbowAngle = _calculateAngle(leftShoulder!, leftElbow!, leftWrist!);
    final rightElbowAngle = _calculateAngle(rightShoulder!, rightElbow!, rightWrist!);
    final symmetry = _calculateSymmetry(leftElbowAngle, rightElbowAngle);

    if (symmetry < 0.8) {
      score -= 2.0; // Penalizar por asimetría
    }

    // 2. Verificar rango de movimiento
    final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    if (avgElbowAngle < 60 || avgElbowAngle > 120) {
      score -= 1.5; // Rango óptimo
    }

    // 3. Detectar repeticiones
    _detectRepetition(avgElbowAngle, 90.0);

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  FormScore _analyzePeckDeck(List<BodyKeypoint> keypoints) {
    final leftShoulder = _getKeypoint(keypoints, 'leftShoulder');
    final rightShoulder = _getKeypoint(keypoints, 'rightShoulder');
    final leftElbow = _getKeypoint(keypoints, 'leftElbow');
    final rightElbow = _getKeypoint(keypoints, 'rightElbow');

    if (!_allPointsVisible([leftShoulder, rightShoulder, leftElbow, rightElbow])) {
      return FormScore(score: 0.0, timestamp: DateTime.now(), confidence: 0.0);
    }

    double score = 10.0;
    final confidence = _calculateAverageConfidence([leftShoulder, rightShoulder, leftElbow, rightElbow]);

    // 1. Verificar que los codos estén a nivel de los hombros
    final leftElbowHeight = leftElbow!.y - leftShoulder!.y;
    final rightElbowHeight = rightElbow!.y - rightShoulder!.y;

    if (leftElbowHeight.abs() > 50 || rightElbowHeight.abs() > 50) {
      score -= 2.0; // Los codos deben estar cerca del nivel de los hombros
    }

    // 2. Verificar apertura de brazos
    final armDistance = _calculateDistance(leftElbow, rightElbow);
    _detectRepetition(armDistance, 200.0); // Distancia promedio

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  FormScore _analyzePressInclinado(List<BodyKeypoint> keypoints) {
    final leftShoulder = _getKeypoint(keypoints, 'leftShoulder');
    final rightShoulder = _getKeypoint(keypoints, 'rightShoulder');
    final leftElbow = _getKeypoint(keypoints, 'leftElbow');
    final rightElbow = _getKeypoint(keypoints, 'rightElbow');
    final leftWrist = _getKeypoint(keypoints, 'leftWrist');
    final rightWrist = _getKeypoint(keypoints, 'rightWrist');

    if (!_allPointsVisible([leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist])) {
      return FormScore(score: 0.0, timestamp: DateTime.now(), confidence: 0.0);
    }

    double score = 10.0;
    final confidence = _calculateAverageConfidence([leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist]);

    // 1. Verificar ángulo inclinado (30-45 grados)
    final bodyAngle = _calculateAngle(leftShoulder!, BodyKeypoint(name: 'temp', x: leftShoulder.x, y: leftShoulder.y + 100, confidence: 1.0), rightShoulder!);

    if (bodyAngle < 30 || bodyAngle > 60) {
      score -= 1.5; // Inclinación incorrecta
    }

    // 2. Verificar ángulo del codo (similar al press plano pero más cerrado)
    final leftElbowAngle = _calculateAngle(leftShoulder, leftElbow!, leftWrist!);
    final rightElbowAngle = _calculateAngle(rightShoulder!, rightElbow!, rightWrist!);
    final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    if (avgElbowAngle < 30 || avgElbowAngle > 80) {
      score -= 2.0; // Rango más específico para inclinado
    }

    // 3. Detectar repeticiones
    _detectRepetition(avgElbowAngle, 60.0);

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  FormScore _analyzeFondos(List<BodyKeypoint> keypoints) {
    final leftShoulder = _getKeypoint(keypoints, 'leftShoulder');
    final rightShoulder = _getKeypoint(keypoints, 'rightShoulder');
    final leftElbow = _getKeypoint(keypoints, 'leftElbow');
    final rightElbow = _getKeypoint(keypoints, 'rightElbow');
    final leftHip = _getKeypoint(keypoints, 'leftHip');
    final rightHip = _getKeypoint(keypoints, 'rightHip');

    if (!_allPointsVisible([leftShoulder, rightShoulder, leftElbow, rightElbow, leftHip, rightHip])) {
      return FormScore(score: 0.0, timestamp: DateTime.now(), confidence: 0.0);
    }

    double score = 10.0;
    final confidence = _calculateAverageConfidence([leftShoulder, rightShoulder, leftElbow, rightElbow, leftHip, rightHip]);

    // 1. Verificar que el torso esté vertical
    final leftTorsoAngle = _calculateAngle(leftShoulder!, leftHip!, BodyKeypoint(name: 'reference', x: leftHip.x, y: leftHip.y + 100, confidence: 1.0));
    final rightTorsoAngle = _calculateAngle(rightShoulder!, rightHip!, BodyKeypoint(name: 'reference', x: rightHip.x, y: rightHip.y + 100, confidence: 1.0));

    if (leftTorsoAngle < 80 || rightTorsoAngle < 80) {
      score -= 2.5; // Penalizar por inclinación del torso
    }

    // 2. Verificar profundidad del movimiento
    final avgElbowHeight = (leftElbow!.y + rightElbow!.y) / 2;
    final avgShoulderHeight = (leftShoulder.y + rightShoulder.y) / 2;

    _detectRepetition(avgElbowHeight - avgShoulderHeight, 80.0);

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  FormScore _analyzeExtensionTriceps(List<BodyKeypoint> keypoints) {
    final leftShoulder = _getKeypoint(keypoints, 'leftShoulder');
    final leftElbow = _getKeypoint(keypoints, 'leftElbow');
    final leftWrist = _getKeypoint(keypoints, 'leftWrist');

    if (!_allPointsVisible([leftShoulder, leftElbow, leftWrist])) {
      return FormScore(score: 0.0, timestamp: DateTime.now(), confidence: 0.0);
    }

    double score = 10.0;
    final confidence = _calculateAverageConfidence([leftShoulder, leftElbow, leftWrist]);

    // 1. Verificar extensión completa del brazo
    final armAngle = _calculateAngle(leftShoulder!, leftElbow!, leftWrist!);

    if (armAngle < 160) {
      score -= (160 - armAngle) * 0.05; // Penalizar por extensión incompleta
    }

    // 2. Detectar repeticiones
    _detectRepetition(armAngle, 140.0);

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  FormScore _analyzeExtensionTricepsTrasNuca(List<BodyKeypoint> keypoints) {
    final leftShoulder = _getKeypoint(keypoints, 'leftShoulder');
    final leftElbow = _getKeypoint(keypoints, 'leftElbow');
    final leftWrist = _getKeypoint(keypoints, 'leftWrist');

    if (!_allPointsVisible([leftShoulder, leftElbow, leftWrist])) {
      return FormScore(score: 0.0, timestamp: DateTime.now(), confidence: 0.0);
    }

    double score = 10.0;
    final confidence = _calculateAverageConfidence([leftShoulder, leftElbow, leftWrist]);

    // 1. Verificar que el codo esté por encima de la cabeza
    if (leftElbow!.y > leftShoulder!.y) {
      score -= 3.0; // El codo debe estar elevado
    }

    // 2. Verificar rango de movimiento tras la nuca
    final armAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist!);

    if (armAngle < 60 || armAngle > 150) {
      score -= 2.0; // Rango específico para tras nuca
    }

    _detectRepetition(armAngle, 90.0);

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  FormScore _analyzeSentadillas(List<BodyKeypoint> keypoints) {
    final leftHip = _getKeypoint(keypoints, 'leftHip');
    final rightHip = _getKeypoint(keypoints, 'rightHip');
    final leftKnee = _getKeypoint(keypoints, 'leftKnee');
    final rightKnee = _getKeypoint(keypoints, 'rightKnee');
    final leftAnkle = _getKeypoint(keypoints, 'leftAnkle');
    final rightAnkle = _getKeypoint(keypoints, 'rightAnkle');

    if (!_allPointsVisible([leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle])) {
      return FormScore(score: 0.0, timestamp: DateTime.now(), confidence: 0.0);
    }

    double score = 10.0;
    final confidence = _calculateAverageConfidence([leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle]);

    // 1. Verificar profundidad de la sentadilla
    final leftKneeAngle = _calculateAngle(leftHip!, leftKnee!, leftAnkle!);
    final rightKneeAngle = _calculateAngle(rightHip!, rightKnee!, rightAnkle!);
    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    if (avgKneeAngle > 120) {
      score -= 3.0; // Debe bajar más
    } else if (avgKneeAngle < 70) {
      score -= 1.0; // Muy profunda
    }

    // 2. Verificar simetría de las piernas
    final symmetry = _calculateSymmetry(leftKneeAngle, rightKneeAngle);
    if (symmetry < 0.85) {
      score -= 2.0;
    }

    // 3. Detectar repeticiones
    _detectRepetition(avgKneeAngle, 100.0);

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  FormScore _analyzeFlexiones(List<BodyKeypoint> keypoints) {
    final leftShoulder = _getKeypoint(keypoints, 'leftShoulder');
    final rightShoulder = _getKeypoint(keypoints, 'rightShoulder');
    final leftElbow = _getKeypoint(keypoints, 'leftElbow');
    final rightElbow = _getKeypoint(keypoints, 'rightElbow');
    final leftWrist = _getKeypoint(keypoints, 'leftWrist');
    final rightWrist = _getKeypoint(keypoints, 'rightWrist');
    final leftHip = _getKeypoint(keypoints, 'leftHip');
    final rightHip = _getKeypoint(keypoints, 'rightHip');

    if (!_allPointsVisible([leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist, leftHip, rightHip])) {
      return FormScore(score: 0.0, timestamp: DateTime.now(), confidence: 0.0);
    }

    double score = 10.0;
    final confidence = _calculateAverageConfidence([leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist, leftHip, rightHip]);

    // 1. Verificar alineación del cuerpo
    final bodyAngle = _calculateAngle(leftShoulder!, leftHip!, BodyKeypoint(name: 'reference', x: leftHip.x, y: leftHip.y + 100, confidence: 1.0));

    if (bodyAngle < 170) {
      score -= 2.5; // Penalizar por cuerpo no recto
    }

    // 2. Verificar profundidad del movimiento
    final armAngle = _calculateAngle(leftShoulder, leftElbow!, leftWrist!);
    _detectRepetition(armAngle, 90.0);

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  FormScore _analyzeGenerico(List<BodyKeypoint> keypoints) {
    final visiblePoints = keypoints.where((kp) => kp.isVisible).length;
    final confidence = keypoints.isNotEmpty ? _calculateAverageConfidence(keypoints.map((kp) => kp as BodyKeypoint?).toList()) : 0.0;

    // Puntaje básico basado en cuántos puntos son visibles
    final score = (visiblePoints / keypoints.length) * 10.0;

    return FormScore(
      score: score,
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }


  List<BodyKeypoint> _convertPoseToKeypoints(Pose pose) {
    final keypoints = <BodyKeypoint>[];

    for (final landmark in pose.landmarks.entries) {
      keypoints.add(BodyKeypoint(
        name: landmark.key.name,
        x: landmark.value.x,
        y: landmark.value.y,
        confidence: landmark.value.likelihood,
      ));
    }

    return keypoints;
  }

  BodyKeypoint? _getKeypoint(List<BodyKeypoint> keypoints, String name) {
    try {
      final nameMapping = {
        'leftShoulder': 'leftShoulder',
        'rightShoulder': 'rightShoulder',
        'leftElbow': 'leftElbow',
        'rightElbow': 'rightElbow',
        'leftWrist': 'leftWrist',
        'rightWrist': 'rightWrist',
        'leftHip': 'leftHip',
        'rightHip': 'rightHip',
        'leftKnee': 'leftKnee',
        'rightKnee': 'rightKnee',
        'leftAnkle': 'leftAnkle',
        'rightAnkle': 'rightAnkle',
      };

      final mappedName = nameMapping[name] ?? name;
      return keypoints.firstWhere((kp) => kp.name == mappedName);
    } catch (e) {
      print('⚠️ Keypoint no encontrado: $name');
      return null;
    }
  }

  bool _allPointsVisible(List<BodyKeypoint?> points) {
    return points.every((point) => point != null && point!.isVisible);
  }

  double _calculateAverageConfidence(List<BodyKeypoint?> points) {
    final validPoints = points.where((point) => point != null).cast<BodyKeypoint>();
    if (validPoints.isEmpty) return 0.0;
    final sum = validPoints.fold(0.0, (sum, point) => sum + point.confidence);
    return sum / validPoints.length;
  }

  double _calculateAngle(BodyKeypoint point1, BodyKeypoint point2, BodyKeypoint point3) {
    final vector1 = [point1.x - point2.x, point1.y - point2.y];
    final vector2 = [point3.x - point2.x, point3.y - point2.y];

    final dotProduct = vector1[0] * vector2[0] + vector1[1] * vector2[1];
    final magnitude1 = math.sqrt(vector1[0] * vector1[0] + vector1[1] * vector1[1]);
    final magnitude2 = math.sqrt(vector2[0] * vector2[0] + vector2[1] * vector2[1]);

    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    final angleRadians = math.acos(cosAngle.clamp(-1.0, 1.0));

    return angleRadians * 180 / math.pi;
  }

  double _calculateDistance(BodyKeypoint point1, BodyKeypoint point2) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  double _calculateSymmetry(double value1, double value2) {
    final diff = (value1 - value2).abs();
    final avg = (value1 + value2) / 2;
    return avg > 0 ? 1.0 - (diff / avg) : 0.0;
  }

  void _detectRepetition(double currentValue, double threshold) {
    if (!_isInDownPosition && currentValue < threshold) {
      _isInDownPosition = true;
    } else if (_isInDownPosition && currentValue > threshold) {
      _isInDownPosition = false;
      _repCount++;
      print('🔄 Repetición detectada: $_repCount');
    }
  }

  FormFeedback generateSeriesFeedback(List<FormScore> scores, ExerciseType exerciseType) {
    if (scores.isEmpty) {
      return FormFeedback(
        averageScore: 0.0,
        mainComment: 'No se pudo analizar la técnica en esta serie.',
        tips: ['Asegúrate de estar bien posicionado frente a la cámara'],
        detailedScores: {},
        totalReps: 0,
      );
    }

    final reliableScores = scores.where((s) => s.isReliable).toList();

    if (reliableScores.isEmpty) {
      return FormFeedback(
        averageScore: 0.0,
        mainComment: 'La calidad de detección fue muy baja.',
        tips: ['Mejora la iluminación', 'Asegúrate de estar completamente visible'],
        detailedScores: {},
        totalReps: 0,
      );
    }

    final averageScore = reliableScores.map((s) => s.score).reduce((a, b) => a + b) / reliableScores.length;
    final maxScore = reliableScores.map((s) => s.score).reduce(math.max);
    final minScore = reliableScores.map((s) => s.score).reduce(math.min);

    // Generar comentario principal
    String mainComment;
    if (averageScore >= 8.5) {
      mainComment = '¡Técnica excelente! Sigue así. 🔥';
    } else if (averageScore >= 7.0) {
      mainComment = '¡Muy bien! Solo pequeños ajustes. 💪';
    } else if (averageScore >= 5.5) {
      mainComment = 'Buen trabajo, puedes mejorar más. 👍';
    } else if (averageScore >= 4.0) {
      mainComment = 'Vas por buen camino, sigue practicando. 🎯';
    } else {
      mainComment = 'Enfócate en la técnica más que en el peso. 📚';
    }

    // Generar tips específicos
    final tips = <String>[];
    if (averageScore < 6.0) {
      tips.add('Concéntrate en el control del movimiento');
    }
    if (maxScore - minScore > 3.0) {
      tips.add('Trata de mantener consistencia en toda la serie');
    }
    if (averageScore >= 8.0) {
      tips.add('¡Excelente forma! Considera aumentar el peso gradualmente');
    }

    return FormFeedback(
      averageScore: averageScore,
      mainComment: mainComment,
      tips: tips,
      detailedScores: {
        'promedio': averageScore,
        'máximo': maxScore,
        'mínimo': minScore,
        'consistencia': maxScore - minScore,
      },
      totalReps: _repCount,
    );
  }
}