// lib/services/ai_form_coach.dart
import 'dart:convert';
import '../models/form_feedback.dart';
import '../models/form_score.dart';
import '../domain/exercise.dart';
import '../domain/user.dart';
import 'gemini_service.dart';

/// 🤖 ENTRENADOR IA HÍBRIDO - ML Kit + PrinceIA
class AIFormCoach {
  final GeminiService _geminiService = GeminiService();

  // 📊 Histórico de análisis para aprendizaje
  final List<WorkoutAnalysis> _analysisHistory = [];
  final List<String> _userWeaknesses = [];
  final Map<String, List<double>> _exerciseProgress = {};

  /// 🎯 ANÁLISIS PRE-ENTRENAMIENTO
  Future<PreWorkoutAdvice> getPreWorkoutAdvice(Exercise exercise, User user) async {
    try {
      // Construir contexto basado en historial
      final historyContext = _buildHistoryContext(exercise.nombre);
      final userContext = _buildUserContext(user);

      final prompt = '''
Como PrinceIA, analiza este ejercicio que el usuario está a punto de realizar:

**EJERCICIO:** ${exercise.nombre}
**USUARIO:** $userContext
**HISTORIAL RECIENTE:** $historyContext

Proporciona un consejo PRE-entrenamiento específico que incluya:
1. 🎯 Punto clave técnico para este ejercicio
2. 🚨 Error más común a evitar
3. 🧘 Consejo mental/respiración
4. 💡 Tip personalizado basado en su historial

Respuesta: máximo 150 palabras, tono motivador pero técnico.
''';

      final aiResponse = await _geminiService.sendMessage(prompt);

      return PreWorkoutAdvice(
        exerciseName: exercise.nombre,
        aiAdvice: aiResponse,
        focusPoints: _extractFocusPoints(exercise.nombre),
        personalizedTips: _getPersonalizedTips(exercise.nombre),
      );

    } catch (e) {
      print('❌ Error obteniendo consejo pre-entrenamiento: $e');
      return PreWorkoutAdvice.fallback(exercise.nombre);
    }
  }

  /// 💪 ANÁLISIS EN TIEMPO REAL
  Future<RealTimeCoaching> getRealTimeCoaching(FormScore currentScore, Exercise exercise) async {
    try {
      if (!currentScore.isReliable) {
        return RealTimeCoaching.notReliable();
      }

      // Generar coaching según puntuación
      String coachingMessage;
      String motivation;

      if (currentScore.score >= 8.0) {
        coachingMessage = _getExcellentFormMessage(exercise.nombre);
        motivation = "🔥 ¡Técnica perfecta! Sigue así";
      } else if (currentScore.score >= 6.0) {
        coachingMessage = _getGoodFormMessage(exercise.nombre);
        motivation = "💪 Muy bien, pequeños ajustes";
      } else if (currentScore.score >= 4.0) {
        coachingMessage = _getImprovementMessage(exercise.nombre);
        motivation = "🎯 Concéntrate en la técnica";
      } else {
        coachingMessage = _getCorrectionMessage(exercise.nombre);
        motivation = "⚡ Vamos paso a paso";
      }

      return RealTimeCoaching(
        message: coachingMessage,
        motivation: motivation,
        score: currentScore.score,
        isPositive: currentScore.score >= 6.0,
      );

    } catch (e) {
      print('❌ Error en coaching tiempo real: $e');
      return RealTimeCoaching.error();
    }
  }

