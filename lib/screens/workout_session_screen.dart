import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../utils/app_colors.dart';
import '../domain/exercise.dart';
import '../domain/rutina.dart';
import '../domain/user.dart';
import '../domain/training.dart';
import '../domain/performed_exercise.dart';
import '../domain/user_record.dart';
import '../database/database_helper.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final User? user;

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
  DateTime? _workoutStartTime; // Para calcular tiempo total del entrenamiento

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

  // 📊 ALMACENAMIENTO DE RESULTADOS
  List<Performed_exercise> _performedExercises = [];
  Map<String, List<Map<String, dynamic>>> _exerciseResults = {}; // Almacena todos los sets de cada ejercicio

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadRoutines();
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
  }

  // MÉTODOS DE CARGA DE RUTINAS
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
        _workoutStartTime = DateTime.now(); // Iniciar cronómetro del entrenamiento

        // Inicializar almacenamiento de resultados
        _performedExercises = [];
        _exerciseResults = {};
        for (var exercise in exercises) {
          _exerciseResults[exercise.id.toString()] = [];
        }
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

  void _finishSet() async {
    _timer?.cancel();
    _pulseController.stop();
    _waveController.stop();

    // 📊 GUARDAR RESULTADOS DEL SET
    await _saveSetResults();

    setState(() {
      _isRunning = false;
      _currentPhase = WorkoutPhase.resting;
      _isResting = true;
      _restSeconds = 180;
    });

    _startRestTimer();
  }

  // 📊 MÉTODO PARA GUARDAR RESULTADOS DE CADA SET
  Future<void> _saveSetResults() async {
    if (_currentExercise == null) return;

    final setResult = {
      'set': _currentSet,
      'weight': double.tryParse(_weightController.text) ?? 0.0,
      'reps': int.tryParse(_repsController.text) ?? 0,
      'time': _seconds.toDouble(),
      'date': DateTime.now(),
    };

    // Añadir el set a los resultados del ejercicio actual
    _exerciseResults[_currentExercise!.id.toString()]?.add(setResult);

    print('Set guardado: Ejercicio ${_currentExercise!.nombre}, Set $_currentSet, Peso: ${setResult['weight']}, Reps: ${setResult['reps']}, Tiempo: ${setResult['time']}s');
  }

  // 💾 MÉTODO PARA GUARDAR EL ENTRENAMIENTO COMPLETO
  Future<void> _saveWorkout() async {
    try {
      // Validaciones más específicas
      if (_selectedRoutine == null) {
        _showError('Error: No se ha seleccionado ninguna rutina');
        print('DEBUG: _selectedRoutine is null');
        return;
      }

      if (widget.user == null) {
        _showError('Error: Usuario no identificado');
        print('DEBUG: widget.user is null');
        return;
      }

      if (_routineExercises.isEmpty) {
        _showError('Error: No hay ejercicios en la rutina');
        print('DEBUG: _routineExercises is empty');
        return;
      }

      if (_exerciseResults.isEmpty) {
        _showError('Error: No se han registrado ejercicios realizados');
        print('DEBUG: _exerciseResults is empty');
        return;
      }

      print('DEBUG: Iniciando guardado del entrenamiento...');
      print('DEBUG: Rutina seleccionada: ${_selectedRoutine!.nombre}');
      print('DEBUG: Usuario: ${widget.user!.name ?? 'Sin nombre'}');
      print('DEBUG: Ejercicios realizados: ${_exerciseResults.length}');

      // Crear lista de ejercicios realizados
      List<Performed_exercise> performedExercises = [];

      for (var exercise in _routineExercises) {
        final exerciseId = exercise.id.toString();
        final sets = _exerciseResults[exerciseId] ?? [];

        print('DEBUG: Procesando ejercicio ${exercise.nombre} con ${sets.length} sets');

        if (sets.isNotEmpty) {
          // Calcular totales para este ejercicio
          final totalSets = sets.length;
          final totalTime = sets.fold<double>(0.0, (sum, set) => sum + (set['time'] as double));
          final avgWeight = sets.fold<double>(0.0, (sum, set) => sum + (set['weight'] as double)) / totalSets;
          final totalReps = sets.fold<int>(0, (sum, set) => sum + (set['reps'] as int));

          final performedExercise = Performed_exercise(
            id: '${exercise.id}_${DateTime.now().millisecondsSinceEpoch}',
            exerciseId: exercise.id,
            time: totalTime,
            series: totalSets,
            reps: totalReps,
            weight: avgWeight,
            date: DateTime.now(),
          );

          performedExercises.add(performedExercise);
          print('DEBUG: Ejercicio añadido - Sets: $totalSets, Tiempo: $totalTime, Peso promedio: $avgWeight');
        }
      }

      if (performedExercises.isEmpty) {
        _showError('Error: No se han completado ejercicios para guardar');
        print('DEBUG: performedExercises is empty after processing');
        return;
      }

      // Calcular tiempo total del entrenamiento
      final totalWorkoutTime = _workoutStartTime != null
          ? DateTime.now().difference(_workoutStartTime!).inSeconds.toDouble()
          : 0.0;

      print('DEBUG: Tiempo total del entrenamiento: $totalWorkoutTime segundos');

      // Crear el objeto Training
      final training = Training(
        rutinaId: _selectedRoutine!.id,
        performedExercises: performedExercises,
        date: DateTime.now(),
        totalTime: totalWorkoutTime,
      );

      print('DEBUG: Objeto Training creado, guardando en base de datos...');

      // Guardar el entrenamiento en la base de datos
      await _dbHelper.insertTraining(training);

      print('DEBUG: Training guardado exitosamente');

      // Actualizar el registro del usuario
      await _updateUserRecord(training);

      print('DEBUG: Registro de usuario actualizado');

      _showInfo('¡Entrenamiento guardado exitosamente!');

    } catch (e, stackTrace) {
      _showError('Error guardando entrenamiento: $e');
      print('ERROR DETALLADO: $e');
      print('STACK TRACE: $stackTrace');
    }
  }

  // 📈 MÉTODO PARA ACTUALIZAR EL REGISTRO DEL USUARIO
  Future<void> _updateUserRecord(Training training) async {
    try {
      if (widget.user == null) {
        print('DEBUG: No se puede actualizar registro - usuario null');
        return;
      }

      if (widget.user!.id == null) {
        print('DEBUG: No se puede actualizar registro - user.id null');
        return;
      }

      print('DEBUG: Actualizando registro para usuario ID: ${widget.user!.id}');

      // Obtener el registro actual del usuario
      User_record? currentRecord = await _dbHelper.getUserRecord(widget.user!.id!);

      print('DEBUG: Registro actual obtenido: ${currentRecord != null ? 'existe' : 'no existe'}');

      // Si no existe registro, crear uno nuevo
      currentRecord ??= User_record(
        record: [],
        recordDates: [],
        totalTrainingDays: 0,
        consecutiveTrainingDays: 0,
      );

      // Actualizar el registro
      final updatedRecord = currentRecord.copyWith(
        record: [...currentRecord.record, training.rutinaId ?? 0],
        recordDates: [...currentRecord.recordDates, training.date],
        totalTrainingDays: currentRecord.totalTrainingDays + 1,
        consecutiveTrainingDays: _calculateConsecutiveDays(
            [...currentRecord.recordDates, training.date]
        ),
      );

      print('DEBUG: Registro actualizado - Días totales: ${updatedRecord.totalTrainingDays}');

      // Guardar el registro actualizado
      await _dbHelper.updateUserRecord(widget.user!.id!, updatedRecord);

      print('DEBUG: Registro de usuario guardado exitosamente');

    } catch (e, stackTrace) {
      print('ERROR actualizando registro del usuario: $e');
      print('STACK TRACE: $stackTrace');
      // No mostramos error al usuario para no interrumpir el flujo principal
    }
  }

  // 📅 MÉTODO PARA CALCULAR DÍAS CONSECUTIVOS
  int _calculateConsecutiveDays(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    // Ordenar fechas y obtener solo los días (sin horas)
    final sortedDates = dates
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet()
        .toList()
      ..sort();

    int consecutive = 1;
    int maxConsecutive = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        consecutive++;
        maxConsecutive = consecutive > maxConsecutive ? consecutive : maxConsecutive;
      } else {
        consecutive = 1;
      }
    }

    return maxConsecutive;
  }

  void _startRestTimer() {
    _restTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _restSeconds--;
        if (_restSeconds <= 0) {
          timer.cancel();
          _isResting = false;
        }
      });
    });
  }

  // MÉTODOS DE UI EXISTENTES
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
                'Cargando...',
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
        return _buildExerciseActive();
      case WorkoutPhase.resting:
        return _buildRestingState();
      case WorkoutPhase.completed:
        return _buildWorkoutCompleted();
    }
  }

  Widget _buildExerciseActive() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWorkoutHeader(),
          SizedBox(height: 20),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildMainTimer(),
                SizedBox(height: 20),
                _buildCurrentSetInfo(),
              ],
            ),
          ),
          SizedBox(height: 20),
          _buildFinishSetButton(),
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
          _buildRestTimer(),
          SizedBox(height: 20),
          _buildNextSetInfo(),
          Spacer(),
          _buildRestActions(),
        ],
      ),
    );
  }

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
          ],
        ),
      ],
    );
  }

  Widget _buildRoutineSelection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.list_alt_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Iniciar Sesión',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    'Selecciona una rutina para empezar',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 30),
          Expanded(
            child: _availableRoutines.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 80, color: AppColors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay rutinas disponibles',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Crea una rutina primero',
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _availableRoutines.length,
              itemBuilder: (context, index) {
                final routine = _availableRoutines[index];
                final color = AppColors.pastelBlue;
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  color: AppColors.cardBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: color.withOpacity(0.2), width: 1),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _selectRoutine(routine),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withOpacity(0.1),
                            radius: 25,
                            child: Icon(
                              Icons.fitness_center_rounded,
                              color: color,
                              size: 24,
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
                                  '${routine.ejercicioIds.length} ejercicios • ${routine.duracionEstimada} min',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.grey),
                        ],
                      ),
                    ),
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
    final color = _currentExercise != null ? _getColorByMuscleGroup(_currentExercise!.grupoMuscular) : AppColors.pastelBlue;

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildWorkoutHeader(),
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'Prepárate',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ajusta el peso y las repeticiones para este set.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSetInput(
                        controller: _weightController,
                        label: 'Peso (kg)',
                        icon: Icons.fitness_center_rounded,
                        color: AppColors.pastelGreen,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSetInput(
                        controller: _repsController,
                        label: 'Reps',
                        icon: Icons.repeat_rounded,
                        color: AppColors.pastelOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startSet,
              icon: Icon(Icons.play_arrow_rounded, color: AppColors.white),
              label: Text(
                'Iniciar Set',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCompleted() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 100,
            color: AppColors.pastelGreen,
          ),
          SizedBox(height: 20),
          Text(
            '¡Entrenamiento Completado!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              await _saveWorkout(); // Guardar antes de salir
              Navigator.pop(context);
            },
            child: Text(
              'Finalizar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pastelBlue,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTimer() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Tiempo',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ],
      ),
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
            'Set Actual',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    _weightController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    'kg',
                    style: GoogleFonts.poppins(color: AppColors.grey),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    _repsController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    'reps',
                    style: GoogleFonts.poppins(color: AppColors.grey),
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
    return ElevatedButton(
      onPressed: _finishSet,
      child: Text(
        'Terminar Set',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.pastelOrange,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
    );
  }

  Widget _buildRestTimer() {
    return Container(
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Descanso',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '${(_restSeconds ~/ 60).toString().padLeft(2, '0')}:${(_restSeconds % 60).toString().padLeft(2, '0')}',
            style: GoogleFonts.poppins(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: AppColors.pastelBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextSetInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Próximo Set',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Set ${_currentSet + 1} de ${_currentExercise?.series ?? 0}',
            style: GoogleFonts.poppins(color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRestActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _restTimer?.cancel();
              setState(() {
                _isResting = false;
                _currentSet++;
                if (_currentSet <= (_currentExercise?.series ?? 0)) {
                  _currentPhase = WorkoutPhase.exerciseReady;
                } else {
                  _currentExerciseIndex++;
                  if (_currentExerciseIndex < _routineExercises.length) {
                    _currentSet = 1;
                    _currentPhase = WorkoutPhase.exerciseReady;
                    _prepareExercise();
                  } else {
                    _currentPhase = WorkoutPhase.completed;
                  }
                }
              });
            },
            child: Text(
              'Continuar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pastelGreen,
              padding: EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              _restTimer?.cancel();
              await _saveWorkout(); // Guardar progreso antes de terminar
              setState(() {
                _currentPhase = WorkoutPhase.completed;
              });
            },
            child: Text(
              'Terminar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pastelOrange,
              padding: EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
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

  Color _getColorByMuscleGroup(String grupo) {
    switch (grupo) {
      case 'Pecho': return AppColors.pastelPink;
      case 'Espalda': return AppColors.pastelGreen;
      case 'Piernas': return AppColors.pastelBlue;
      case 'Hombros': return AppColors.pastelPurple;
      case 'Brazos': return AppColors.pastelOrange;
      default: return AppColors.grey;
    }
  }

  Widget _buildSetInput({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required Color color,
}) {
  return TextField(
    controller: controller,
    textAlign: TextAlign.center,
    keyboardType: TextInputType.number,
    style: GoogleFonts.poppins(
      color: AppColors.white,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color: color,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: color),
      filled: true,
      fillColor: AppColors.surfaceBlack,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
    ),
  );
}
// Agregar estos métodos a tu clase _WorkoutSessionScreenState

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.pastelGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

// Método adicional para mostrar diálogos más elaborados (opcional)
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendido',
                style: GoogleFonts.poppins(
                  color: AppColors.pastelBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.pastelGreen,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Genial',
                style: GoogleFonts.poppins(
                  color: AppColors.pastelGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
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