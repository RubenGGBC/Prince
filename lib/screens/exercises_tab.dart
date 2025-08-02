import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../domain/exercise.dart';
import '../database/database_helper.dart';
import '../domain/user.dart';

class ExercisesTab extends StatefulWidget {

  final User user;

  const ExercisesTab({Key? key, required this.user}) : super(key: key);

  @override
  _ExercisesTabState createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _selectedCategory = 'Todos';
  final List<String> _categories = ['Todos', 'Pecho', 'Espalda', 'Piernas', 'Hombros', 'Brazos', 'Cardio'];
  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  bool _isLoading = true;
  String _errorMessage = ''; // 🔍 Para mostrar errores al usuario

  @override
  void initState() {
    super.initState();
    print('🚀 Iniciando ExercisesTab'); // 🔍 Debug
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    print('📖 Iniciando carga de ejercicios...'); // 🔍 Debug
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 🔍 Debug: Verificar conexión a BD
      final counts = await _dbHelper.getTableCounts();
      print('📊 Conteo de tablas: $counts'); // 🔍 Debug

      final exercises = await _dbHelper.getAllExercises();
      print('✅ Ejercicios cargados: ${exercises.length}'); // 🔍 Debug

      // 🔍 Debug: Mostrar algunos ejercicios
      if (exercises.isNotEmpty) {
        for (int i = 0; i < (exercises.length > 5 ? 5 : exercises.length); i++) {
          print('📋 Ejercicio $i: ${exercises[i].nombre} (${exercises[i].grupoMuscular})');
        }
      } else {
        print('⚠️ No se encontraron ejercicios en la base de datos'); // 🔍 Debug
      }

      setState(() {
        _exercises = exercises;
        _filteredExercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando ejercicios: $e'); // 🔍 Debug
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error cargando ejercicios: $e';
      });
    }
  }

  void _filterExercises() {
    print('🔍 Filtrando ejercicios por: $_selectedCategory'); // 🔍 Debug
    setState(() {
      if (_selectedCategory == 'Todos') {
        _filteredExercises = _exercises;
      } else {
        _filteredExercises = _exercises.where((exercise) =>
        exercise.grupoMuscular == _selectedCategory).toList();
      }
    });
    print('📊 Ejercicios filtrados: ${_filteredExercises.length}'); // 🔍 Debug
  }

  void _searchExercises(String query) {
    print('🔍 Buscando ejercicios con: "$query"'); // 🔍 Debug
    setState(() {
      if (query.isEmpty) {
        _filterExercises();
      } else {
        _filteredExercises = _exercises.where((exercise) =>
        exercise.nombre.toLowerCase().contains(query.toLowerCase()) ||
            exercise.grupoMuscular.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
    print('📊 Ejercicios encontrados: ${_filteredExercises.length}'); // 🔍 Debug
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategories(),
            Expanded(child: _buildExercisesList()),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 🔍 Debug: Botón de debug
          FloatingActionButton(
            heroTag: "debug",
            onPressed: _showDebugInfo,
            backgroundColor: AppColors.pastelPurple,
            child: Icon(Icons.bug_report, color: AppColors.white),
            mini: true,
          ),
          SizedBox(width: 10),
          FloatingActionButton.extended(
            heroTag: "add",
            onPressed: () {
              _showAddExerciseDialog();
            },
            backgroundColor: AppColors.pastelPink,
            icon: Icon(Icons.add_circle, color: AppColors.white),
            label: Text(
              'Ejercicio',
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
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
                  Icons.fitness_center,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ejercicios',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      '${_filteredExercises.length} ejercicios disponibles',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _showExerciseStats();
                },
                icon: Icon(
                  Icons.analytics_outlined,
                  color: AppColors.pastelBlue,
                  size: 24,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pastelBlue.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: TextField(
              style: GoogleFonts.poppins(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Buscar ejercicios...',
                hintStyle: GoogleFonts.poppins(color: AppColors.grey),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.pastelBlue),
                suffixIcon: IconButton(
                  icon: Icon(Icons.filter_list, color: AppColors.grey),
                  onPressed: () {
                    _showFilterDialog();
                  },
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onChanged: _searchExercises,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          final categoryIcon = _getCategoryIcon(category);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              _filterExercises();
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.pastelBlue : AppColors.cardBlack,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? AppColors.pastelBlue : AppColors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    categoryIcon,
                    color: isSelected ? AppColors.white : AppColors.grey,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.white : AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExercisesList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.pastelBlue),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando ejercicios...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadExercises,
              icon: Icon(Icons.refresh),
              label: Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pastelBlue,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: AppColors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay ejercicios',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _selectedCategory == 'Todos'
                  ? 'Agrega tu primer ejercicio'
                  : 'No hay ejercicios en "$_selectedCategory"',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.grey,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddExerciseDialog(),
              icon: Icon(Icons.add_circle_outline),
              label: Text('Agregar Ejercicio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pastelBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExercises,
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: _filteredExercises.length,
        itemBuilder: (context, index) {
          final exercise = _filteredExercises[index];
          return _buildExerciseCard(exercise);
        },
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final color = _getColorByMuscleGroup(exercise.grupoMuscular);
    final muscleIcon = _getIconByMuscleGroup(exercise.grupoMuscular);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _openExerciseDetails(exercise);
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    muscleIcon,
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
                        exercise.nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.repeat, color: AppColors.grey, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${exercise.series} series',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.grey,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.fitness_center, color: AppColors.grey, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${exercise.repeticiones} reps',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChip(exercise.grupoMuscular, color, Icons.label),
                          SizedBox(width: 8),
                          _buildChip('${exercise.peso}kg', AppColors.pastelOrange, Icons.monitor_weight),
                          SizedBox(width: 8),
                          _buildChip('${exercise.volumenTotal.toStringAsFixed(0)}kg total', AppColors.pastelGreen, Icons.trending_up),
                        ],
                      ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          _startExercise(exercise);
                        },
                        icon: Icon(
                          Icons.play_circle_filled_rounded,
                          color: color,
                          size: 32,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          _deleteExercise(exercise);
                        },
                        icon: Icon(
                          Icons.delete_rounded,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
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

  // 🔍 Debug: Mostrar información del estado
  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          '🔍 Debug Info - Exercises',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📊 Estado:', style: GoogleFonts.poppins(color: AppColors.pastelBlue, fontWeight: FontWeight.bold)),
              Text('• Loading: $_isLoading', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12)),
              Text('• Error: ${_errorMessage.isEmpty ? "Ninguno" : _errorMessage}', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12)),

              SizedBox(height: 12),
              Text('📋 Ejercicios:', style: GoogleFonts.poppins(color: AppColors.pastelGreen, fontWeight: FontWeight.bold)),
              Text('• Total: ${_exercises.length}', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12)),
              Text('• Filtrados: ${_filteredExercises.length}', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12)),
              Text('• Categoría: $_selectedCategory', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12)),

              if (_exercises.isNotEmpty) ...[
                SizedBox(height: 12),
                Text('📝 Primeros ejercicios:', style: GoogleFonts.poppins(color: AppColors.pastelOrange, fontWeight: FontWeight.bold)),
                ...(_exercises.take(3).map((e) =>
                    Text('• ${e.nombre} (${e.grupoMuscular})', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12))
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _dbHelper.resetDatabase();
              _loadExercises();
            },
            icon: Icon(Icons.refresh, color: Colors.orange),
            label: Text('Reset BD', style: TextStyle(color: Colors.orange)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppColors.pastelBlue),
            label: Text('Cerrar', style: TextStyle(color: AppColors.pastelBlue)),
          ),
        ],
      ),
    );
  }

  // FUNCIONES PARA ICONOS

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Todos': return Icons.grid_view_rounded;
      case 'Pecho': return Icons.sports_gymnastics;
      case 'Espalda': return Icons.sports_martial_arts;
      case 'Piernas': return Icons.directions_run;
      case 'Hombros': return Icons.sports_handball;
      case 'Brazos': return Icons.sports_tennis;
      case 'Cardio': return Icons.favorite;
      default: return Icons.fitness_center;
    }
  }

  IconData _getIconByMuscleGroup(String grupo) {
    switch (grupo) {
      case 'Pecho': return Icons.sports_gymnastics;
      case 'Espalda': return Icons.sports_martial_arts;
      case 'Piernas': return Icons.directions_run;
      case 'Hombros': return Icons.sports_handball;
      case 'Brazos': return Icons.sports_tennis;
      case 'Cardio': return Icons.favorite;
      default: return Icons.fitness_center;
    }
  }

  Color _getColorByMuscleGroup(String grupo) {
    switch (grupo) {
      case 'Pecho': return AppColors.pastelPink;
      case 'Espalda': return AppColors.pastelGreen;
      case 'Piernas': return AppColors.pastelBlue;
      case 'Hombros': return AppColors.pastelPurple;
      case 'Brazos': return AppColors.pastelOrange;
      case 'Cardio': return Colors.red;
      default: return AppColors.grey;
    }
  }

  void _showAddExerciseDialog() {
    final _nombreController = TextEditingController();
    final _seriesController = TextEditingController();
    final _repsController = TextEditingController();
    final _pesoController = TextEditingController();
    final _notasController = TextEditingController();
    String _selectedMuscleGroup = 'Pecho';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: AppColors.pastelPink),
            SizedBox(width: 12),
            Text(
              'Nuevo Ejercicio',
              style: GoogleFonts.poppins(color: AppColors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                style: GoogleFonts.poppins(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: GoogleFonts.poppins(color: AppColors.grey),
                  prefixIcon: Icon(Icons.title, color: AppColors.pastelBlue),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.pastelBlue),
                  ),
                ),
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedMuscleGroup,
                dropdownColor: AppColors.cardBlack,
                style: GoogleFonts.poppins(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Grupo Muscular',
                  labelStyle: GoogleFonts.poppins(color: AppColors.grey),
                  prefixIcon: Icon(_getIconByMuscleGroup(_selectedMuscleGroup), color: AppColors.pastelGreen),
                ),
                items: ['Pecho', 'Espalda', 'Piernas', 'Hombros', 'Brazos', 'Cardio']
                    .map((grupo) => DropdownMenuItem(
                  value: grupo,
                  child: Row(
                    children: [
                      Icon(_getIconByMuscleGroup(grupo), color: _getColorByMuscleGroup(grupo)),
                      SizedBox(width: 8),
                      Text(grupo),
                    ],
                  ),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMuscleGroup = value!;
                  });
                },
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _seriesController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(color: AppColors.white),
                      decoration: InputDecoration(
                        labelText: 'Series',
                        labelStyle: GoogleFonts.poppins(color: AppColors.grey),
                        prefixIcon: Icon(Icons.repeat, color: AppColors.pastelOrange),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.grey),
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
                        prefixIcon: Icon(Icons.fitness_center, color: AppColors.pastelPurple),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              TextField(
                controller: _pesoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  labelStyle: GoogleFonts.poppins(color: AppColors.grey),
                  prefixIcon: Icon(Icons.monitor_weight, color: AppColors.pastelGreen),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: _notasController,
                style: GoogleFonts.poppins(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Notas (opcional)',
                  labelStyle: GoogleFonts.poppins(color: AppColors.grey),
                  prefixIcon: Icon(Icons.note_add, color: AppColors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppColors.grey),
            label: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton.icon(
            onPressed: () async {
              if (_nombreController.text.isNotEmpty &&
                  _seriesController.text.isNotEmpty &&
                  _repsController.text.isNotEmpty &&
                  _pesoController.text.isNotEmpty) {

                final now = DateTime.now();
                final exercise = Exercise(
                  grupoMuscular: _selectedMuscleGroup,
                  nombre: _nombreController.text,
                  horaInicio: now.subtract(Duration(minutes: 30)),
                  horaFin: now,
                  repeticiones: int.parse(_repsController.text),
                  series: int.parse(_seriesController.text),
                  peso: double.parse(_pesoController.text),
                  notas: _notasController.text.isNotEmpty ? _notasController.text : null,
                );

                try {
                  await _dbHelper.addExercise(exercise);
                  Navigator.pop(context);
                  _loadExercises();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.white),
                          SizedBox(width: 8),
                          Text('Ejercicio agregado'),
                        ],
                      ),
                      backgroundColor: AppColors.pastelGreen,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: AppColors.white),
                          SizedBox(width: 8),
                          Text('Error al agregar ejercicio'),
                        ],
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: Icon(Icons.save, color: AppColors.pastelBlue),
            label: Text('Guardar', style: TextStyle(color: AppColors.pastelBlue)),
          ),
        ],
      ),
    );
  }

  void _openExerciseDetails(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_getIconByMuscleGroup(exercise.grupoMuscular),
                color: _getColorByMuscleGroup(exercise.grupoMuscular)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                exercise.nombre,
                style: GoogleFonts.poppins(color: AppColors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(Icons.label, 'Grupo', exercise.grupoMuscular),
            _buildDetailRow(Icons.repeat, 'Series', '${exercise.series}'),
            _buildDetailRow(Icons.fitness_center, 'Repeticiones', '${exercise.repeticiones}'),
            _buildDetailRow(Icons.monitor_weight, 'Peso', '${exercise.peso}kg'),
            _buildDetailRow(Icons.trending_up, 'Volumen total', '${exercise.volumenTotal}kg'),
            _buildDetailRow(Icons.timer, 'Duración', exercise.duracionFormateada),
            if (exercise.notas != null && exercise.notas!.isNotEmpty)
              _buildDetailRow(Icons.note, 'Notas', exercise.notas!),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppColors.pastelBlue),
            label: Text('Cerrar', style: TextStyle(color: AppColors.pastelBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grey, size: 16),
          SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 14)),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(color: AppColors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _startExercise(Exercise exercise) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.play_circle_filled, color: AppColors.white),
            SizedBox(width: 8),
            Text('Iniciando ${exercise.nombre}'),
          ],
        ),
        backgroundColor: _getColorByMuscleGroup(exercise.grupoMuscular),
      ),
    );
  }

  void _deleteExercise(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text(
              'Eliminar Ejercicio',
              style: GoogleFonts.poppins(color: AppColors.white),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar ${exercise.nombre}?',
          style: GoogleFonts.poppins(color: AppColors.grey),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppColors.grey),
            label: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton.icon(
            onPressed: () async {
              if (exercise.id != null) {
                await _dbHelper.deleteExercise(exercise.id!);
                Navigator.pop(context);
                _loadExercises();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.white),
                        SizedBox(width: 8),
                        Text('Ejercicio eliminado'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: Icon(Icons.delete_forever, color: Colors.red),
            label: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showExerciseStats() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.analytics, color: AppColors.white),
            SizedBox(width: 8),
            Text('Estadísticas próximamente'),
          ],
        ),
        backgroundColor: AppColors.pastelBlue,
      ),
    );
  }

  void _showFilterDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.filter_list, color: AppColors.white),
            SizedBox(width: 8),
            Text('Filtros avanzados próximamente'),
          ],
        ),
        backgroundColor: AppColors.pastelPurple,
      ),
    );
  }
}