  /// 📋 ANÁLISIS POST-ENTRENAMIENTO CON IA
  Future<PostWorkoutAnalysis> getPostWorkoutAnalysis(
      FormFeedback feedback,
      Exercise exercise,
      int actualReps,
      double sessionDuration,
      ) async {
    try {
      // Guardar análisis para aprendizaje
      final analysis = WorkoutAnalysis(
        exercise: exercise,
        feedback: feedback,
        actualReps: actualReps,
        duration: sessionDuration,
        timestamp: DateTime.now(),
      );
      _analysisHistory.add(analysis);
      _updateProgressTracking(exercise.nombre, feedback.averageScore);

      // Construir prompt detallado para PrinceIA
      final prompt = '''
Como PrinceIA, analiza estos resultados del entrenamiento:

**EJERCICIO:** ${exercise.nombre}
**DURACIÓN:** ${sessionDuration.toStringAsFixed(1)} segundos
**REPETICIONES PLANIFICADAS:** ${exercise.repeticiones}
**REPETICIONES DETECTADAS:** ${feedback.totalReps}
**PUNTUACIÓN TÉCNICA:** ${feedback.averageScore.toStringAsFixed(1)}/10

**ANÁLISIS DETALLADO:**
- Puntuación promedio: ${feedback.averageScore.toStringAsFixed(1)}
- Consistencia: ${feedback.detailedScores['consistencia']?.toStringAsFixed(1) ?? 'N/A'}
- Puntos fuertes: ${feedback.tips.where((tip) => tip.contains('bien') || tip.contains('excelente')).join(', ')}
- Áreas de mejora: ${feedback.tips.where((tip) => !tip.contains('bien') && !tip.contains('excelente')).join(', ')}

**HISTORIAL RECIENTE:** ${_getRecentPerformance(exercise.nombre)}

Proporciona un análisis completo que incluya:
1. 📊 Evaluación general del set
2. 🎯 3 puntos específicos para mejorar
3. 💡 Plan de acción para la próxima sesión
4. 🚀 Motivación personalizada

Tono: entrenador experto pero empático. Máximo 200 palabras.
''';

      final aiAnalysis = await _geminiService.sendMessage(prompt);

      // Detectar patrones y debilidades
      _analyzePatterns();

      return PostWorkoutAnalysis(
        aiAnalysis: aiAnalysis,
        improvementPlan: await _generateImprovementPlan(exercise),
        strengthsIdentified: _identifyStrengths(feedback),
        weaknessesIdentified: _identifyWeaknesses(feedback),
        nextSessionFocus: _getNextSessionFocus(exercise.nombre),
        motivationalMessage: _generateMotivationalMessage(feedback.averageScore),
      );

    } catch (e) {
      print('❌ Error en análisis post-entrenamiento: $e');
      return PostWorkoutAnalysis.error();
    }
  }

  /// 🧠 PLAN PERSONALIZADO DE MEJORA
  Future<String> generateImprovementPlan(List<String> weaknesses) async {
    try {
      final prompt = '''
Como PrinceIA, crea un plan de mejora personalizado:

**DEBILIDADES IDENTIFICADAS:**
${weaknesses.map((w) => '- $w').join('\n')}

**HISTORIAL DE EJERCICIOS:** ${_getExerciseHistory()}

Crea un plan que incluya:
1. 🎯 Ejercicios correctivos específicos
2. 📅 Frecuencia de práctica recomendada
3. 🎥 Técnicas de visualización
4. 📈 Métricas para medir progreso

Formato: práctico y accionable. Máximo 180 palabras.
''';

      return await _geminiService.sendMessage(prompt);

    } catch (e) {
      print('❌ Error generando plan de mejora: $e');
      return _getFallbackImprovementPlan(weaknesses);
    }
  }

  /// 📈 ANÁLISIS DE PROGRESO A LARGO PLAZO
  Future<String> getProgressAnalysis(int days) async {
    try {
      final recentAnalysis = _analysisHistory
          .where((a) => a.timestamp.isAfter(DateTime.now().subtract(Duration(days: days))))
          .toList();

      if (recentAnalysis.isEmpty) {
        return "📊 **Análisis de Progreso**\n\nNecesitas más datos para generar un análisis completo. ¡Sigue entrenando! 💪";
      }

      final avgScore = recentAnalysis
          .map((a) => a.feedback.averageScore)
          .reduce((a, b) => a + b) / recentAnalysis.length;

      final prompt = '''
Como PrinceIA, analiza el progreso de los últimos $days días:

**ENTRENAMIENTOS ANALIZADOS:** ${recentAnalysis.length}
**PUNTUACIÓN PROMEDIO:** ${avgScore.toStringAsFixed(1)}/10
**EJERCICIOS PRACTICADOS:** ${recentAnalysis.map((a) => a.exercise.nombre).toSet().join(', ')}
**TENDENCIA:** ${_calculateTrend(recentAnalysis)}

**DEBILIDADES RECURRENTES:** ${_userWeaknesses.join(', ')}

Proporciona:
1. 📈 Evaluación del progreso
2. 🎯 Logros destacados
3. 🚀 Próximos objetivos
4. 💡 Recomendaciones estratégicas

Tono: motivador y constructivo. Máximo 250 palabras.
''';

      return await _geminiService.sendMessage(prompt);

    } catch (e) {
      print('❌ Error en análisis de progreso: $e');
      return _getFallbackProgressAnalysis(days);
    }
  }

