import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/exercise_icons.dart'; // 🔥 NUEVO: Importar utilidades de iconos
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
      print('✅ Ejercicios cargados: ${exercises.length}'); // 🔍 Debug
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error cargando ejercicios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ejercicios: $e'),
          backgroundColor: AppColors.cardBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 12),
              Text(
                'Eliminar Ejercicio',
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de eliminar "${exercise.nombre}"?\n\nEsta acción no se puede deshacer.',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (exercise.id != null) {
                  try {
                    await _dbHelper.deleteExercise(exercise.id!);
                    Navigator.pop(context);
                    _loadExercises();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.white),
                            SizedBox(width: 8),
                            Text('Ejercicio eliminado'),
                          ],
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar ejercicio'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Eliminar', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      );
    }

    // 🔥 NUEVO: Mostrar diálogo para resetear datos (útil para desarrollo)
    void _showResetDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.refresh, color: AppColors.pastelOrange),
              SizedBox(width: 12),
              Text(
                'Resetear Datos',
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Quieres resetear todos los ejercicios y cargar los datos predefinidos?\n\nEsto eliminará todos los ejercicios actuales.',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _dbHelper.resetPredefinedData();
                  Navigator.pop(context);
                  _loadExercises();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.white),
                          SizedBox(width: 8),
                          Text('Datos resetados exitosamente'),
                        ],
                      ),
                      backgroundColor: AppColors.pastelGreen,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al resetear datos: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pastelOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Resetear', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      );
    }
  } Colors.red,
  ),
  );
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
  print('🔍 Filtrado: ${_filteredExercises.length} ejercicios para $_selectedCategory');
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
        Row(
          children: [
            // 🔥 NUEVO: Icono en el título
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.pastelBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fitness_center,
                color: AppColors.pastelBlue,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Column(
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
                  '${_exercises.length} ejercicios disponibles',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
            Spacer(),
            // 🔥 NUEVO: Botón para resetear datos (útil para desarrollo)
            IconButton(
              onPressed: () {
                _showResetDialog();
              },
              icon: Icon(
                Icons.refresh,
                color: AppColors.pastelOrange,
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

        // 🔥 NUEVO: Obtener icono y color para cada categoría
        final icon = category == 'Todos'
            ? Icons.grid_view
            : ExerciseIcons.getIconByMuscleGroup(category);
        final color = category == 'Todos'
            ? AppColors.pastelBlue
            : ExerciseIcons.getColorByMuscleGroup(category);

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
              color: isSelected ? color : AppColors.cardBlack,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? color : AppColors.grey.withOpacity(0.3),
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ] : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? AppColors.white : color,
                ),
                SizedBox(width: 6),
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

  if (_filteredExercises.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedCategory == 'Todos'
                  ? Icons.fitness_center
                  : ExerciseIcons.getIconByMuscleGroup(_selectedCategory),
              size: 64,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 16),
          Text(
            _selectedCategory == 'Todos'
                ? 'No hay ejercicios'
                : 'No hay ejercicios de $_selectedCategory',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Agrega tu primer ejercicio presionando el botón +',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.grey.withOpacity(0.7),
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
        return _buildExerciseCard(exercise, index);
      },
    ),
  );
}

