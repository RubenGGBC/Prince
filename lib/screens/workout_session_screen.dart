// lib/screens/workout_session_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import '../core/app_colors.dart';
import '../data/database_helper.dart';
import '../domain/rutina.dart';
import '../domain/exercise.dart';
import '../services/form_analysis_camera.dart';
import '../models/form_feedback.dart';
import '../models/form_score.dart';

enum WorkoutPhase {
  selectRoutine,
  exerciseReady,
  exerciseActive,
  resting,
  completed,
}

class WorkoutSessionScreen extends StatefulWidget {
  @override
  _WorkoutSessionScreenState createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with TickerProviderStateMixin {

  // 📊 Estado básico del workout
  final DatabaseHelper _dbHelper = DatabaseHelper();
  WorkoutPhase _currentPhase = WorkoutPhase.selectRoutine;
  bool _isLoading = true;

  // 🏋️ Rutinas y ejercicios
  List<Rutina> _availableRoutines = [];
  Rutina? _selectedRoutine;
  List<Exercise> _routineExercises = [];
  int _currentExerciseIndex = 0;
  int _currentSet = 1;

  // ⏱️ Control de tiempo
  Timer? _timer;
  Timer? _restTimer;
  bool _isRunning = false;
  bool _isResting = false;
  int _seconds = 0;
  int _restSeconds = 60;

  // 🎨 Animaciones
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  late AnimationController _techniqueIndicatorController;
  late Animation<double> _techniqueIndicatorAnimation;

  // 📱 Controles de input
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();

  // 🎥 Análisis de técnica con cámara
  FormAnalysisCamera? _formAnalysisCamera;
  bool _isCameraReady = false;
  bool _isAnalyzingForm = false;
  FormScore? _currentFormScore;
  FormFeedback? _lastSetFeedback;

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

  // 🆕 INICIALIZACIÓN COMPLETA DEL ANÁLISIS DE TÉCNICA
  Future<void> _initializeFormAnalysis() async {
    try {
      print('🎬 Inicializando sistema de análisis de técnica...');

      _formAnalysisCamera = FormAnalysisCamera();

      // 🔧 CALLBACKS DETALLADOS
      _formAnalysisCamera!.onFormScoreUpdate = (FormScore score) {
        print('📊 Score actualizado: ${score.score.toStringAsFixed(1)}');
        if (mounted) {
          setState(() {
            _currentFormScore = score;
          });
          _updateTechniqueIndicator(score.score);
        }
      };

      _formAnalysisCamera!.onError = (String error) {
        print('❌ ERROR DE CÁMARA: $error');
        if (mounted) {
          _showError('Error de cámara: $error');
        }
      };

      _formAnalysisCamera!.onSetComplete = (FormFeedback feedback) {
        print('📋 Set completado - Puntuación: ${feedback.averageScore.toStringAsFixed(1)}');
        if (mounted) {
          setState(() {
            _lastSetFeedback = feedback;
            _sessionFeedbacks.add(feedback);
          });
        }
      };

      // 🎥 INICIALIZAR CÁMARA
      print('🎥 Intentando inicializar cámara...');
      final success = await _formAnalysisCamera!.initialize();

      print('📋 Resultado inicialización: $success');

      if (success && mounted) {
        setState(() {
          _isCameraReady = true;
        });
        print('✅ Sistema de análisis inicializado correctamente');
      } else {
        print('❌ FALLO EN INICIALIZACIÓN - _isCameraReady: false');
        _showError('No se pudo inicializar la cámara');
      }

    } catch (e) {
      print('❌ EXCEPCIÓN inicializando análisis: $e');
      _showError('Error inicializando análisis de técnica: $e');
    }
  }

  void _setupAnimations() {
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

    _techniqueIndicatorController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _techniqueIndicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _techniqueIndicatorController, curve: Curves.easeInOut),
    );
  }

  void _updateTechniqueIndicator(double score) {
    if (score >= 7.0) {
      _techniqueIndicatorController.forward();
    } else {
      _techniqueIndicatorController.reverse();
    }
  }

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

  // 🆕 CONFIGURAR CÁMARA PARA EJERCICIO ESPECÍFICO
  Future<void> _setupCameraForCurrentExercise() async {
    if (!_isCameraReady || _currentExercise == null || _formAnalysisCamera == null) {
      print('⚠️ No se puede configurar cámara - Ready: $_isCameraReady, Exercise: ${_currentExercise?.nombre}, Camera: ${_formAnalysisCamera != null}');
      return;
    }

    try {
      print('🎥 Configurando cámara para: ${_currentExercise!.nombre}');

      await _formAnalysisCamera!.setupCameraForExercise(_currentExercise!);

      // Mostrar instrucciones de posicionamiento
      final instructions = _formAnalysisCamera!.getCameraPositionInstructions();
      _showInfo('Posicionamiento: $instructions');

    } catch (e) {
      print('❌ Error configurando cámara: $e');
      _showError('Error configurando cámara para el ejercicio');
    }
  }

  // ⏱️ CONTROL DEL CRONÓMETRO
  void _startSet() {
    setState(() {
      _currentPhase = WorkoutPhase.exerciseActive;
      _isRunning = true;
      _seconds = 0;
      _currentFormScore = null;
      _lastSetFeedback = null;
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

  Future<void> _startFormAnalysis() async {
    if (!_isCameraReady || _formAnalysisCamera == null) {
      print('⚠️ Cámara no lista para análisis - Ready: $_isCameraReady');
      return;
    }

    try {
      print('🎬 Iniciando grabación y análisis...');

      setState(() {
        _isAnalyzingForm = true;
      });

      await _formAnalysisCamera!.startAnalysis();

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
    if (_isAnalyzingForm && _formAnalysisCamera != null) {
      try {
        feedback = await _formAnalysisCamera!.stopAnalysis();
        setState(() {
          _isAnalyzingForm = false;
          _lastSetFeedback = feedback;
        });
      } catch (e) {
        print('❌ Error obteniendo feedback: $e');
      }
    }

    setState(() {
      _isRunning = false;
      _currentPhase = WorkoutPhase.resting;
      _isResting = true;
      _restSeconds = 60;
    });

    _startRestTimer();
  }

  void _startRestTimer() {
    _restTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _restSeconds--;
      });

      if (_restSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isResting = false;
          _currentPhase = WorkoutPhase.exerciseReady;
        });
        _checkNextSet();
      }
    });
  }

  void _checkNextSet() {
    if (_currentSet < 3) {
      setState(() {
        _currentSet++;
      });
    } else {
      _nextExercise();
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
  }

  // 🎥 WIDGET DE PREVIEW DE CÁMARA CORREGIDO
  Widget _buildCameraPreview() {
    print('🎬 Construyendo preview de cámara...');
    print('📋 _isCameraReady: $_isCameraReady');
    print('📋 _formAnalysisCamera: ${_formAnalysisCamera != null}');

    if (!_isCameraReady || _formAnalysisCamera?.cameraController == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.cardBlack,
          border: Border.all(color: AppColors.grey, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.pastelBlue,
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                _isCameraReady ? 'Configurando cámara...' : 'Inicializando cámara...',
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_formAnalysisCamera!.cameraController!.value.isInitialized) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.cardBlack,
          border: Border.all(color: AppColors.pastelOrange, width: 2),
        ),
        child: Center(
          child: Text(
            'Cámara no inicializada',
            style: GoogleFonts.poppins(color: AppColors.white),
          ),
        ),
      );
    }

    // 🎥 PREVIEW REAL DE LA CÁMARA
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _formAnalysisCamera!.cameraController!.value.aspectRatio,
        child: CameraPreview(_formAnalysisCamera!.cameraController!),
      ),
    );
  }

  // 🎯 INDICADOR DE TÉCNICA EN TIEMPO REAL
  Widget _buildTechniqueIndicator() {
    if (_currentFormScore == null) {
      return Container(
        height: 40,
        child: Center(
          child: Text(
            'Esperando análisis...',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    final score = _currentFormScore!.score;
    final color = score >= 8.0
        ? AppColors.pastelGreen
        : score >= 6.0
        ? AppColors.pastelBlue
        : AppColors.pastelOrange;

    return AnimatedBuilder(
      animation: _techniqueIndicatorAnimation,
      builder: (context, child) {
        return Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2 + (_techniqueIndicatorAnimation.value * 0.3)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                score >= 8.0 ? Icons.check_circle :
                score >= 6.0 ? Icons.thumb_up :
                Icons.warning,
                color: color,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '${score.toStringAsFixed(1)}/10',
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // UI WIDGETS PRINCIPALES

  Widget _buildCurrentPhase() {
    switch (_currentPhase) {
      case WorkoutPhase.selectRoutine:
        return _buildRoutineSelection();
      case WorkoutPhase.exerciseReady:
        return _buildExerciseReady();
      case WorkoutPhase.exerciseActive:
        return _buildExerciseActive();
      case WorkoutPhase.resting:
        return _buildRestingState();
      case WorkoutPhase.completed:
        return _buildWorkoutCompleted();
    }
  }

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

  Widget _buildExerciseReady() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWorkoutHeader(),
          SizedBox(height: 30),
          _buildExerciseCard(),
          SizedBox(height: 30),
          _buildInputFields(),
          Spacer(),
          _buildReadyButton(),
        ],
      ),
    );
  }

  Widget _buildExerciseActive() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWorkoutHeader(),
          SizedBox(height: 20),

          // 🆕 VISTA PRINCIPAL CON CÁMARA
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
                          child: _buildCameraPreview(),
                        ),
                      ),

                      SizedBox(height: 12),

                      // Indicador de técnica en tiempo real
                      _buildTechniqueIndicator(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Botón para finalizar set
          _buildFinishButton(),
        ],
      ),
    );
  }

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

  Widget _buildSetFeedbackCard() {
    if (_lastSetFeedback == null) return SizedBox();

    final feedback = _lastSetFeedback!;
    final color = feedback.averageScore >= 8.0
        ? AppColors.pastelGreen
        : feedback.averageScore >= 6.0
        ? AppColors.pastelBlue
        : AppColors.pastelOrange;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Técnica del Set',
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${feedback.averageScore.toStringAsFixed(1)}/10',
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            feedback.mainComment,
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
          if (feedback.tips.isNotEmpty) ...[
            SizedBox(height: 8),
            ...feedback.tips.map((tip) => Text(
              '• $tip',
              style: GoogleFonts.poppins(
                color: AppColors.grey,
                fontSize: 12,
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutCompleted() {
    final avgScore = _sessionFeedbacks.isNotEmpty
        ? _sessionFeedbacks.map((f) => f.averageScore).reduce((a, b) => a + b) / _sessionFeedbacks.length
        : 0.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🎉 ¡Entrenamiento Completado!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Puntuación Técnica Promedio:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),
          Text(
            '${avgScore.toStringAsFixed(1)}/10',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: avgScore >= 8.0
                  ? AppColors.pastelGreen
                  : avgScore >= 6.0
                  ? AppColors.pastelBlue
                  : AppColors.pastelOrange,
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pastelBlue,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: Text(
              'Finalizar',
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGETS DE SOPORTE

  Widget _buildWorkoutHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => _showExitDialog(),
          icon: Icon(Icons.arrow_back, color: AppColors.white),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                _selectedRoutine?.nombre ?? 'Entrenamiento',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              if (_currentExercise != null)
                Text(
                  '${_currentExerciseIndex + 1}/${_routineExercises.length} - Set $_currentSet/3',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard() {
    if (_currentExercise == null) return SizedBox();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getExerciseColor(_currentExercise!.grupoMuscular),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            _currentExercise!.nombre,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _currentExercise!.grupoMuscular,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _getExerciseColor(_currentExercise!.grupoMuscular),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'Peso (kg)',
              labelStyle: GoogleFonts.poppins(color: AppColors.grey),
              filled: true,
              fillColor: AppColors.cardBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _repsController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'Repeticiones',
              labelStyle: GoogleFonts.poppins(color: AppColors.grey),
              filled: true,
              fillColor: AppColors.cardBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyButton() {
    return ElevatedButton(
      onPressed: _startSet,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.pastelGreen,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(
        'Iniciar Serie',
        style: GoogleFonts.poppins(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildMainTimer() {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
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
                    'Ejercicio',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.grey,
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Set $_currentSet/3',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${_weightController.text}kg × ${_repsController.text} reps',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishButton() {
    return ElevatedButton(
      onPressed: _finishSet,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.pastelOrange,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(
        'Finalizar Serie',
        style: GoogleFonts.poppins(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
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

  // GETTERS Y UTILIDADES

  Exercise? get _currentExercise {
    if (_routineExercises.isEmpty || _currentExerciseIndex >= _routineExercises.length) {
      return null;
    }
    return _routineExercises[_currentExerciseIndex];
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

  void _showError(String message) {
    print('🚨 MOSTRANDO ERROR: $message');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _showInfo(String message) {
    print('ℹ️ INFO: $message');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.pastelBlue,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text('Salir del Entrenamiento', style: TextStyle(color: AppColors.white)),
        content: Text(
          'Se perderá el progreso actual. ¿Estás seguro?',
          style: TextStyle(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Salir', style: TextStyle(color: AppColors.pastelOrange)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _techniqueIndicatorController.dispose();
    _weightController.dispose();
    _repsController.dispose();

    // 🧹 LIMPIAR RECURSOS DE CÁMARA
    _formAnalysisCamera?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.pastelBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: _buildCurrentPhase(),
      ),
    );
  }
}