  /// 🎙️ COACHING DE VOZ EN TIEMPO REAL
  String getVoiceCoaching(FormScore score, Exercise exercise) {
    if (!score.isReliable) return "";

    if (score.score >= 8.5) {
      return "¡Perfecto! Mantén esa técnica";
    } else if (score.score >= 7.0) {
      return "Muy bien, pequeños ajustes";
    } else if (score.score >= 5.0) {
      return "Concéntrate en el control";
    } else {
      return "Vamos más despacio, técnica primero";
    }
  }

  // MÉTODOS PRIVADOS DE ANÁLISIS

  String _buildHistoryContext(String exerciseName) {
    final recentSessions = _analysisHistory
        .where((a) => a.exercise.nombre == exerciseName)
        .take(3)
        .toList();

    if (recentSessions.isEmpty) {
      return "Primera vez realizando este ejercicio";
    }

    final avgScore = recentSessions
        .map((s) => s.feedback.averageScore)
        .reduce((a, b) => a + b) / recentSessions.length;

    return "Últimas sesiones promedio: ${avgScore.toStringAsFixed(1)}/10";
  }

  String _buildUserContext(User user) {
    return "Nivel: ${user.experienceLevel ?? 'Principiante'}, "
        "Objetivos: ${user.goals?.join(', ') ?? 'Fitness general'}";
  }

  List<String> _extractFocusPoints(String exerciseName) {
    final focusMap = {
      'flexiones': ['Cuerpo en línea recta', 'Codos cerca del cuerpo', 'Descenso controlado'],
      'sentadillas': ['Pies al ancho de hombros', 'Peso en talones', 'Rodillas alineadas'],
      'press de pecho': ['Hombros estables', 'Rango completo', 'Control excéntrico'],
    };

    return focusMap[exerciseName.toLowerCase()] ?? ['Técnica correcta', 'Control del movimiento', 'Respiración constante'];
  }

  List<String> _getPersonalizedTips(String exerciseName) {
    final weaknessesForExercise = _userWeaknesses
        .where((w) => w.toLowerCase().contains(exerciseName.toLowerCase()))
        .toList();

    if (weaknessesForExercise.isNotEmpty) {
      return ["Enfócate en: ${weaknessesForExercise.first}"];
    }

    return ["Mantén la concentración durante todo el movimiento"];
  }

  void _updateProgressTracking(String exerciseName, double score) {
    if (!_exerciseProgress.containsKey(exerciseName)) {
      _exerciseProgress[exerciseName] = [];
    }

    _exerciseProgress[exerciseName]!.add(score);

    // Mantener solo las últimas 10 sesiones
    if (_exerciseProgress[exerciseName]!.length > 10) {
      _exerciseProgress[exerciseName]!.removeAt(0);
    }
  }

  void _analyzePatterns() {
    // Detectar patrones de debilidades recurrentes
    final recentAnalysis = _analysisHistory.take(10).toList();
    final commonIssues = <String>[];

    for (final analysis in recentAnalysis) {
      if (analysis.feedback.averageScore < 6.0) {
        commonIssues.addAll(analysis.feedback.tips);
      }
    }

    // Identificar los 3 problemas más comunes
    final issueCount = <String, int>{};
    for (final issue in commonIssues) {
      issueCount[issue] = (issueCount[issue] ?? 0) + 1;
    }

    _userWeaknesses.clear();
    _userWeaknesses.addAll(
        issueCount.entries
            .where((entry) => entry.value >= 2)
            .map((entry) => entry.key)
            .take(3)
    );
  }

  String _getExcellentFormMessage(String exerciseName) {
    final messages = [
      "¡Técnica impecable! 🔥",
      "¡Perfecto control! 💪",
      "¡Esa es la forma correcta! ⭐",
      "¡Excelente ejecución! 🎯",
    ];
    return messages[DateTime.now().second % messages.length];
  }

