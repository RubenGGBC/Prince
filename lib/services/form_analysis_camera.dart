// lib/services/form_analysis_camera.dart - MEJORADO CON IA
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/form_feedback.dart';
import '../models/form_score.dart';
import '../domain/exercise.dart';
import '../domain/user.dart';
import '../models/exercise_analyzer.dart';
import 'ai_from_coach.dart';

/// 📹 CONTROLADOR PRINCIPAL CON IA INTEGRADA
class FormAnalysisCamera {
  // 🎥 Controladores de cámara
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;

  // 🧠 ML Kit y análisis
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );
  final ExerciseAnalyzer _exerciseAnalyzer = ExerciseAnalyzer();

  // 🤖 NUEVO: Entrenador IA híbrido
  final AIFormCoach _aiCoach = AIFormCoach();

  // 📊 Estado del análisis
  StreamController<FormScore>? _formScoreStream;
  StreamController<RealTimeCoaching>? _coachingStream; // 🆕 Coaching en tiempo real
  final List<FormScore> _currentSetScores = [];
  ExerciseType _currentExerciseType = ExerciseType.generic;
  Exercise? _currentExercise;
  User? _currentUser;

  // 🎯 Callbacks mejorados
  Function(FormScore)? onFormScoreUpdate;
  Function(RealTimeCoaching)? onRealTimeCoaching; // 🆕 Coaching callback
  Function(String)? onError;
  Function(FormFeedback)? onSetComplete;
  Function(PostWorkoutAnalysis)? onPostWorkoutAnalysis; // 🆕 Análisis post-entrenamiento

  // ⏱️ Control de frecuencia de análisis IA
  DateTime _lastAIAnalysis = DateTime.now();
  static const _aiAnalysisInterval = Duration(seconds: 2); // IA cada 2 segundos

  // ✅ Getters públicos
  bool get isCameraInitialized => _isCameraInitialized;
  bool get isAnalyzing => _isAnalyzing;
  CameraController? get cameraController => _cameraController;
  Stream<FormScore>? get formScoreStream => _formScoreStream?.stream;
  Stream<RealTimeCoaching>? get coachingStream => _coachingStream?.stream; // 🆕

  /// 🚀 INICIALIZAR CÁMARA Y PERMISOS
  Future<bool> initialize() async {
    try {
      print('📱 Inicializando FormAnalysisCamera con IA...');

      // 1. Verificar y solicitar permisos
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission != PermissionStatus.granted) {
        _handleError('Permiso de cámara denegado');
        return false;
      }

      // 2. Obtener cámaras disponibles
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _handleError('No se encontraron cámaras disponibles');
        return false;
      }

      // 3. Inicializar streams
      _formScoreStream = StreamController<FormScore>.broadcast();
      _coachingStream = StreamController<RealTimeCoaching>.broadcast(); // 🆕

      print('✅ FormAnalysisCamera con IA inicializada correctamente');
      return true;

    } catch (e) {
      print('❌ Error inicializando FormAnalysisCamera: $e');
      _handleError('Error inicializando cámara: $e');
      return false;
    }
  }

  /// 🎯 CONFIGURAR EJERCICIO CON CONSEJO PRE-ENTRENAMIENTO
  Future<bool> setupCameraForExercise(Exercise exercise, {User? user}) async {
    try {
      print('🏋️ Configurando cámara para: ${exercise.nombre}');

      _currentExercise = exercise;
      _currentUser = user;

      // 1. Determinar tipo de ejercicio
      _currentExerciseType = _determineExerciseType(exercise.nombre);

      // 2. 🆕 OBTENER CONSEJO PRE-ENTRENAMIENTO DE IA
      if (user != null) {
        try {
          final preWorkoutAdvice = await _aiCoach.getPreWorkoutAdvice(exercise, user);
          print('🤖 Consejo pre-entrenamiento recibido');

          // Notificar consejo pre-entrenamiento
          onRealTimeCoaching?.call(RealTimeCoaching(
            message: preWorkoutAdvice.aiAdvice,
            motivation: "🎯 Consejo de PrinceIA",
            score: 10.0,
            isPositive: true,
          ));
        } catch (e) {
          print('⚠️ Error obteniendo consejo pre-entrenamiento: $e');
        }
      }

      // 3. Seleccionar cámara según la posición requerida
      CameraDescription selectedCamera;
      final cameraPosition = _currentExerciseType.cameraPosition;

      if (cameraPosition == 'frontal') {
        selectedCamera = _cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );
      } else {
        selectedCamera = _cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );
      }

      // 4. Limpiar controlador anterior si existe
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
        _isCameraInitialized = false;
      }

      // 5. Inicializar controlador de cámara
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      // 6. Inicializar el controlador
      await _cameraController!.initialize();

      // 7. Configurar orientación
      await _cameraController!.lockCaptureOrientation();

      // 8. Marcar como inicializada
      _isCameraInitialized = true;

      print('✅ Cámara configurada: $cameraPosition para ${_currentExerciseType.displayName}');
      print('✅ Controlador inicializado: ${_cameraController!.value.isInitialized}');

      return true;

    } catch (e) {
      print('❌ Error configurando cámara: $e');
      _handleError('Error configurando cámara: $e');
      _isCameraInitialized = false;
      return false;
    }
  }

  /// ▶️ EMPEZAR ANÁLISIS CON IA EN TIEMPO REAL
  Future<void> startAnalysis() async {
    if (!_isCameraInitialized || _cameraController == null) {
      _handleError('Cámara no inicializada');
      return;
    }

    if (_isAnalyzing) {
      print('⚠️ El análisis ya está en curso');
      return;
    }

    try {
      print('🎬 Iniciando análisis de técnica con IA...');

      _isAnalyzing = true;
      _currentSetScores.clear();
      _exerciseAnalyzer.resetForNewSet();
      _lastAIAnalysis = DateTime.now();

      // Empezar stream de imágenes para análisis
      await _cameraController!.startImageStream(_analyzeImageFrame);

      print('✅ Análisis con IA iniciado correctamente');

    } catch (e) {
      print('❌ Error iniciando análisis: $e');
      _handleError('Error iniciando análisis: $e');
      _isAnalyzing = false;
    }
  }

  /// ⏹️ DETENER ANÁLISIS Y GENERAR FEEDBACK CON IA
  Future<FormFeedback> stopAnalysis() async {
    if (!_isAnalyzing) {
      return FormFeedback(
        averageScore: 0.0,
        mainComment: 'No se realizó análisis',
        tips: [],
        detailedScores: {},
        totalReps: 0,
      );
    }

    try {
      print('🛑 Deteniendo análisis...');

      _isAnalyzing = false;

      if (_cameraController != null) {
        await _cameraController!.stopImageStream();
      }

      // Generar feedback final de la serie
      final feedback = _exerciseAnalyzer.generateSeriesFeedback(
          _currentSetScores,
          _currentExerciseType
      );

      print('📊 Feedback generado - Puntuación: ${feedback.averageScore.toStringAsFixed(1)}');
      print('🔄 Repeticiones detectadas: ${feedback.totalReps}');

      // 🆕 ANÁLISIS POST-ENTRENAMIENTO CON IA
      if (_currentExercise != null) {
        try {
          final sessionDuration = _currentSetScores.isNotEmpty
              ? _currentSetScores.last.timestamp.difference(_currentSetScores.first.timestamp).inSeconds.toDouble()
              : 0.0;

          final postAnalysis = await _aiCoach.getPostWorkoutAnalysis(
            feedback,
            _currentExercise!,
            _currentExercise!.repeticiones,
            sessionDuration,
          );

          // Notificar análisis post-entrenamiento
          onPostWorkoutAnalysis?.call(postAnalysis);
          print('🤖 Análisis post-entrenamiento con IA completado');

        } catch (e) {
          print('⚠️ Error en análisis post-entrenamiento: $e');
        }
      }

      // Notificar feedback final
      onSetComplete?.call(feedback);

      return feedback;

    } catch (e) {
      print('❌ Error deteniendo análisis: $e');
      _handleError('Error deteniendo análisis: $e');
      return FormFeedback(
        averageScore: 0.0,
        mainComment: 'Error generando feedback',
        tips: ['Inténtalo de nuevo'],
        detailedScores: {},
        totalReps: 0,
      );
    }
  }

  /// 🔍 ANALIZAR CADA FRAME CON IA MEJORADA
  void _analyzeImageFrame(CameraImage image) async {
    if (!_isAnalyzing) return;

    try {
      // 1. Convertir imagen a formato ML Kit
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) return;

      // 2. Detectar pose usando ML Kit
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) return;

      // 3. Analizar la pose principal
      final mainPose = poses.first;
      final formScore = _exerciseAnalyzer.analyzeExerciseFrame(_currentExerciseType, mainPose);

      // 4. Solo procesar si la puntuación es confiable
      if (formScore.isReliable) {
        _currentSetScores.add(formScore);

        // 5. Notificar actualización de puntuación
        onFormScoreUpdate?.call(formScore);

        // 6. 🆕 COACHING IA EN TIEMPO REAL (cada 2 segundos)
        final now = DateTime.now();
        if (now.difference(_lastAIAnalysis) >= _aiAnalysisInterval && _currentExercise != null) {
          _lastAIAnalysis = now;

          try {
            final realTimeCoaching = await _aiCoach.getRealTimeCoaching(formScore, _currentExercise!);
            onRealTimeCoaching?.call(realTimeCoaching);

            // También enviar al stream
            _coachingStream?.add(realTimeCoaching);

          } catch (e) {
            print('⚠️ Error en coaching tiempo real: $e');
          }
        }
      }

    } catch (e) {
      print('❌ Error analizando frame: $e');
      // No paramos el análisis por un error de frame individual
    }
  }

  /// 🎙️ OBTENER MENSAJE DE VOZ PARA TTS
  String getVoiceCoaching(FormScore score) {
    if (_currentExercise == null) return "";
    return _aiCoach.getVoiceCoaching(score, _currentExercise!);
  }

  /// 📈 OBTENER ANÁLISIS DE PROGRESO
  Future<String> getProgressAnalysis(int days) async {
    return await _aiCoach.getProgressAnalysis(days);
  }

  /// 💡 GENERAR PLAN DE MEJORA PERSONALIZADO
  Future<String> generateImprovementPlan(List<String> weaknesses) async {
    return await _aiCoach.generateImprovementPlan(weaknesses);
  }

  // MÉTODOS EXISTENTES (sin cambios)

  /// 🔄 CONVERTIR IMAGEN DE CÁMARA A FORMATO ML KIT
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      if (_cameraController == null) return null;

      final sensorOrientation = _cameraController!.description.sensorOrientation;
      InputImageRotation? rotation;

      switch (sensorOrientation) {
        case 90:
          rotation = InputImageRotation.rotation90deg;
          break;
        case 180:
          rotation = InputImageRotation.rotation180deg;
          break;
        case 270:
          rotation = InputImageRotation.rotation270deg;
          break;
        default:
          rotation = InputImageRotation.rotation0deg;
      }

      final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImage = InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        inputImageData: InputImageData(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          imageRotation: rotation,
          inputImageFormat: format,
          planeData: image.planes.map((Plane plane) {
            return InputImagePlaneMetadata(
              bytesPerRow: plane.bytesPerRow,
              height: plane.height,
              width: plane.width,
            );
          }).toList(),
        ),
      );

      return inputImage;

    } catch (e) {
      print('❌ Error convirtiendo imagen: $e');
      return null;
    }
  }

  /// 🎯 DETERMINAR TIPO DE EJERCICIO
  ExerciseType _determineExerciseType(String exerciseName) {
    final name = exerciseName.toLowerCase();

    if (name.contains('press') && name.contains('pecho')) {
      return ExerciseType.pressPlano;
    } else if (name.contains('peck deck') || name.contains('pec deck')) {
      return ExerciseType.peckDeck;
    } else if (name.contains('press') && name.contains('inclinado')) {
      return ExerciseType.pressInclinado;
    } else if (name.contains('fondos') || name.contains('dip')) {
      return ExerciseType.fondos;
    } else if (name.contains('extensión') && name.contains('triceps')) {
      if (name.contains('tras nuca') || name.contains('overhead')) {
        return ExerciseType.extensionTricepsTrasNuca;
      } else {
        return ExerciseType.extensionTriceps;
      }
    } else if (name.contains('sentadilla') || name.contains('squat')) {
      return ExerciseType.sentadillas;
    } else if (name.contains('flexion') || name.contains('push')) {
      return ExerciseType.flexiones;
    } else {
      return ExerciseType.generic;
    }
  }

  /// 📱 WIDGET DE PREVIEW DE CÁMARA CON OVERLAY IA
  Widget buildCameraPreview({bool showAIOverlay = true}) {
    print('🔍 buildCameraPreview() llamado');
    print('   - _isCameraInitialized: $_isCameraInitialized');
    print('   - _cameraController != null: ${_cameraController != null}');

    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Iniciando cámara...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (_currentExercise != null) ...[
                SizedBox(height: 8),
                Text(
                  '🤖 PrinceIA preparando análisis',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (!_cameraController!.value.isInitialized) {
      return Container(
        color: Colors.red,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.white, size: 48),
              SizedBox(height: 16),
              Text(
                'Error: Controlador no inicializado',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    Widget cameraWidget = CameraPreview(_cameraController!);

    // 🆕 Overlay con información de IA si está habilitado
    if (showAIOverlay && _isAnalyzing) {
      cameraWidget = Stack(
        children: [
          cameraWidget,

          // Overlay con estado de IA
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.smart_toy, color: Colors.blue, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'PrinceIA analizando',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Puntos de pose si disponibles (opcional)
          if (_currentSetScores.isNotEmpty)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Reps: ${_exerciseAnalyzer.currentRepCount}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _cameraController!.value.aspectRatio,
        child: cameraWidget,
      ),
    );
  }

  /// 🎨 OBTENER INSTRUCCIONES DE POSICIONAMIENTO
  String getCameraPositionInstructions() {
    final baseInstructions = {
      'frontal': 'Coloca el teléfono frente a ti a 1-2 metros de distancia',
      'lateral': 'Coloca el teléfono al lado tuyo, perpendicular a tu cuerpo',
      'trasera': 'Coloca el teléfono detrás de ti para capturar tu perfil posterior',
    };

    final instruction = baseInstructions[_currentExerciseType.cameraPosition] ??
        'Posiciona el teléfono para que todo tu cuerpo sea visible';

    return "$instruction\n🤖 PrinceIA te dará consejos en tiempo real";
  }

  /// 📊 OBTENER ESTADÍSTICAS MEJORADAS
  Map<String, dynamic> getCurrentStats() {
    return {
      'currentReps': _exerciseAnalyzer.currentRepCount,
      'totalFramesAnalyzed': _currentSetScores.length,
      'averageScore': _currentSetScores.isNotEmpty
          ? _currentSetScores.map((s) => s.score).reduce((a, b) => a + b) / _currentSetScores.length
          : 0.0,
      'exerciseType': _currentExerciseType.displayName,
      'cameraPosition': _currentExerciseType.cameraPosition,
      'aiCoachingActive': _isAnalyzing,
      'lastAIAnalysis': _lastAIAnalysis.toIso8601String(),
    };
  }

  /// ⚠️ MANEJO DE ERRORES
  void _handleError(String message) {
    print('❌ FormAnalysisCamera Error: $message');
    onError?.call(message);
  }

  /// 🔄 REINICIAR PARA NUEVO EJERCICIO
  Future<void> resetForNewExercise() async {
    if (_isAnalyzing) {
      await stopAnalysis();
    }

    _currentSetScores.clear();
    _exerciseAnalyzer.resetForNewSet();
    _currentExerciseType = ExerciseType.generic;
    _currentExercise = null;
    _currentUser = null;

    print('🔄 FormAnalysisCamera reiniciada para nuevo ejercicio');
  }

  /// 📷 TOMAR CAPTURA DE PANTALLA
  Future<Uint8List?> takePicture() async {
    if (!_isCameraInitialized || _cameraController == null) {
      return null;
    }

    try {
      final XFile picture = await _cameraController!.takePicture();
      return await picture.readAsBytes();
    } catch (e) {
      print('❌ Error tomando foto: $e');
      return null;
    }
  }

  /// 🧹 LIMPIEZA DE RECURSOS
  Future<void> dispose() async {
    try {
      print('🧹 Limpiando recursos de FormAnalysisCamera...');

      _isAnalyzing = false;

      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await _cameraController!.dispose();
        _cameraController = null;
      }

      await _poseDetector.close();
      await _formScoreStream?.close();
      await _coachingStream?.close(); // 🆕
      _formScoreStream = null;
      _coachingStream = null;

      print('✅ Recursos limpiados correctamente');

    } catch (e) {
      print('❌ Error limpiando recursos: $e');
    }
  }
}