import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import '../utils/app_colors.dart';
import '../domain/exercise.dart';
import '../domain/rutina.dart';
import '../database/DatabaseHelper.dart';

class WorkoutSessionScreen extends StatefulWidget {
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
  int _restSeconds = 180; // 3 minutos = 180 segundos
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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadRoutines();
  }

  void _setupAnimations() {
    // 💓 Animación de pulso para el cronómetro
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 🌊 Animación ondulante para la técnica
    _waveController = AnimationController(
      duration: Duration(milliseconds: 4000), // 4 segundos: 2 subida + 2 bajada
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
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
        _currentPhase = WorkoutPhase.exerciseReady;
        _currentExerciseIndex = 0;
        _currentSet = 1;
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
    }
  }

  // ⏱️ CONTROL DEL CRONÓMETRO
  void _startSet() {
    setState(() {
      _currentPhase = WorkoutPhase.exerciseActive;
      _isRunning = true;
      _seconds = 0;
    });

    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _finishSet() {
    _timer?.cancel();
    _pulseController.stop();
    _waveController.stop();

    setState(() {
      _isRunning = false;
      _currentPhase = WorkoutPhase.resting;
      _isResting = true;
      _restSeconds = 180; // Reset a 3 minutos
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
      _finishWorkout();
    }
  }

  void _finishWorkout() {
    setState(() {
      _currentPhase = WorkoutPhase.completed;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildCompletionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: _buildPhaseContent(),
      ),
    );
  }

  Widget _buildPhaseContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

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
        return _buildCompletedState();
    }
  }

  // 📋 SELECCIÓN DE RUTINA
  Widget _buildRoutineSelection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios, color: AppColors.white),
              ),
              SizedBox(width: 12),
              Text(
                'Seleccionar Rutina',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),

          SizedBox(height: 30),

          // Lista de rutinas
          Expanded(
            child: _availableRoutines.isEmpty
                ? _buildEmptyRoutines()
                : ListView.builder(
              itemCount: _availableRoutines.length,
              itemBuilder: (context, index) {
                final routine = _availableRoutines[index];
                return _buildRoutineCard(routine);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(Rutina routine) {
    final color = _getRoutineColor(routine.categoria);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectRoutine(routine),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getRoutineIcon(routine.categoria),
                    color: color,
                    size: 30,
                  ),
                ),

                SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        routine.descripcion,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoChip(
                            '${routine.cantidadEjercicios} ejercicios',
                            Icons.fitness_center,
                            AppColors.pastelBlue,
                          ),
                          SizedBox(width: 8),
                          _buildInfoChip(
                            routine.duracionFormateada,
                            Icons.timer,
                            AppColors.pastelOrange,
                          ),
                          SizedBox(width: 8),
                          _buildInfoChip(
                            routine.categoria,
                            Icons.label,
                            color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.play_circle_filled,
                  color: color,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🏋️ EJERCICIO LISTO
  Widget _buildExerciseReady() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Header con progreso
          _buildWorkoutHeader(),

          SizedBox(height: 30),

          // Información del ejercicio
          _buildExerciseInfo(),

          SizedBox(height: 30),

          // Inputs de peso y repeticiones
          _buildSetInputs(),

          SizedBox(height: 30),

          // Botón para empezar set
          _buildStartSetButton(),

          Spacer(),

          // Navegación entre ejercicios
          _buildExerciseNavigation(),
        ],
      ),
    );
  }

  // 🏃 EJERCICIO ACTIVO
  Widget _buildExerciseActive() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWorkoutHeader(),

          SizedBox(height: 20),

          // Cronómetro principal
          _buildMainTimer(),

          SizedBox(height: 30),

          // Barra ondulante de técnica
          _buildTechniqueWave(),

          SizedBox(height: 30),

          // Información del set actual
          _buildCurrentSetInfo(),

          Spacer(),

          // Botón terminar set
          _buildFinishSetButton(),
        ],
      ),
    );
  }

  // 😴 ESTADO DE DESCANSO
  Widget _buildRestingState() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWorkoutHeader(),

          Spacer(),

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

        // Barra de progreso
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
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.grey,
          ),
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
            width: 200,
            height: 200,
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
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    'Set $_currentSet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
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

  Widget _buildTechniqueWave() {
    return Container(
      height: 100,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Guía de Técnica',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),

          SizedBox(height: 16),

          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Barra de fondo
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Bolita ondulante
                  Positioned(
                    left: _waveAnimation.value * (MediaQuery.of(context).size.width - 80),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _waveAnimation.value < 0.5
                            ? AppColors.pastelGreen  // Subida
                            : AppColors.pastelOrange, // Bajada
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_waveAnimation.value < 0.5
                                ? AppColors.pastelGreen
                                : AppColors.pastelOrange).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subida (2s)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.pastelGreen,
                ),
              ),
              Text(
                'Bajada (2s)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.pastelOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimer() {
    final minutes = _restSeconds ~/ 60;
    final seconds = _restSeconds % 60;

    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.pastelBlue,
          width: 4,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.poppins(
                fontSize: 48,
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

  // 🔧 WIDGETS DE APOYO Y UTILIDADES

  Widget _buildExerciseInfo() {
    if (_currentExercise == null) return SizedBox();

    final color = _getExerciseColor(_currentExercise!.grupoMuscular);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getExerciseIcon(_currentExercise!.grupoMuscular),
                  color: color,
                  size: 30,
                ),
              ),

              SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentExercise!.nombre,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      _currentExercise!.grupoMuscular,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildExerciseDetailItem(
                'Set',
                '$_currentSet/${_currentExercise!.series}',
                Icons.repeat,
                AppColors.pastelBlue,
              ),
              _buildExerciseDetailItem(
                'Reps',
                '${_currentExercise!.repeticiones}',
                Icons.fitness_center,
                AppColors.pastelGreen,
              ),
              _buildExerciseDetailItem(
                'Peso',
                '${_currentExercise!.peso}kg',
                Icons.monitor_weight,
                AppColors.pastelOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetailItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSetInputs() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personalizar Set',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),

          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.poppins(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Peso (kg)',
                    labelStyle: GoogleFonts.poppins(color: AppColors.grey),
                    prefixIcon: Icon(Icons.monitor_weight, color: AppColors.pastelOrange),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.pastelOrange),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 20),

              Expanded(
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Repeticiones',
                    labelStyle: GoogleFonts.poppins(color: AppColors.grey),
                    prefixIcon: Icon(Icons.fitness_center, color: AppColors.pastelGreen),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.pastelGreen),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartSetButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.pastelPink.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _startSet,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled, color: AppColors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Empezar Set $_currentSet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishSetButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.pastelGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.pastelGreen.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _finishSet,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Terminar Set',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSetInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                _weightController.text,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pastelOrange,
                ),
              ),
              Text(
                'kg',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          Container(
            width: 2,
            height: 40,
            color: AppColors.grey.withOpacity(0.3),
          ),
          Column(
            children: [
              Text(
                _repsController.text,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pastelGreen,
                ),
              ),
              Text(
                'reps',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: _currentExerciseIndex > 0 ? () {
            setState(() {
              _currentExerciseIndex--;
              _currentSet = 1;
            });
            _prepareExercise();
          } : null,
          icon: Icon(Icons.arrow_back_ios, color: _currentExerciseIndex > 0 ? AppColors.pastelBlue : AppColors.grey),
          label: Text(
            'Anterior',
            style: GoogleFonts.poppins(
              color: _currentExerciseIndex > 0 ? AppColors.pastelBlue : AppColors.grey,
            ),
          ),
        ),

        TextButton.icon(
          onPressed: _currentExerciseIndex < _routineExercises.length - 1 ? () {
            setState(() {
              _currentExerciseIndex++;
              _currentSet = 1;
            });
            _prepareExercise();
          } : null,
          icon: Icon(Icons.arrow_forward_ios, color: _currentExerciseIndex < _routineExercises.length - 1 ? AppColors.pastelBlue : AppColors.grey),
          label: Text(
            'Siguiente',
            style: GoogleFonts.poppins(
              color: _currentExerciseIndex < _routineExercises.length - 1 ? AppColors.pastelBlue : AppColors.grey,
            ),
          ),
        ),
      ],
    );
  }

  // 🔧 MÉTODOS DE UTILIDAD

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 COLORES E ICONOS

  Color _getRoutineColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'fuerza': return AppColors.pastelBlue;
      case 'cardio': return Colors.red;
      case 'funcional': return AppColors.pastelGreen;
      case 'principiante': return AppColors.pastelOrange;
      case 'avanzado': return AppColors.pastelPurple;
      default: return AppColors.grey;
    }
  }

  IconData _getRoutineIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'fuerza': return Icons.fitness_center;
      case 'cardio': return Icons.favorite;
      case 'funcional': return Icons.sports_gymnastics;
      case 'principiante': return Icons.school;
      case 'avanzado': return Icons.workspace_premium;
      default: return Icons.category;
    }
  }

  Color _getExerciseColor(String grupoMuscular) {
    switch (grupoMuscular.toLowerCase()) {
      case 'pecho': return AppColors.pastelPink;
      case 'espalda': return AppColors.pastelGreen;
      case 'piernas': return AppColors.pastelBlue;
      case 'hombros': return AppColors.pastelPurple;
      case 'brazos': return AppColors.pastelOrange;
      case 'cardio': return Colors.red;
      default: return AppColors.grey;
    }
  }

  IconData _getExerciseIcon(String grupoMuscular) {
    switch (grupoMuscular.toLowerCase()) {
      case 'pecho': return Icons.sports_gymnastics;
      case 'espalda': return Icons.sports_martial_arts;
      case 'piernas': return Icons.directions_run;
      case 'hombros': return Icons.sports_handball;
      case 'brazos': return Icons.sports_tennis;
      case 'cardio': return Icons.favorite;
      default: return Icons.fitness_center;
    }
  }

  // 🔧 ESTADOS VACÍOS Y DIÁLOGOS

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.pastelBlue),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando rutinas...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRoutines() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: AppColors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No hay rutinas disponibles',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Crea una rutina primero',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.add),
            label: Text('Crear Rutina'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pastelBlue,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 60,
              color: AppColors.white,
            ),
          ),

          SizedBox(height: 30),

          Text(
            '¡Entrenamiento Completado!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16),

          Text(
            _selectedRoutine?.nombre ?? '',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: AppColors.pastelBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionDialog() {
    return AlertDialog(
      backgroundColor: AppColors.cardBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Icon(
            Icons.celebration,
            color: AppColors.pastelGreen,
            size: 50,
          ),
          SizedBox(height: 12),
          Text(
            '¡Felicitaciones!',
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Has completado tu entrenamiento',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Tiempo total', _formatTime(_seconds)),
                SizedBox(height: 8),
                _buildSummaryRow('Ejercicios', '${_routineExercises.length}'),
                SizedBox(height: 8),
                _buildSummaryRow('Sets totales', '${_routineExercises.fold(0, (sum, ex) => sum + ex.series)}'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          child: Text(
            'Finalizar',
            style: TextStyle(color: AppColors.pastelBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.grey,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Salir del entrenamiento',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Text(
          '¿Estás seguro? Se perderá el progreso actual.',
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
    // TODO: Implementar menú con opciones como pausa, configuración, etc.
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }
}

// 📋 ENUM PARA LAS FASES DEL ENTRENAMIENTO
enum WorkoutPhase {
  selectRoutine,
  exerciseReady,
  exerciseActive,
  resting,
  completed,
}