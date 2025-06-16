// lib/screens/workout_session_screen.dart - CON IA HÍBRIDA
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import '../utils/app_colors.dart';
import '../domain/exercise.dart';
import '../domain/rutina.dart';
import '../domain/user.dart';
import '../database/DatabaseHelper.dart';
// IMPORTS PARA ML KIT + IA
import '../services/form_analysis_camera.dart';
import '../services/ai_from_coach.dart';
import '../models/form_feedback.dart';
import '../models/form_score.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final User? user; // 🆕 Usuario para personalización IA

  const WorkoutSessionScreen({Key? key, this.user}) : super(key: key);

  @override
  _WorkoutSessionScreenState createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // 📋 ESTADO DE LA SESIÓN
  List<Rutina> _availableRoutines = [];
  Rutina? _selectedRoutine;
  List<Exercise> _routineExercises = [];

  // 🏋️ ESTADO DEL EJERCICIO ACTUAL
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  Exercise? get _currentExercise => _routineExercises.isNotEmpty ? _routineExercises[_currentExerciseIndex] : null;

  // ⏱️ ESTADO DEL CRONÓMETRO
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  // 😴 ESTADO DEL DESCANSO
  Timer? _restTimer;
  int _restSeconds = 180;
  bool _isResting = false;

  // 📊 DATOS DEL SET ACTUAL
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  // 🎭 ANIMACIONES
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  // 📱 ESTADOS DE UI
  bool _isLoading = true;
  WorkoutPhase _currentPhase = WorkoutPhase.selectRoutine;

  // 🆕 ========== SISTEMA IA HÍBRIDO ==========

  // 📹 Controlador de análisis con IA
  late FormAnalysisCamera _formAnalysisCamera;
  bool _isCameraReady = false;
  bool _isAnalyzingForm = false;

  // 🤖 Datos de IA en tiempo real
  FormScore? _currentFormScore;
  RealTimeCoaching? _currentCoaching; // 🆕 Coaching en tiempo real
  FormFeedback? _lastSetFeedback;
  PostWorkoutAnalysis? _lastPostAnalysis; // 🆕 Análisis post-entrenamiento

  // 🎯 Animaciones IA
  late AnimationController _aiCoachingController;
  late Animation<double> _aiCoachingAnimation;

  // 📈 Estadísticas de la sesión
  List<FormFeedback> _sessionFeedbacks = [];
  List<PostWorkoutAnalysis> _sessionAnalyses = []; // 🆕 Análisis de IA

  // 🎙️ Coaching de voz
  bool _voiceCoachingEnabled = true;
  Timer? _voiceCoachingTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadRoutines();
    _initializeAISystem(); // 🆕 Inicializar sistema IA
  }

  /// 🤖 INICIALIZAR SISTEMA IA HÍBRIDO
  Future<void> _initializeAISystem() async {
    try {
      print('🤖 Inicializando sistema IA híbrido...');

      _formAnalysisCamera = FormAnalysisCamera();

      // 🆕 CONFIGURAR CALLBACKS IA MEJORADOS
      _formAnalysisCamera.onFormScoreUpdate = (FormScore score) {
        if (mounted) {
          setState(() {
            _currentFormScore = score;
          });
          _updateTechniqueIndicator(score.score);
        }
      };

      // 🆕 Coaching en tiempo real
      _formAnalysisCamera.onRealTimeCoaching = (RealTimeCoaching coaching) {
        if (mounted) {
          setState(() {
            _currentCoaching = coaching;
          });
          _triggerCoachingAnimation();

          // Coaching de voz si está habilitado
          if (_voiceCoachingEnabled && coaching.isPositive) {
            _speakCoaching(coaching.message);
          }
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

      // 🆕 Análisis post-entrenamiento con IA
      _formAnalysisCamera.onPostWorkoutAnalysis = (PostWorkoutAnalysis analysis) {
        if (mounted) {
          setState(() {
            _lastPostAnalysis = analysis;
            _sessionAnalyses.add(analysis);
          });
          _showPostWorkoutAnalysis(analysis);
        }
      };

      // Inicializar cámara
      final success = await _formAnalysisCamera.initialize();
      if (success && mounted) {
        setState(() {
          _isCameraReady = true;
        });
        print('✅ Sistema IA híbrido inicializado correctamente');
      }

    } catch (e) {
      print('❌ Error inicializando sistema IA: $e');
      _showError('Error inicializando sistema IA');
    }
  }

  void _setupAnimations() {
    // Animaciones existentes
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

    // 🆕 Animación para coaching IA
    _aiCoachingController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _aiCoachingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _aiCoachingController, curve: Curves.elasticOut),
    );
  }

  /// 🆕 TRIGGER ANIMACIÓN DE COACHING
  void _triggerCoachingAnimation() {
    _aiCoachingController.forward().then((_) {
      Timer(Duration(seconds: 2), () {
        if (mounted) _aiCoachingController.reverse();
      });
    });
  }

  /// 🎙️ HABLAR COACHING (Text-to-Speech simulado)
  void _speakCoaching(String message) {
    // Implementar TTS aquí si es necesario
    print('🎙️ TTS: $message');
  }

  void _updateTechniqueIndicator(double score) {
    if (score >= 7.0) {
      _aiCoachingController.forward();
    } else {
      _aiCoachingController.reverse();
    }
  }

  // MÉTODOS DE CARGA DE RUTINAS (sin cambios)
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

      // 🆕 CONFIGURAR CÁMARA CON INFORMACIÓN DEL USUARIO
      _setupCameraForCurrentExercise();
    }
  }

  /// 🆕 CONFIGURAR CÁMARA CON IA PARA EJERCICIO ACTUAL
  Future<void> _setupCameraForCurrentExercise() async {
    print('🎥 Configurando cámara con IA para: ${_currentExercise?.nombre}');

    if (!_isCameraReady || _currentExercise == null) {
      print('❌ Cámara no lista o ejercicio null');
      return;
    }

    try {
      // 🆕 Pasar usuario para personalización IA
      final success = await _formAnalysisCamera.setupCameraForExercise(
        _currentExercise!,
        user: widget.user,
      );

      if (success) {
        setState(() {
          // Forzar rebuild
        });

        final instructions = _formAnalysisCamera.getCameraPositionInstructions();
        _showInfo(instructions);

        print('✅ Cámara con IA configurada correctamente');
      } else {
        _showError('Error configurando cámara IA');
      }

    } catch (e) {
      print('❌ Error configurando cámara IA: $e');
      _showError('Error configurando cámara IA: $e');
    }
  }

  // ⏱️ CONTROL DEL CRONÓMETRO CON IA
  void _startSet() {
    setState(() {
      _currentPhase = WorkoutPhase.exerciseActive;
      _isRunning = true;
      _seconds = 0;
      _currentFormScore = null;
      _currentCoaching = null; // 🆕 Reset coaching
      _lastSetFeedback = null;
      _lastPostAnalysis = null; // 🆕 Reset análisis
    });

    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });

    // Iniciar análisis con IA
    _startAIAnalysis();
  }

  /// 🆕 INICIAR ANÁLISIS CON IA
  Future<void> _startAIAnalysis() async {
    if (!_isCameraReady) {
      print('⚠️ Cámara no lista para análisis IA');
      return;
    }

    try {
      print('🤖 Iniciando análisis con IA...');

      setState(() {
        _isAnalyzingForm = true;
      });

      await _formAnalysisCamera.startAnalysis();

      // Iniciar coaching de voz periódico
      if (_voiceCoachingEnabled) {
        _voiceCoachingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
          if (_currentFormScore != null) {
            final voiceMessage = _formAnalysisCamera.getVoiceCoaching(_currentFormScore!);
            if (voiceMessage.isNotEmpty) {
              _speakCoaching(voiceMessage);
            }
          }
        });
      }

      print('✅ Análisis IA iniciado');

    } catch (e) {
      print('❌ Error iniciando análisis IA: $e');
      _showError('Error iniciando análisis IA');
    }
  }

  void _finishSet() async {
    _timer?.cancel();
    _voiceCoachingTimer?.cancel(); // 🆕 Parar coaching de voz
    _pulseController.stop();
    _waveController.stop();

    // Detener análisis y obtener feedback con IA
    FormFeedback? feedback;
    if (_isAnalyzingForm) {
      try {
        print('🛑 Deteniendo análisis IA...');
        feedback = await _formAnalysisCamera.stopAnalysis();
        print('📊 Feedback IA obtenido: ${feedback.averageScore.toStringAsFixed(1)}/10');
      } catch (e) {
        print('❌ Error obteniendo feedback IA: $e');
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

  /// 🆕 MOSTRAR ANÁLISIS POST-ENTRENAMIENTO
  void _showPostWorkoutAnalysis(PostWorkoutAnalysis analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: AppColors.pastelBlue),
            SizedBox(width: 8),
            Text(
              'Análisis de PrinceIA',
              style: GoogleFonts.poppins(color: AppColors.white),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                analysis.aiAnalysis,
                style: GoogleFonts.poppins(color: AppColors.white, fontSize: 14),
              ),
              SizedBox(height: 16),

              if (analysis.strengthsIdentified.isNotEmpty) ...[
                Text(
                  '💪 Fortalezas:',
                  style: GoogleFonts.poppins(color: AppColors.pastelGreen, fontWeight: FontWeight.bold),
                ),
                ...analysis.strengthsIdentified.map((strength) => Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text('• $strength', style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12)),
                )),
                SizedBox(height: 12),
              ],

              if (analysis.weaknessesIdentified.isNotEmpty) ...[
                Text(
                  '🎯 A mejorar:',
                  style: GoogleFonts.poppins(color: AppColors.pastelOrange, fontWeight: FontWeight.bold),
                ),
                ...analysis.weaknessesIdentified.map((weakness) => Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text('• $weakness', style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12)),
                )),
                SizedBox(height: 12),
              ],

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
                      '🚀 Próxima sesión:',
                      style: GoogleFonts.poppins(color: AppColors.pastelBlue, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      analysis.nextSessionFocus,
                      style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continuar', style: TextStyle(color: AppColors.pastelBlue)),
          ),
        ],
      ),
    );
  }

  // MÉTODOS DE UI EXISTENTES CON MEJORAS IA

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                '🤖 Preparando PrinceIA...',
                style: GoogleFonts.poppins(color: AppColors.white),
              ),
            ],
          ),
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

  Widget _buildCurrentPhase() {
    switch (_currentPhase) {
      case WorkoutPhase.selectRoutine:
        return _buildRoutineSelection();
      case WorkoutPhase.exerciseReady:
        return _buildExerciseReady();
      case WorkoutPhase.exerciseActive:
        return _buildExerciseActiveWithAI(); // 🆕 Con IA
      case WorkoutPhase.resting:
        return _buildRestingStateWithAI(); // 🆕 Con IA
      case WorkoutPhase.completed:
        return _buildWorkoutCompletedWithAI(); // 🆕 Con IA
    }
  }

  /// 🆕 EJERCICIO ACTIVO CON IA
  Widget _buildExerciseActiveWithAI() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWorkoutHeader(),
          SizedBox(height: 20),

          // Vista principal con cámara IA
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Panel izquierdo: Cronómetro y stats
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildMainTimer(),
                      SizedBox(height: 20),
                      _buildCurrentSetInfo(),
                      SizedBox(height: 20),
                      _buildAIStats(), // 🆕 Estadísticas IA
                    ],
                  ),
                ),

                SizedBox(width: 20),

                // Panel derecho: Cámara con análisis IA
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Vista de cámara con overlay IA
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _currentFormScore != null
                                  ? _currentFormScore!.color
                                  : AppColors.grey,
                              width: 3,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: _isCameraReady
                                ? _formAnalysisCamera.buildCameraPreview(showAIOverlay: true) // 🆕 Con overlay IA
                                : _buildCameraPlaceholder(),
                          ),
                        ),
                      ),

                      SizedBox(height: 12),

                      // 🆕 Panel de coaching IA en tiempo real
                      _buildAICoachingPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Controles
          Row(
            children: [
              // Toggle coaching de voz
              _buildVoiceCoachingToggle(),
              Spacer(),
              // Botón terminar set
              Expanded(flex: 2, child: _buildFinishSetButton()),
            ],
          ),
        ],
      ),
    );
  }

  /// 🆕 PANEL DE COACHING IA EN TIEMPO REAL
  Widget _buildAICoachingPanel() {
    return AnimatedBuilder(
      animation: _aiCoachingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_aiCoachingAnimation.value * 0.05),
          child: Container(
            height: 100,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _currentCoaching?.isPositive == true
                    ? AppColors.pastelGreen
                    : AppColors.pastelOrange,
                width: _aiCoachingAnimation.value * 2,
              ),
            ),
            child: _currentCoaching != null
                ? Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.smart_toy, color: AppColors.pastelBlue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'PrinceIA',
                      style: GoogleFonts.poppins(
                        color: AppColors.pastelBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Spacer(),
                    Text(
                      _currentCoaching!.score.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        color: _currentCoaching!.isPositive ? AppColors.pastelGreen : AppColors.pastelOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  _currentCoaching!.message,
                  style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
                : Center(
              child: Text(
                _isAnalyzingForm ? '🤖 PrinceIA analizando...' : '🎯 Presiona iniciar',
                style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 14),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🆕 ESTADÍSTICAS IA
  Widget _buildAIStats() {
    final stats = _formAnalysisCamera.getCurrentStats();

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '🤖 Stats IA',
            style: GoogleFonts.poppins(
              color: AppColors.pastelBlue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reps:', style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12)),
              Text('${stats['currentReps']}', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Promedio:', style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12)),
              Text('${(stats['averageScore'] as double).toStringAsFixed(1)}', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  /// 🆕 TOGGLE COACHING DE VOZ
  Widget _buildVoiceCoachingToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _voiceCoachingEnabled = !_voiceCoachingEnabled;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _voiceCoachingEnabled ? AppColors.pastelBlue : AppColors.surfaceBlack,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _voiceCoachingEnabled ? Icons.volume_up : Icons.volume_off,
              color: AppColors.white,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              'Voz',
              style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// 🆕 ESTADO DE DESCANSO CON ANÁLISIS IA
  Widget _buildRestingStateWithAI() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWorkoutHeader(),
          SizedBox(height: 20),

          // Análisis IA del set anterior
          if (_lastPostAnalysis != null) ...[
            _buildAIAnalysisCard(_lastPostAnalysis!),
            SizedBox(height: 20),
          ] else if (_lastSetFeedback != null) ...[
            _buildSetFeedbackCard(),
            SizedBox(height: 20),
          ],

          // Cronómetro de descanso
          _buildRestTimer(),

          SizedBox(height: 20),

          // Información del próximo set
          _buildNextSetInfo(),

          Spacer(),

          // Acciones de descanso
          _buildRestActions(),
        ],
      ),
    );
  }

  /// 🆕 TARJETA DE ANÁLISIS IA
  Widget _buildAIAnalysisCard(PostWorkoutAnalysis analysis) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pastelBlue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy, color: AppColors.pastelBlue),
              SizedBox(width: 8),
              Text(
                'Análisis de PrinceIA',
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          Text(
            analysis.aiAnalysis,
            style: GoogleFonts.poppins(color: AppColors.white, fontSize: 14),
          ),

          if (analysis.strengthsIdentified.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              '💪 Fortalezas identificadas:',
              style: GoogleFonts.poppins(color: AppColors.pastelGreen, fontWeight: FontWeight.bold),
            ),
            ...analysis.strengthsIdentified.take(2).map((strength) => Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('• $strength', style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12)),
            )),
          ],

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
                  '🎯 Próxima sesión:',
                  style: GoogleFonts.poppins(color: AppColors.pastelBlue, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  analysis.nextSessionFocus,
                  style: GoogleFonts.poppins(color: AppColors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // RESTO DE MÉTODOS UI (reutilizar los existentes con pequeñas mejoras)

  Widget _buildWorkoutHeader() {
    return Column(
      children: [
        Text(
          _currentExercise?.nombre ?? 'Cargando...',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Set $_currentSet de ${_currentExercise?.series ?? 0}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.grey,
              ),
            ),
            if (_isCameraReady) ...[
              SizedBox(width: 8),
              Icon(Icons.smart_toy, color: AppColors.pastelBlue, size: 16),
            ],
          ],
        ),
      ],
    );
  }

  // ... [incluir todos los métodos UI restantes del código anterior]
  // [Para brevedad, incluyo solo los métodos clave, pero debes mantener todos los existentes]

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
            Icon(Icons.smart_toy, color: AppColors.pastelBlue, size: 48),
            SizedBox(height: 16),
            Text(
              _isCameraReady ? '🤖 Preparando análisis IA...' : '🎥 Inicializando cámara...',
              style: GoogleFonts.poppins(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ... [resto de métodos UI existentes]

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

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    _voiceCoachingTimer?.cancel(); // 🆕
    _pulseController.dispose();
    _waveController.dispose();
    _aiCoachingController.dispose(); // 🆕
    _weightController.dispose();
    _repsController.dispose();

    // Limpiar recursos IA
    _formAnalysisCamera.dispose();

    super.dispose();
  }

// ... [incluir métodos restantes como _buildMainTimer, _buildSetFeedbackCard, etc.]
}

enum WorkoutPhase {
  selectRoutine,
  exerciseReady,
  exerciseActive,
  resting,
  completed,
}