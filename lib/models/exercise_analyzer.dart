// lib/services/exercise_analyzer.dart
import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/form_feedback.dart';

// 🧠 CLASE PRINCIPAL PARA ANALIZAR LA TÉCNICA DE EJERCICIOS
class ExerciseAnalyzer {
  // 📊 Contadores para detectar repeticiones
  int _repCount = 0;
  bool _isInDownPosition = false;
  double _lastAngle = 0.0;

  // 🎯 MÉTODO PRINCIPAL - Analizar cualquier ejercicio
  FormScore analyzeExerciseFrame(ExerciseType exerciseType, Pose pose) {
    try {
      // Convertir pose de ML Kit a nuestro formato
      final keypoints = _convertPoseToKeypoints(pose);

      // Verificar que tenemos suficientes puntos confiables
      final requiredPoints = exerciseType.keypoints;
      final visiblePoints = keypoints.where((kp) =>
      requiredPoints.contains(kp.name) && kp.isVisible
      ).length;

      if (visiblePoints < requiredPoints.length * 0.6) {
        // No hay suficientes puntos visibles
        return FormScore(
          score: 0.0,
          timestamp: DateTime.now(),
          confidence: 0.0,
        );
      }

      // Analizar según el tipo de ejercicio
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

  // 🏋️ ANÁLISIS ESPECÍFICO - PRESS DE PECHO PLANO
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

    // 1. Verificar simetría de hombros (deben estar alineados)
    final shoulderSymmetry = _calculateSymmetry(leftShoulder!.y, rightShoulder!.y);
    if (shoulderSymmetry < 0.85) {
      score -= 2.0; // Penalizar por hombros desalineados
    }

    // 2. Verificar ángulo del codo (debe estar entre 45-90 grados)
    final leftElbowAngle = _calculateAngle(leftShoulder, leftElbow!, leftWrist!);
    final rightElbowAngle = _calculateAngle(rightShoulder, rightElbow!, rightWrist!);
    final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    if (avgElbowAngle < 45 || avgElbowAngle > 90) {
      score -= 1.5; // Penalizar por rango de movimiento incorrecto
    }

    // 3. Verificar que las muñecas estén por encima de los codos
    if (leftWrist.y > leftElbow.y || rightWrist.y > rightElbow.y) {
      score -= 2.0; // Penalizar por muñecas caídas
    }

    // 4. Detectar repeticiones
    _detectRepetition(avgElbowAngle, 70.0); // Umbral para press de pecho

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  // 🦅 ANÁLISIS ESPECÍFICO - PECK DECK
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

    // 1. Verificar que los codos estén a la altura de los hombros
    final leftElbowHeight = (leftElbow!.y - leftShoulder!.y).abs();
    final rightElbowHeight = (rightElbow!.y - rightShoulder!.y).abs();

    if (leftElbowHeight > 50 || rightElbowHeight > 50) { // 50 píxeles de tolerancia
      score -= 2.5; // Penalizar por codos mal posicionados
    }

    // 2. Verificar simetría en el movimiento
    final symmetry = _calculateSymmetry(leftElbow.x, rightElbow.x);
    if (symmetry < 0.8) {
      score -= 2.0; // Penalizar por asimetría
    }

    // 3. Verificar rango de movimiento (los codos deben juntarse al frente)
    final elbowDistance = _calculateDistance(leftElbow, rightElbow);
    _detectRepetition(elbowDistance, 100.0); // Umbral para peck deck

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  // ⬆️ ANÁLISIS ESPECÍFICO - PRESS INCLINADO
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

    // 1. Verificar inclinación (las muñecas deben estar más altas que los hombros)
    if (leftWrist!.y >= leftShoulder!.y || rightWrist!.y >= rightShoulder!.y) {
      score -= 3.0; // Penalizar por falta de inclinación
    }

    // 2. Verificar ángulo del codo (similar al press plano pero más cerrado)
    final leftElbowAngle = _calculateAngle(leftShoulder, leftElbow!, leftWrist);
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

  // 💺 ANÁLISIS ESPECÍFICO - FONDOS (Vista desde atrás)
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

    // 1. Verificar que el torso esté vertical (hombros alineados con caderas)
    final leftTorsoAngle = _calculateAngle(leftShoulder!, leftHip!, BodyKeypoint(name: 'reference', x: leftHip.x, y: leftHip.y + 100, confidence: 1.0));
    final rightTorsoAngle = _calculateAngle(rightShoulder!, rightHip!, BodyKeypoint(name: 'reference', x: rightHip.x, y: rightHip.y + 100, confidence: 1.0));

    if (leftTorsoAngle < 80 || rightTorsoAngle < 80) {
      score -= 2.5; // Penalizar por inclinación del torso
    }

    // 2. Verificar profundidad del movimiento (codos deben flexionarse)
    final avgElbowHeight = (leftElbow!.y + rightElbow!.y) / 2;
    final avgShoulderHeight = (leftShoulder.y + rightShoulder.y) / 2;

    _detectRepetition(avgElbowHeight - avgShoulderHeight, 80.0);

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  // 💪 ANÁLISIS ESPECÍFICO - EXTENSIÓN DE TRÍCEPS (Vista lateral)
  FormScore _analyzeExtensionTriceps(List<BodyKeypoint> keypoints) {
    final leftShoulder = _getKeypoint(keypoints, 'leftShoulder');
    final leftElbow = _getKeypoint(keypoints, 'leftElbow');
    final leftWrist = _getKeypoint(keypoints, 'leftWrist');

    // Para vista lateral, usamos principalmente un lado
    if (!_allPointsVisible([leftShoulder, leftElbow, leftWrist])) {
      return FormScore(score: 0.0, timestamp: DateTime.now(), confidence: 0.0);
    }

    double score = 10.0;
    final confidence = _calculateAverageConfidence([leftShoulder, leftElbow, leftWrist]);

    // 1. Verificar que el codo esté estático (no debe moverse mucho)
    final elbowStability = _calculateDistance(leftShoulder!, leftElbow!);

    // 2. Verificar extensión completa del brazo
    final armAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist!);

    if (armAngle < 160) { // El brazo debe estar casi completamente extendido
      score -= (160 - armAngle) * 0.05; // Penalizar por extensión incompleta
    }

    // 3. Detectar repeticiones basadas en el ángulo del brazo
    _detectRepetition(armAngle, 140.0);

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  // 💪 ANÁLISIS ESPECÍFICO - EXTENSIÓN TRÍCEPS TRAS NUCA (Vista lateral)
  FormScore _analyzeExtensionTricepsTrasNuca(List<BodyKeypoint> keypoints) {
    final leftShoulder = _getKeypoint(keypoints, 'leftShoulder');
    final leftElbow = _getKeypoint(keypoints, 'leftElbow');
    final leftWrist = _getKeypoint(keypoints, 'leftWrist');

    if (!_allPointsVisible([leftShoulder, leftElbow, leftWrist])) {
      return FormScore(score: 0.0, timestamp: DateTime.now(), confidence: 0.0);
    }

    double score = 10.0;
    final confidence = _calculateAverageConfidence([leftShoulder, leftElbow, leftWrist]);

    // 1. Verificar que el codo esté alto (por encima del hombro)
    if (leftElbow!.y > leftShoulder!.y) {
      score -= 3.0; // Penalizar por codo bajo
    }

    // 2. Verificar que la muñeca vaya detrás de la cabeza
    final armAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist!);

    if (armAngle > 90) { // En la posición inferior, el ángulo debe ser agudo
      score -= 2.0;
    }

    // 3. Detectar repeticiones
    _detectRepetition(armAngle, 60.0);

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  // 🦵 ANÁLISIS ESPECÍFICO - SENTADILLAS (ya implementado, mejorado)
  FormScore _analyzeSentadillas(List<BodyKeypoint> keypoints) {
    final leftHip = _getKeypoint(keypoints, 'leftHip');
    final leftKnee = _getKeypoint(keypoints, 'leftKnee');
    final leftAnkle = _getKeypoint(keypoints, 'leftAnkle');
    final rightHip = _getKeypoint(keypoints, 'rightHip');
    final rightKnee = _getKeypoint(keypoints, 'rightKnee');
    final rightAnkle = _getKeypoint(keypoints, 'rightAnkle');

    if (!_allPointsVisible([leftHip, leftKnee, leftAnkle, rightHip, rightKnee, rightAnkle])) {
      return FormScore(score: 0.0, timestamp: DateTime.now(), confidence: 0.0);
    }

    double score = 10.0;
    final confidence = _calculateAverageConfidence([leftHip, leftKnee, leftAnkle, rightHip, rightKnee, rightAnkle]);

    // 1. Calcular ángulo de la rodilla
    final leftKneeAngle = _calculateAngle(leftHip!, leftKnee!, leftAnkle!);
    final rightKneeAngle = _calculateAngle(rightHip!, rightKnee!, rightAnkle!);
    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    // 2. Evaluar profundidad
    if (avgKneeAngle > 120) {
      score -= 3.0; // Muy poco profundo
    } else if (avgKneeAngle > 90) {
      score -= 1.0; // Podría bajar más
    }

    // 3. Detectar repeticiones
    _detectRepetition(avgKneeAngle, 100.0);

    return FormScore(
      score: math.max(0.0, score),
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  // 🤲 ANÁLISIS ESPECÍFICO - FLEXIONES
  FormScore _analyzeFlexiones(List<BodyKeypoint> keypoints) {
    final leftShoulder = _getKeypoint(keypoints, 'leftShoulder');
    final leftElbow = _getKeypoint(keypoints, 'leftElbow');
    final leftWrist = _getKeypoint(keypoints, 'leftWrist');
    final leftHip = _getKeypoint(keypoints, 'leftHip');

    if (!_allPointsVisible([leftShoulder, leftElbow, leftWrist, leftHip])) {
      return FormScore(score: 0.0, timestamp: DateTime.now(), confidence: 0.0);
    }

    double score = 10.0;
    final confidence = _calculateAverageConfidence([leftShoulder, leftElbow, leftWrist, leftHip]);

    // 1. Verificar alineación del cuerpo (hombro-cadera en línea recta)
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

  // 🌟 ANÁLISIS GENÉRICO - Para ejercicios no específicos
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

  // 🔧 MÉTODOS DE UTILIDAD

  List<BodyKeypoint> _convertPoseToKeypoints(Pose pose) {
    final keypoints = <BodyKeypoint>[];

    for (final landmark in pose.landmarks.entries) {
      keypoints.add(BodyKeypoint(
        name: landmark.key.name, // Los enums ya tienen .name en esta versión
        x: landmark.value.x,
        y: landmark.value.y,
        confidence: landmark.value.likelihood,
      ));
    }

    return keypoints;
  }

  BodyKeypoint? _getKeypoint(List<BodyKeypoint> keypoints, String name) {
    try {
      // Mapear nombres a los nombres correctos de la API
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
    // Lógica simple para detectar cuando se cruza un umbral
    if (!_isInDownPosition && currentValue < threshold) {
      _isInDownPosition = true;
    } else if (_isInDownPosition && currentValue > threshold) {
      _isInDownPosition = false;
      _repCount++;
    }
  }

  // 📊 GENERAR FEEDBACK FINAL DE LA SERIE
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

    // Filtrar solo scores confiables
    final reliableScores = scores.where((s) => s.isReliable).toList();

    if (reliableScores.isEmpty) {
      return FormFeedback(
        averageScore: 0.0,
        mainComment: 'La calidad de detección fue muy baja.',
        tips: ['Mejora la iluminación', 'Ponte más cerca de la cámara'],
        detailedScores: {},
        totalReps: 0,
      );
    }

    // Calcular puntaje promedio
    final avgScore = reliableScores
        .map((s) => s.score)
        .reduce((a, b) => a + b) / reliableScores.length;

    // Generar comentario principal
    String mainComment = _generateMainComment(avgScore, exerciseType);

    // Generar tips específicos
    List<String> tips = _generateTips(avgScore, exerciseType);

    return FormFeedback(
      averageScore: avgScore,
      mainComment: mainComment,
      tips: tips,
      detailedScores: {
        'Técnica General': avgScore,
        'Consistencia': _calculateConsistency(reliableScores),
      },
      totalReps: _repCount,
    );
  }

  String _generateMainComment(double score, ExerciseType exerciseType) {
    if (score >= 9.0) return '¡Técnica excelente! Mantén esa forma perfecta.';
    if (score >= 7.5) return 'Muy buena técnica, solo pequeños ajustes.';
    if (score >= 6.0) return 'Técnica sólida, hay espacio para mejorar.';
    if (score >= 4.5) return 'Técnica decente, enfócate en los fundamentos.';
    return 'Necesitas trabajar en la técnica básica.';
  }

  List<String> _generateTips(double score, ExerciseType exerciseType) {
    List<String> tips = [];

    if (score < 7.0) {
      switch (exerciseType) {
        case ExerciseType.pressPlano:
        case ExerciseType.pressInclinado:
          tips.addAll([
            'Mantén los hombros hacia atrás y abajo',
            'Controla la bajada de la barra',
            'Mantén las muñecas firmes y rectas'
          ]);
          break;
        case ExerciseType.fondos:
          tips.addAll([
            'Mantén el torso vertical',
            'Baja hasta que los codos estén a 90°',
            'Sube de forma controlada'
          ]);
          break;
        case ExerciseType.extensionTriceps:
        case ExerciseType.extensionTricepsTrasNuca:
          tips.addAll([
            'Mantén los codos quietos',
            'Extiende completamente el brazo',
            'Controla el peso en la bajada'
          ]);
          break;
        default:
          tips.add('Enfócate en el control y la forma');
      }
    }

    if (tips.isEmpty) {
      tips.add('¡Sigue así! Tu técnica está mejorando.');
    }

    return tips;
  }

  double _calculateConsistency(List<FormScore> scores) {
    if (scores.length < 2) return 10.0;

    final variance = _calculateVariance(scores.map((s) => s.score).toList());
    return math.max(0.0, 10.0 - variance);
  }

  double _calculateVariance(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((x) => math.pow(x - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    return variance;
  }

  // 🔄 Resetear contadores para nueva serie
  void resetForNewSet() {
    _repCount = 0;
    _isInDownPosition = false;
    _lastAngle = 0.0;
  }

  // 📊 Obtener estadísticas actuales
  int get currentRepCount => _repCount;
}