import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../domain/exercise.dart';
import '../database/DatabaseHelper.dart';

class ExercisesTab extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _dbHelper.getAllExercises();
      setState(() {
        _exercises = exercises;
        _filteredExercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error cargando ejercicios: $e');
    }
  }

  void _filterExercises() {
    setState(() {
      if (_selectedCategory == 'Todos') {
        _filteredExercises = _exercises;
      } else {
        _filteredExercises = _exercises.where((exercise) =>
        exercise.grupoMuscular == _selectedCategory).toList();
      }
    });
  }

  void _searchExercises(String query) {
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddExerciseDialog();
        },
        backgroundColor: AppColors.pastelPink,
        child: Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
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
                prefixIcon: Icon(Icons.search, color: AppColors.pastelBlue),
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
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              _filterExercises();
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.pastelBlue : AppColors.cardBlack,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? AppColors.pastelBlue : AppColors.grey.withOpacity(0.3),
                ),
              ),
              child: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.white : AppColors.grey,
                ),
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
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.pastelBlue),
        ),
      );
    }

    if (_filteredExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: AppColors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay ejercicios',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: AppColors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Agrega tu primer ejercicio',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.grey,
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
                  ),
                  child: Icon(
                    _getIconByMuscleGroup(exercise.grupoMuscular),
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
                      Text(
                        '${exercise.series} series × ${exercise.repeticiones} reps',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChip(exercise.grupoMuscular, color),
                          SizedBox(width: 8),
                          _buildChip('${exercise.peso}kg', AppColors.pastelOrange),
                          SizedBox(width: 8),
                          _buildChip('${exercise.volumenTotal.toStringAsFixed(0)}kg total', AppColors.pastelGreen),
                        ],
                      ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        _startExercise(exercise);
                      },
                      icon: Icon(
                        Icons.play_circle_filled,
                        color: color,
                        size: 32,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _deleteExercise(exercise);
                      },
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 24,
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

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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

  IconData _getIconByMuscleGroup(String grupo) {
    switch (grupo) {
      case 'Pecho': return Icons.fitness_center;
      case 'Espalda': return Icons.fitness_center;
      case 'Piernas': return Icons.accessibility_new;
      case 'Hombros': return Icons.fitness_center;
      case 'Brazos': return Icons.fitness_center;
      case 'Cardio': return Icons.directions_run;
      default: return Icons.fitness_center;
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
        title: Text(
          'Nuevo Ejercicio',
          style: GoogleFonts.poppins(color: AppColors.white),
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
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
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
                ),
                items: ['Pecho', 'Espalda', 'Piernas', 'Hombros', 'Brazos', 'Cardio']
                    .map((grupo) => DropdownMenuItem(
                  value: grupo,
                  child: Text(grupo),
                ))
                    .toList(),
                onChanged: (value) {
                  _selectedMuscleGroup = value!;
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
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
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
                      content: Text('Ejercicio agregado'),
                      backgroundColor: AppColors.pastelGreen,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al agregar ejercicio'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Guardar', style: TextStyle(color: AppColors.pastelBlue)),
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
        title: Text(
          exercise.nombre,
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grupo: ${exercise.grupoMuscular}', style: GoogleFonts.poppins(color: AppColors.grey)),
            Text('Series: ${exercise.series}', style: GoogleFonts.poppins(color: AppColors.grey)),
            Text('Repeticiones: ${exercise.repeticiones}', style: GoogleFonts.poppins(color: AppColors.grey)),
            Text('Peso: ${exercise.peso}kg', style: GoogleFonts.poppins(color: AppColors.grey)),
            Text('Volumen total: ${exercise.volumenTotal}kg', style: GoogleFonts.poppins(color: AppColors.grey)),
            Text('Duración: ${exercise.duracionFormateada}', style: GoogleFonts.poppins(color: AppColors.grey)),
            if (exercise.notas != null && exercise.notas!.isNotEmpty)
              Text('Notas: ${exercise.notas}', style: GoogleFonts.poppins(color: AppColors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: AppColors.pastelBlue)),
          ),
        ],
      ),
    );
  }

  void _startExercise(Exercise exercise) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando ${exercise.nombre}'),
        backgroundColor: _getColorByMuscleGroup(exercise.grupoMuscular),
      ),
    );
  }

  void _deleteExercise(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Eliminar Ejercicio',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Text(
          '¿Estás seguro de eliminar ${exercise.nombre}?',
          style: GoogleFonts.poppins(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (exercise.id != null) {
                await _dbHelper.deleteExercise(exercise.id!);
                Navigator.pop(context);
                _loadExercises();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ejercicio eliminado'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}