  String _getGoodFormMessage(String exerciseName) {
    final messages = [
      "¡Muy bien! Pequeños ajustes 👍",
      "¡Buen trabajo! Mantén el control 💪",
      "¡Sigue así! Casi perfecto 🎯",
      "¡Genial! Puliendo detalles ⚡",
    ];
    return messages[DateTime.now().second % messages.length];
  }

  String _getImprovementMessage(String exerciseName) {
    final messages = [
      "Concéntrate en el control 🎯",
      "Vamos más despacio 🧘",
      "Técnica sobre velocidad 📐",
      "Respira y controla 💨",
    ];
    return messages[DateTime.now().second % messages.length];
  }

  String _getCorrectionMessage(String exerciseName) {
    final messages = [
      "Revisemos la técnica 🔍",
      "Paso a paso 👣",
      "Vamos a corregir 🛠️",
      "Enfócate en la forma 📏",
    ];
    return messages[DateTime.now().second % messages.length];
  }

  String _calculateTrend(List<WorkoutAnalysis> analysis) {
    if (analysis.length < 2) return "Datos insuficientes";

    final recent = analysis.take(3).map((a) => a.feedback.averageScore).reduce((a, b) => a + b) / 3;
    final older = analysis.skip(3).take(3).map((a) => a.feedback.averageScore).reduce((a, b) => a + b) / 3;

    if (recent > older + 0.5) return "Mejorando";
    if (recent < older - 0.5) return "Necesita atención";
    return "Estable";
  }

  // Métodos de fallback para errores
  String _getFallbackImprovementPlan(List<String> weaknesses) {
    return """
💪 **Plan de Mejora**

🎯 **Enfoque:** ${weaknesses.isNotEmpty ? weaknesses.first : 'Técnica general'}

📅 **Práctica recomendada:**
- 10 minutos diarios de ejercicios de movilidad
- Practicar movimientos básicos sin peso
- Grabarse para auto-corrección

🎥 **Visualización:**
- Imagina el movimiento perfecto antes de ejecutar
- Concéntrate en un punto técnico por sesión

📈 **Progreso:**
- Mide mejora en puntuación de técnica
- Anota sensaciones durante el ejercicio
""";
  }

  String _getFallbackProgressAnalysis(int days) {
    return """
📊 **Análisis de Progreso - $days días**

🎯 **Estado actual:** Construyendo base de datos

💪 **Recomendación:** 
- Continúa entrenando consistentemente
- Enfócate en técnica sobre intensidad
- El análisis mejorará con más datos

🚀 **Próximo paso:** 
- Completa al menos 5 sesiones más para análisis detallado
""";
  }

  List<String> _identifyStrengths(FormFeedback feedback) {
    final strengths = <String>[];

    if (feedback.averageScore >= 8.0) {
      strengths.add("Excelente técnica general");
    }

    if (feedback.totalReps > 0) {
      strengths.add("Buena detección de repeticiones");
    }

    final consistency = feedback.detailedScores['consistencia'] as double?;
    if (consistency != null && consistency < 2.0) {
      strengths.add("Movimiento consistente");
    }

    return strengths.isNotEmpty ? strengths : ["Disposición para mejorar"];
  }

  List<String> _identifyWeaknesses(FormFeedback feedback) {
    final weaknesses = <String>[];

    if (feedback.averageScore < 6.0) {
      weaknesses.add("Técnica necesita trabajo");
    }

    final consistency = feedback.detailedScores['consistencia'] as double?;
    if (consistency != null && consistency > 3.0) {
      weaknesses.add("Inconsistencia en el movimiento");
    }

    if (feedback.totalReps == 0) {
      weaknesses.add("Rango de movimiento muy limitado");
    }

    return weaknesses;
  }

  String _getNextSessionFocus(String exerciseName) {
    final progress = _exerciseProgress[exerciseName];
    if (progress == null || progress.isEmpty) {
      return "Establecer línea base de técnica";
    }

    final lastScore = progress.last;
    if (lastScore < 5.0) {
      return "Dominar movimiento básico";
    } else if (lastScore < 7.0) {
      return "Perfeccionar técnica";
    } else {
      return "Mantener consistencia";
    }
  }

