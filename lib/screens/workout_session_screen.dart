// lib/screens/workout_session_screen.dart - MODIFICADO CON ML KIT
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import '../utils/app_colors.dart';
import '../domain/exercise.dart';
import '../domain/rutina.dart';
import '../database/DatabaseHelper.dart';
// 🆕 NUEVOS IMPORTS PARA ML KIT
import '../services/form_analysis_camera.dart';
import '../models/form_feedback.dart';

class WorkoutSessionScreen extends StatefulWidget {
  @override
  _WorkoutSessionScreenState createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // 📋 ESTADO DE LA SESIÓN (existente)
  List<Rutina> _availableRoutines = [];
  Rutina? _selectedRoutine;
  List<Exercise> _routineExercises = [];

  // 🏋️ ESTADO DEL EJERCICIO ACTUAL (existente)
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  Exercise? get _currentExercise => _routineExercises.isNotEmpty ? _routineExercises[_currentExerciseIndex] : null;

  // ⏱️ ESTADO DEL CRONÓMETRO (existente)
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  // 😴 ESTADO DEL DESCANSO (existente)
  Timer? _restTimer;
  int _restSeconds = 180;
  bool _isResting = false;

  // 📊 DATOS DEL SET ACTUAL (existente)
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  // 🎭 ANIMACIONES (existente)
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  // 📱 ESTADOS DE UI (existente)
  bool _isLoading = true;
  WorkoutPhase _currentPhase = WorkoutPhase.selectRoutine;

  // 🆕 ========== NUEVAS VARIABLES PARA ML KIT ==========

  // 📹 Controlador de análisis de técnica
  late FormAnalysisCamera _formAnalysisCamera;
  bool _isCameraReady = false;
  bool _isAnalyzingForm = false;

  // 📊 Datos de técnica en tiempo real
  FormScore? _currentFormScore;
  FormFeedback? _lastSetFeedback;

  // 🎯 Animación para el indicador de técnica
  late AnimationController _techniqueIndicatorController;
  late Animation<double> _techniqueIndicatorAnimation;