Widget _buildExerciseCard(Exercise exercise, int index) {
  final color = ExerciseIcons.getColorByMuscleGroup(exercise.grupoMuscular);
  final icon = ExerciseIcons.getIconByExerciseName(exercise.nombre);

  return Container(
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColors.cardBlack,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: color.withOpacity(0.2),
        width: 1,
      ),
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
              // 🔥 NUEVO: Número de orden + Icono específico
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                ],
              ),

              SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del ejercicio
                    Text(
                      exercise.nombre,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 4),

                    // Información básica
                    Row(
                      children: [
                        Icon(
                          ExerciseIcons.getStatsIcon('series'),
                          size: 14,
                          color: AppColors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${exercise.series} series',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.grey,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(
                          ExerciseIcons.getStatsIcon('repeticiones'),
                          size: 14,
                          color: AppColors.grey,
                        ),
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

                    // Chips informativos
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ExerciseIcons.buildCategoryBadge(categoria: exercise.grupoMuscular),
                        _buildInfoChip('${exercise.peso}kg', Icons.monitor_weight, AppColors.pastelOrange),
                        _buildInfoChip('${exercise.volumenTotal.toStringAsFixed(0)}kg total', Icons.bar_chart, AppColors.pastelGreen),
                      ],
                    ),
                  ],
                ),
              ),

              // Botones de acción
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        _startExercise(exercise);
                      },
                      icon: Icon(
                        ExerciseIcons.getActionIcon('play'),
                        color: color,
                        size: 28,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        _deleteExercise(exercise);
                      },
                      icon: Icon(
                        ExerciseIcons.getActionIcon('delete'),
                        color: Colors.red,
                        size: 20,
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
          Icon(
            Icons.add_circle,
            color: AppColors.pastelBlue,
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            'Nuevo Ejercicio',
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nombre del ejercicio
            TextField(
              controller: _nombreController,
              style: GoogleFonts.poppins(color: AppColors.white),
              decoration: InputDecoration(
                labelText: 'Nombre del ejercicio',
                labelStyle: GoogleFonts.poppins(color: AppColors.grey),
                prefixIcon: Icon(Icons.fitness_center, color: AppColors.pastelBlue),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.pastelBlue),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Grupo muscular
            DropdownButtonFormField<String>(
              value: _selectedMuscleGroup,
              dropdownColor: AppColors.cardBlack,
              style: GoogleFonts.poppins(color: AppColors.white),
              decoration: InputDecoration(
                labelText: 'Grupo Muscular',
                labelStyle: GoogleFonts.poppins(color: AppColors.grey),
                prefixIcon: Icon(
                  ExerciseIcons.getIconByMuscleGroup(_selectedMuscleGroup),
                  color: ExerciseIcons.getColorByMuscleGroup(_selectedMuscleGroup),
                ),
              ),
              items: ['Pecho', 'Espalda', 'Piernas', 'Hombros', 'Brazos', 'Cardio']
                  .map((grupo) => DropdownMenuItem(
                value: grupo,
                child: Row(
                  children: [
                    Icon(
                      ExerciseIcons.getIconByMuscleGroup(grupo),
                      color: ExerciseIcons.getColorByMuscleGroup(grupo),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(grupo),
                  ],
                ),
              ))
                  .toList(),
              onChanged: (value) {
                _selectedMuscleGroup = value!;
              },
            ),
            SizedBox(height: 16),

            // Series y repeticiones
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
                      prefixIcon: Icon(Icons.repeat, color: AppColors.pastelGreen),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.pastelGreen),
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
                      prefixIcon: Icon(Icons.numbers, color: AppColors.pastelPink),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.pastelPink),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Peso
            TextField(
              controller: _pesoController,
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
            SizedBox(height: 16),

            // Notas
            TextField(
              controller: _notasController,
              style: GoogleFonts.poppins(color: AppColors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notas (opcional)',
                labelStyle: GoogleFonts.poppins(color: AppColors.grey),
                prefixIcon: Icon(Icons.note, color: AppColors.pastelPurple),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.pastelPurple),
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
        ElevatedButton(
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
                        Text('Ejercicio agregado exitosamente'),
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
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Por favor completa todos los campos'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pastelBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Guardar', style: TextStyle(color: AppColors.white)),
        ),
      ],
    ),
  );
}

void _openExerciseDetails(Exercise exercise) {
  final color = ExerciseIcons.getColorByMuscleGroup(exercise.grupoMuscular);
  final icon = ExerciseIcons.getIconByExerciseName(exercise.nombre);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.cardBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              exercise.nombre,
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Grupo Muscular', exercise.grupoMuscular, Icons.fitness_center, color),
          _buildDetailRow('Series', '${exercise.series}', Icons.repeat, AppColors.pastelGreen),
          _buildDetailRow('Repeticiones', '${exercise.repeticiones}', Icons.numbers, AppColors.pastelPink),
          _buildDetailRow('Peso', '${exercise.peso}kg', Icons.monitor_weight, AppColors.pastelOrange),
          _buildDetailRow('Volumen Total', '${exercise.volumenTotal}kg', Icons.bar_chart, AppColors.pastelBlue),
          _buildDetailRow('Duración', exercise.duracionFormateada, Icons.timer, AppColors.pastelPurple),
          if (exercise.notas != null && exercise.notas!.isNotEmpty)
            _buildDetailRow('Notas', exercise.notas!, Icons.note, AppColors.grey),
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

Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

void _startExercise(Exercise exercise) {
  final color = ExerciseIcons.getColorByMuscleGroup(exercise.grupoMuscular);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.play_circle_filled, color: AppColors.white),
          SizedBox(width: 8),
          Text('Iniciando ${exercise.nombre}'),
        ],
      ),
      backgroundColor: color,
    ),
  );
}

}