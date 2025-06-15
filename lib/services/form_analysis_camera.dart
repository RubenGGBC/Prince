// lib/services/form_analysis_camera.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/form_feedback.dart';
import '../domain/exercise.dart';
import '../models/exercise_analyzer.dart';

// 📹 CONTROLADOR PRINCIPAL PARA ANÁLISIS DE TÉCNICA CON CÁMARA
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

  // 📊 Estado del análisis
  StreamController<FormScore>? _formScoreStream;
  final List<FormScore> _currentSetScores = [];
  ExerciseType _currentExerciseType = ExerciseType.generic;

  // 🎯 Callbacks
  Function(FormScore)? onFormScoreUpdate;
  Function(String)? onError;
  Function(FormFeedback)? onSetComplete;

  // ✅ Getters públicos
  bool get isCameraInitialized => _isCameraInitialized;
  bool get isAnalyzing => _isAnalyzing;
  CameraController? get cameraController => _cameraController;
  Stream<FormScore>? get formScoreStream => _formScoreStream?.stream;

  // 🚀 INICIALIZAR CÁMARA Y PERMISOS
  Future<bool> initialize() async {
    try {
      print('📱 Inicializando FormAnalysisCamera...');

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

      // 3. Inicializar stream de puntajes
      _formScoreStream = StreamController<FormScore>.broadcast();

      print('✅ FormAnalysisCamera inicializada correctamente');
      return true;

    } catch (e) {
      print('❌ Error inicializando FormAnalysisCamera: $e');
      _handleError('Error inicializando cámara: $e');
      return false;
    }
  }

  // 📹 CONFIGURAR CÁMARA SEGÚN EL EJERCICIO
  Future<bool> setupCameraForExercise(Exercise exercise) async {
    try {
      print('🏋️ Configurando cámara para: ${exercise.nombre}');

      // 1. Determinar tipo de ejercicio
      _currentExerciseType = _determineExerciseType(exercise.nombre);

      // 2. Seleccionar cámara según la posición requerida
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

      // 3. Inicializar controlador de cámara
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false, // No necesitamos audio para análisis de forma
        imageFormatGroup: ImageFormatGroup.nv21, // Formato óptimo para ML Kit
      );

      await _cameraController!.initialize();

      // 4. Configurar orientación
      await _cameraController!.lockCaptureOrientation();

      _isCameraInitialized = true;
      print('✅ Cámara configurada: ${cameraPosition} para ${_currentExerciseType.displayName}');

      return true;

    } catch (e) {
      print('❌ Error configurando cámara: $e');
      _handleError('Error configurando cámara: $e');
      return false;
    }
  }

  // ▶️ EMPEZAR ANÁLISIS EN TIEMPO REAL
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
      print('🎬 Iniciando análisis de técnica...');

      _isAnalyzing = true;
      _currentSetScores.clear();
      _exerciseAnalyzer.resetForNewSet();

      // Empezar stream de imágenes para análisis
      await _cameraController!.startImageStream(_analyzeImageFrame);

      print('✅ Análisis iniciado correctamente');

    } catch (e) {
      print('❌ Error iniciando análisis: $e');
      _handleError('Error iniciando análisis: $e');
      _isAnalyzing = false;
    }
  }

  // ⏹️ DETENER ANÁLISIS Y GENERAR FEEDBACK
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

  // 🔍 ANALIZAR CADA FRAME DE LA CÁMARA
  void _analyzeImageFrame(CameraImage image) async {
    if (!_isAnalyzing) return;

    try {
      // 1. Convertir imagen de cámara a formato ML Kit
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) return;

      // 2. Detectar poses
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        // 3. Analizar técnica del primer pose detectado
        final formScore = _exerciseAnalyzer.analyzeExerciseFrame(
            _currentExerciseType,
            poses.first
        );

        // 4. Guardar score solo si es confiable
        if (formScore.isReliable) {
          _currentSetScores.add(formScore);

          // Limitar a últimos 30 scores (aprox 1 segundo de análisis a 30fps)
          if (_currentSetScores.length > 30) {
            _currentSetScores.removeAt(0);
          }

          // 5. Notificar nuevo score
          _formScoreStream?.add(formScore);
          onFormScoreUpdate?.call(formScore);
        }
      }

    } catch (e) {
      print('❌ Error analizando frame: $e');
      // No llamamos _handleError aquí para evitar spam de errores
    }
  }

  // 🔄 CONVERTIR IMAGEN DE CÁMARA A FORMATO ML KIT
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      // Obtener información de rotación de la cámara
      final sensorOrientation = _cameraController?.description.sensorOrientation ?? 0;
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

      // Obtener formato de imagen
      final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      // Crear InputImage con la API correcta
      final inputImage = InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        inputImageData: InputImageData(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          imageRotation: rotation,
          inputImageFormat: format,
          planeData: image.planes.map(
                (Plane plane) {
              return InputImagePlaneMetadata(
                bytesPerRow: plane.bytesPerRow,
                height: plane.height,
                width: plane.width,
              );
            },
          ).toList(),
        ),
      );

      return inputImage;

    } catch (e) {
      print('❌ Error convirtiendo imagen: $e');
      return null;
    }
  }

  // 🎯 DETERMINAR TIPO DE EJERCICIO BASADO EN EL NOMBRE
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

  // 📱 OBTENER WIDGET DE PREVIEW DE CÁMARA
  Widget buildCameraPreview() {
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
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _cameraController!.value.aspectRatio,
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  // 📊 OBTENER ESTADÍSTICAS ACTUALES
  Map<String, dynamic> getCurrentStats() {
    return {
      'currentReps': _exerciseAnalyzer.currentRepCount,
      'totalFramesAnalyzed': _currentSetScores.length,
      'averageScore': _currentSetScores.isNotEmpty
          ? _currentSetScores.map((s) => s.score).reduce((a, b) => a + b) / _currentSetScores.length
          : 0.0,
      'exerciseType': _currentExerciseType.displayName,
      'cameraPosition': _currentExerciseType.cameraPosition,
    };
  }

  // 🎨 OBTENER INSTRUCCIONES DE POSICIONAMIENTO
  String getCameraPositionInstructions() {
    switch (_currentExerciseType.cameraPosition) {
      case 'frontal':
        return 'Coloca el teléfono frente a ti a 1-2 metros de distancia';
      case 'lateral':
        return 'Coloca el teléfono al lado tuyo, perpendicular a tu cuerpo';
      case 'trasera':
        return 'Coloca el teléfono detrás de ti para capturar tu perfil posterior';
      default:
        return 'Posiciona el teléfono para que todo tu cuerpo sea visible';
    }
  }

  // ⚠️ MANEJO DE ERRORES
  void _handleError(String message) {
    print('❌ FormAnalysisCamera Error: $message');
    onError?.call(message);
  }

  // 🧹 LIMPIEZA DE RECURSOS
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
      _formScoreStream = null;

      print('✅ Recursos limpiados correctamente');

    } catch (e) {
      print('❌ Error limpiando recursos: $e');
    }
  }

  // 🔄 REINICIAR PARA NUEVO EJERCICIO
  Future<void> resetForNewExercise() async {
    if (_isAnalyzing) {
      await stopAnalysis();
    }

    _currentSetScores.clear();
    _exerciseAnalyzer.resetForNewSet();
    _currentExerciseType = ExerciseType.generic;

    print('🔄 FormAnalysisCamera reiniciada para nuevo ejercicio');
  }

  // 📷 TOMAR CAPTURA DE PANTALLA (Para debugging)
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
}