  // 📈 Estadísticas de la sesión
  List<FormFeedback> _sessionFeedbacks = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadRoutines();
    // 🆕 INICIALIZAR SISTEMA DE ANÁLISIS
    _initializeFormAnalysis();
  }

  // 🆕 NUEVO MÉTODO - Inicializar análisis de técnica
  Future<void> _initializeFormAnalysis() async {
    try {
      print('🎬 Inicializando sistema de análisis de técnica...');

      _formAnalysisCamera = FormAnalysisCamera();

      // Configurar callbacks
      _formAnalysisCamera.onFormScoreUpdate = (FormScore score) {
        if (mounted) {
          setState(() {
            _currentFormScore = score;
          });
          _updateTechniqueIndicator(score.score);
        }
      };

      _formAnalysisCamera.onError = (String error) {
        if (mounted) {
          _showError('Error de cámara: $error');
        }
      };

      _formAnalysisCamera.onSetComplete = (FormFeedback feedback) {
        if (mounted) {
          setState(() {
            _lastSetFeedback = feedback;
            _sessionFeedbacks.add(feedback);
          });
        }
      };

      // Inicializar cámara
      final success = await _formAnalysisCamera.initialize();
      if (success && mounted) {
        setState(() {
          _isCameraReady = true;
        });
        print('✅ Sistema de análisis inicializado correctamente');
      }

    } catch (e) {
      print('❌ Error inicializando análisis: $e');
      _showError('Error inicializando análisis de técnica');
    }
  }

  void _setupAnimations() {
    // Animaciones existentes...
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: Duration(milliseconds: 4000),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // 🆕 NUEVA ANIMACIÓN - Indicador de técnica
    _techniqueIndicatorController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _techniqueIndicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _techniqueIndicatorController, curve: Curves.easeInOut),
    );
  }

  // 🆕 NUEVO MÉTODO - Actualizar indicador de técnica
  void _updateTechniqueIndicator(double score) {
    if (score >= 7.0) {
      _techniqueIndicatorController.forward();
    } else {
      _techniqueIndicatorController.reverse();
    }
  }

  // Métodos existentes de carga de rutinas...
  Future<void> _loadRoutines() async {
    try {
      final routines = await _dbHelper.getAllRutinas();
      setState(() {
        _availableRoutines = routines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando rutinas: $e');
    }
  }

  Future<void> _selectRoutine(Rutina routine) async {
    try {
      final exercises = await _dbHelper.getExercisesByIds(routine.ejercicioIds);
      setState(() {
        _selectedRoutine = routine;
        _routineExercises = exercises;
        _currentExerciseIndex = 0;
        _currentSet = 1;
        _currentPhase = WorkoutPhase.exerciseReady;
      });
      _prepareExercise();
    } catch (e) {
      _showError('Error cargando ejercicios: $e');
    }
  }

  void _prepareExercise() {
    if (_currentExercise != null) {
      setState(() {
        _weightController.text = _currentExercise!.peso.toString();
        _repsController.text = _currentExercise!.repeticiones.toString();
      });

      // 🆕 CONFIGURAR CÁMARA PARA EL EJERCICIO ACTUAL
      _setupCameraForCurrentExercise();
    }
  }

  // 🆕 NUEVO MÉTODO - Configurar cámara para ejercicio actual
  Future<void> _setupCameraForCurrentExercise() async {
    if (!_isCameraReady || _currentExercise == null) return;

    try {
      print('🎥 Configurando cámara para: ${_currentExercise!.nombre}');

      await _formAnalysisCamera.setupCameraForExercise(_currentExercise!);

      // Mostrar instrucciones de posicionamiento
      final instructions = _formAnalysisCamera.getCameraPositionInstructions();
      _showInfo('Posicionamiento: $instructions');

    } catch (e) {
      print('❌ Error configurando cámara: $e');
    }
  }

  // ⏱️ CONTROL DEL CRONÓMETRO - MODIFICADO
  void _startSet() {
    setState(() {
      _currentPhase = WorkoutPhase.exerciseActive;
      _isRunning = true;
      _seconds = 0;
      _currentFormScore = null; // Reset score anterior
      _lastSetFeedback = null; // Reset feedback anterior
    });

    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });

    // 🆕 INICIAR ANÁLISIS DE TÉCNICA
    _startFormAnalysis();
  }

  // 🆕 NUEVO MÉTODO - Iniciar análisis de técnica
  Future<void> _startFormAnalysis() async {
    if (!_isCameraReady) {
      print('⚠️ Cámara no lista para análisis');
      return;
    }

    try {
      print('🎬 Iniciando grabación y análisis...');

      setState(() {
        _isAnalyzingForm = true;
      });

      await _formAnalysisCamera.startAnalysis();

      print('✅ Análisis de técnica iniciado');

    } catch (e) {
      print('❌ Error iniciando análisis: $e');
      _showError('Error iniciando análisis de técnica');
    }
  }

  void _finishSet() async {
    _timer?.cancel();
    _pulseController.stop();
    _waveController.stop();

    // 🆕 DETENER ANÁLISIS Y OBTENER FEEDBACK
    FormFeedback? feedback;
    if (_isAnalyzingForm) {
      try {
        print('🛑 Deteniendo análisis y generando feedback...');
        feedback = await _formAnalysisCamera.stopAnalysis();
        print('📊 Feedback obtenido: ${feedback.averageScore.toStringAsFixed(1)}/10');
      } catch (e) {
        print('❌ Error obteniendo feedback: $e');
      }
    }

    setState(() {
      _isRunning = false;
      _isAnalyzingForm = false;
      _currentPhase = WorkoutPhase.resting;
      _isResting = true;
      _restSeconds = 180;
      if (feedback != null) {
        _lastSetFeedback = feedback;
        _sessionFeedbacks.add(feedback);
      }
    });

    _startRestTimer();
  }

  void _startRestTimer() {
    _restTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _restSeconds--;
      });

      if (_restSeconds <= 0) {
        _restTimer?.cancel();
        setState(() {
          _isResting = false;
          _currentPhase = WorkoutPhase.exerciseReady;
          _lastSetFeedback = null; // Limpiar feedback para nuevo set
        });
        _checkNextSet();
      }
    });
  }

  void _checkNextSet() {
    if (_currentExercise != null) {
      if (_currentSet < _currentExercise!.series) {
        setState(() {
          _currentSet++;
        });
      } else {
        _nextExercise();
      }
    }
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _routineExercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _currentPhase = WorkoutPhase.exerciseReady;
      });
      _prepareExercise();
    } else {
      _completeWorkout();
    }
  }

  void _completeWorkout() {
    setState(() {
      _currentPhase = WorkoutPhase.completed;
    });
    _showWorkoutSummary();
  }

  // 🆕 NUEVO MÉTODO - Mostrar resumen de entrenamiento
  void _showWorkoutSummary() {
    if (_sessionFeedbacks.isEmpty) return;

    final avgScore = _sessionFeedbacks
        .map((f) => f.averageScore)
        .reduce((a, b) => a + b) / _sessionFeedbacks.length;

    final totalReps = _sessionFeedbacks
        .map((f) => f.totalReps)
        .reduce((a, b) => a + b);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          '🏆 ¡Entrenamiento Completado!',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Técnica Promedio: ${avgScore.toStringAsFixed(1)}/10',
              style: GoogleFonts.poppins(color: AppColors.white, fontSize: 18),
            ),
            Text(
              'Repeticiones Detectadas: $totalReps',
              style: GoogleFonts.poppins(color: AppColors.grey),
            ),
            SizedBox(height: 16),
            Text(
              avgScore >= 8.0
                  ? '¡Excelente técnica! 🔥'
                  : avgScore >= 6.0
                  ? '¡Buen trabajo! 💪'
                  : 'Sigue practicando 🎯',
              style: GoogleFonts.poppins(color: AppColors.pastelGreen),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Finalizar', style: TextStyle(color: AppColors.pastelBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: _buildCurrentPhase(),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_currentPhase) {
      case WorkoutPhase.selectRoutine:
        return _buildRoutineSelection();
      case WorkoutPhase.exerciseReady:
        return _buildExerciseReady();
      case WorkoutPhase.exerciseActive:
        return _buildExerciseActive(); // 🆕 MODIFICADO CON CÁMARA
      case WorkoutPhase.resting:
        return _buildRestingState(); // 🆕 MODIFICADO CON FEEDBACK
      case WorkoutPhase.completed:
        return _buildWorkoutCompleted();
    }
  }

  // MÉTODOS DE UI EXISTENTES (solo muestro los principales modificados)

  Widget _buildRoutineSelection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            '🏋️ Selecciona tu Rutina',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: _availableRoutines.length,
              itemBuilder: (context, index) {
                final routine = _availableRoutines[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    tileColor: AppColors.cardBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text(
                      routine.nombre,
                      style: GoogleFonts.poppins(color: AppColors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${routine.ejercicioIds.length} ejercicios',
                      style: GoogleFonts.poppins(color: AppColors.grey),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: AppColors.pastelBlue),
                    onTap: () => _selectRoutine(routine),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 EJERCICIO ACTIVO - MODIFICADO CON CÁMARA
  Widget _buildExerciseActive() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWorkoutHeader(),

          SizedBox(height: 20),

          // 🆕 VISTA DE CÁMARA Y ANÁLISIS
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Cronómetro principal (lado izquierdo)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildMainTimer(),
                      SizedBox(height: 20),
                      _buildCurrentSetInfo(),
                    ],
                  ),
                ),

                SizedBox(width: 20),

                // 🆕 Vista de cámara y análisis (lado derecho)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Preview de cámara
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isAnalyzingForm
                                  ? (_currentFormScore?.score ?? 0) >= 7.0
                                  ? AppColors.pastelGreen
                                  : AppColors.pastelOrange
                                  : AppColors.grey,
                              width: 3,
                            ),
                          ),
                          child: _isCameraReady
                              ? _formAnalysisCamera.buildCameraPreview()
                              : _buildCameraPlaceholder(),
                        ),
                      ),

                      SizedBox(height: 12),

                      // 🆕 Indicadores de técnica en tiempo real
                      _buildTechniqueIndicators(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Botón terminar set
          _buildFinishSetButton(),
        ],
      ),
    );
  }

  // 🆕 PLACEHOLDER PARA CÁMARA
  Widget _buildCameraPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: AppColors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'Preparando cámara...',
              style: GoogleFonts.poppins(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 INDICADORES DE TÉCNICA EN TIEMPO REAL
  Widget _buildTechniqueIndicators() {
    if (!_isAnalyzingForm || _currentFormScore == null) {
      return Container(
        height: 60,
        child: Center(
          child: Text(
            _isAnalyzingForm ? 'Analizando técnica...' : 'Presiona ▶️ para iniciar',
            style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 14),
          ),
        ),
      );
    }

    final score = _currentFormScore!.score;
    final color = Color(int.parse(_currentFormScore!.gradeColor.substring(1), radix: 16) + 0xFF000000);

    return Container(
      height: 60,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          // Puntaje numérico
          Container(
            width: 50,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                score.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          SizedBox(width: 12),

          // Texto de calificación
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentFormScore!.gradeText,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Técnica en tiempo real',
                  style: GoogleFonts.poppins(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Indicador animado
          AnimatedBuilder(
            animation: _techniqueIndicatorAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_techniqueIndicatorAnimation.value * 0.2),
                child: Icon(
                  score >= 8.0 ? Icons.check_circle :
                  score >= 6.0 ? Icons.thumb_up :
                  Icons.warning,
                  color: color,
                  size: 24,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🆕 ESTADO DE DESCANSO - MODIFICADO CON FEEDBACK
  Widget _buildRestingState() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWorkoutHeader(),

          SizedBox(height: 20),

          // 🆕 Mostrar feedback de la serie si está disponible
          if (_lastSetFeedback != null)
            _buildSetFeedbackCard(),

          if (_lastSetFeedback != null)
            SizedBox(height: 20),

          // Timer de descanso
          _buildRestTimer(),

          SizedBox(height: 30),

          Text(
            'Descansando...',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),

          Text(
            'Prepárate para el siguiente set',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),

          Spacer(),

          // Botón para saltar descanso
          TextButton(
            onPressed: () {
              _restTimer?.cancel();
              setState(() {
                _isResting = false;
                _currentPhase = WorkoutPhase.exerciseReady;
                _lastSetFeedback = null;
              });
              _checkNextSet();
            },
            child: Text(
              'Saltar descanso',
              style: GoogleFonts.poppins(
                color: AppColors.pastelBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 TARJETA DE FEEDBACK DE LA SERIE
  Widget _buildSetFeedbackCard() {
    if (_lastSetFeedback == null) return SizedBox();

    final feedback = _lastSetFeedback!;
    final color = Color(int.parse(
      feedback.averageScore >= 9.0 ? '4CAF50' :
      feedback.averageScore >= 7.5 ? '8BC34A' :
      feedback.averageScore >= 6.0 ? 'FFC107' :
      feedback.averageScore >= 4.5 ? 'FF9800' : 'F44336',
      radix: 16,
    ) + 0xFF000000);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          // Header con emoji y puntaje
          Row(
            children: [
              Text(
                feedback.emoji,
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${feedback.averageScore.toStringAsFixed(1)}/10',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'Técnica de la serie',
                      style: GoogleFonts.poppins(
                        color: AppColors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${feedback.totalReps} reps',
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Comentario principal
          Text(
            feedback.mainComment,
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 12),

          // Mensaje motivacional
          Text(
            feedback.motivationalMessage,
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),

          // Tips si los hay
          if (feedback.tips.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceBlack,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Tips para mejorar:',
                    style: GoogleFonts.poppins(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...feedback.tips.map((tip) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $tip',
                      style: GoogleFonts.poppins(
                        color: AppColors.grey,
                        fontSize: 13,
                      ),
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Métodos de UI existentes (mantener igual)...
  Widget _buildWorkoutHeader() {
    final progress = (_currentExerciseIndex + 1) / _routineExercises.length;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _showExitDialog(),
              icon: Icon(Icons.close, color: AppColors.white),
            ),
            Expanded(
              child: Text(
                _selectedRoutine?.nombre ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () => _showWorkoutMenu(),
              icon: Icon(Icons.more_vert, color: AppColors.white),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surfaceBlack,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Ejercicio ${_currentExerciseIndex + 1} de ${_routineExercises.length}',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _buildMainTimer() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.pastelPink.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(_seconds),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    'Set $_currentSet',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentSetInfo() {
    if (_currentExercise == null) return SizedBox();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            _currentExercise!.nombre,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${_weightController.text} kg',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pastelBlue,
                    ),
                  ),
                  Text(
                    'Peso',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    _repsController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pastelGreen,
                    ),
                  ),
                  Text(
                    'Reps',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinishSetButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _finishSet,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pastelOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Terminar Set',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRestTimer() {
    final minutes = _restSeconds ~/ 60;
    final seconds = _restSeconds % 60;

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.pastelBlue, width: 4),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            Text(
              'Descanso',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos de utilidad existentes...
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getExerciseColor(String grupoMuscular) {
    switch (grupoMuscular.toLowerCase()) {
      case 'pecho': return AppColors.pastelGreen;
      case 'espalda': return AppColors.pastelBlue;
      case 'brazos': return AppColors.pastelOrange;
      case 'piernas': return AppColors.pastelPink;
      default: return AppColors.pastelPurple;
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text('Salir del Entrenamiento', style: TextStyle(color: AppColors.white)),
        content: Text(
          'Se perderá el progreso actual.',
          style: GoogleFonts.poppins(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continuar', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showWorkoutMenu() {
    // TODO: Implementar menú
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.pastelBlue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildExerciseReady() {
    // Implementación existente...
    return Container(); // Placeholder
  }

  Widget _buildWorkoutCompleted() {
    // Implementación existente...
    return Container(); // Placeholder
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _techniqueIndicatorController.dispose(); // 🆕
    _weightController.dispose();
    _repsController.dispose();

    // 🆕 LIMPIAR RECURSOS DE ML KIT
    _formAnalysisCamera.dispose();

    super.dispose();
  }
}

enum WorkoutPhase {
  selectRoutine,
  exerciseReady,
  exerciseActive,
  resting,
  completed,
}