  String _generateMotivationalMessage(double score) {
    if (score >= 8.5) {
      return "🔥 ¡Estás dominando la técnica! Sigue así, campeón";
    } else if (score >= 7.0) {
      return "💪 ¡Excelente progreso! Cada rep te acerca a la perfección";
    } else if (score >= 5.0) {
      return "🎯 ¡Vas por buen camino! La constancia es clave";
    } else {
      return "⚡ ¡Cada entrenamiento es un paso adelante! No te rindas";
    }
  }

  String _getRecentPerformance(String exerciseName) {
    final recent = _exerciseProgress[exerciseName];
    if (recent == null || recent.isEmpty) {
      return "Sin historial previo";
    }

    final avg = recent.reduce((a, b) => a + b) / recent.length;
    return "Promedio reciente: ${avg.toStringAsFixed(1)}/10";
  }

  String _getExerciseHistory() {
    final exerciseCount = <String, int>{};
    for (final analysis in _analysisHistory) {
      final name = analysis.exercise.nombre;
      exerciseCount[name] = (exerciseCount[name] ?? 0) + 1;
    }

    return exerciseCount.entries
        .map((e) => "${e.key}: ${e.value} sesiones")
        .join(", ");
  }

  Future<String> _generateImprovementPlan(Exercise exercise) async {
    return "Plan personalizado para ${exercise.nombre} en desarrollo...";
  }
}

// MODELOS DE DATOS PARA EL SISTEMA HÍBRIDO

class PreWorkoutAdvice {
  final String exerciseName;
  final String aiAdvice;
  final List<String> focusPoints;
  final List<String> personalizedTips;

  PreWorkoutAdvice({
    required this.exerciseName,
    required this.aiAdvice,
    required this.focusPoints,
    required this.personalizedTips,
  });

  static PreWorkoutAdvice fallback(String exerciseName) {
    return PreWorkoutAdvice(
      exerciseName: exerciseName,
      aiAdvice: "Concéntrate en la técnica correcta y mantén el control durante todo el movimiento. ¡Tú puedes! 💪",
      focusPoints: ["Técnica correcta", "Control del movimiento", "Respiración constante"],
      personalizedTips: ["Mantén la concentración durante todo el ejercicio"],
    );
  }
}

class RealTimeCoaching {
  final String message;
  final String motivation;
  final double score;
  final bool isPositive;

  RealTimeCoaching({
    required this.message,
    required this.motivation,
    required this.score,
    required this.isPositive,
  });

  static RealTimeCoaching notReliable() {
    return RealTimeCoaching(
      message: "Ajusta tu posición",
      motivation: "📱 Mejor ángulo de cámara",
      score: 0.0,
      isPositive: false,
    );
  }

  static RealTimeCoaching error() {
    return RealTimeCoaching(
      message: "Sigue con tu técnica",
      motivation: "💪 Tú tienes el control",
      score: 0.0,
      isPositive: true,
    );
  }
}

class PostWorkoutAnalysis {
  final String aiAnalysis;
  final String improvementPlan;
  final List<String> strengthsIdentified;
  final List<String> weaknessesIdentified;
  final String nextSessionFocus;
  final String motivationalMessage;

  PostWorkoutAnalysis({
    required this.aiAnalysis,
    required this.improvementPlan,
    required this.strengthsIdentified,
    required this.weaknessesIdentified,
    required this.nextSessionFocus,
    required this.motivationalMessage,
  });

  static PostWorkoutAnalysis error() {
    return PostWorkoutAnalysis(
      aiAnalysis: "Error en el análisis, pero has hecho un gran trabajo entrenando. ¡Sigue así! 💪",
      improvementPlan: "Continúa practicando con constancia",
      strengthsIdentified: ["Dedicación al entrenamiento"],
      weaknessesIdentified: [],
      nextSessionFocus: "Mantener la constancia",
      motivationalMessage: "⚡ Cada entrenamiento cuenta. ¡Sigue adelante!",
    );
  }
}

class WorkoutAnalysis {
  final Exercise exercise;
  final FormFeedback feedback;
  final int actualReps;
  final double duration;
  final DateTime timestamp;

  WorkoutAnalysis({
    required this.exercise,
    required this.feedback,
    required this.actualReps,
    required this.duration,
    required this.timestamp,
  });
}