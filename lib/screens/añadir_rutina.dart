import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../domain/exercise.dart';
import '../domain/rutina.dart';
import '../database/DatabaseHelper.dart';

class CrearRutinaScreen extends StatefulWidget {
  @override
  _CrearRutinaScreenState createState() => _CrearRutinaScreenState();
}

class _CrearRutinaScreenState extends State<CrearRutinaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _duracionController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _selectedCategoria = 'Fuerza';
  List<Exercise> _availableExercises = [];
  List<Exercise> _selectedExercises = [];
  List<Exercise> _filteredExercises = [];
  String _selectedMuscleFilter = 'Todos';
  bool _isLoading = true;

  final List<String> _categorias = ['Fuerza', 'Cardio', 'Funcional', 'Principiante', 'Avanzado'];
  final List<String> _muscleGroups = ['Todos', 'Pecho', 'Espalda', 'Piernas', 'Hombros', 'Brazos'];

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
        _availableExercises = exercises;
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
      if (_selectedMuscleFilter == 'Todos') {
        _filteredExercises = _availableExercises;
      } else {
        _filteredExercises = _availableExercises
            .where((exercise) => exercise.grupoMuscular == _selectedMuscleFilter)
            .toList();
      }
    });
  }

  Future<void> _saveRoutine() async {
    if (_formKey.currentState!.validate() && _selectedExercises.isNotEmpty) {
      final exerciseIds = _selectedExercises.map((e) => e.id!).toList();

      final rutina = Rutina(
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        ejercicioIds: exerciseIds,
        duracionEstimada: int.tryParse(_duracionController.text) ?? 60,
        categoria: _selectedCategoria,
      );

      try {
        await _dbHelper.addRutina(rutina);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rutina creada exitosamente'),
            backgroundColor: AppColors.pastelGreen,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear rutina: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona al menos un ejercicio'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBlack,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Crear Rutina',
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveRoutine,
            child: Text(
              'Guardar',
              style: GoogleFonts.poppins(
                color: AppColors.pastelGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.pastelBlue),
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              SizedBox(height: 30),
              _buildSelectedExercises(),
              SizedBox(height: 30),
              _buildExerciseSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
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
            'Información Básica',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 20),

          TextFormField(
            controller: _nombreController,
            style: GoogleFonts.poppins(color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'Nombre de la rutina',
              labelStyle: GoogleFonts.poppins(color: AppColors.grey),
              hintText: 'Ej: Push Day, Rutina de Piernas',
              hintStyle: GoogleFonts.poppins(color: AppColors.grey.withOpacity(0.7)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.pastelBlue),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa un nombre para la rutina';
              }
              return null;
            },
          ),
          SizedBox(height: 20),

          TextFormField(
            controller: _descripcionController,
            style: GoogleFonts.poppins(color: AppColors.white),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Descripción',
              labelStyle: GoogleFonts.poppins(color: AppColors.grey),
              hintText: 'Describe los objetivos de esta rutina',
              hintStyle: GoogleFonts.poppins(color: AppColors.grey.withOpacity(0.7)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.pastelBlue),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Agrega una descripción';
              }
              return null;
            },
          ),
          SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategoria,
                  dropdownColor: AppColors.cardBlack,
                  style: GoogleFonts.poppins(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    labelStyle: GoogleFonts.poppins(color: AppColors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.grey),
                    ),
                  ),
                  items: _categorias.map((categoria) => DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoria = value!;
                    });
                  },
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: TextFormField(
                  controller: _duracionController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Duración (min)',
                    labelStyle: GoogleFonts.poppins(color: AppColors.grey),
                    hintText: '60',
                    hintStyle: GoogleFonts.poppins(color: AppColors.grey.withOpacity(0.7)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.pastelBlue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Duración requerida';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Debe ser un número';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedExercises() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ejercicios Seleccionados',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.pastelGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedExercises.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.pastelGreen,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          if (_selectedExercises.isEmpty)
            Container(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.playlist_add,
                      size: 48,
                      color: AppColors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No hay ejercicios seleccionados',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.grey,
                      ),
                    ),
                    Text(
                      'Agrega ejercicios desde la lista de abajo',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.grey.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _selectedExercises.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final Exercise item = _selectedExercises.removeAt(oldIndex);
                  _selectedExercises.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final exercise = _selectedExercises[index];
                return _buildSelectedExerciseItem(exercise, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedExerciseItem(Exercise exercise, int index) {
    final color = _getColorByMuscleGroup(exercise.grupoMuscular);

    return Container(
      key: ValueKey(exercise.id),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${index + 1}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.drag_handle, color: AppColors.grey, size: 20),
          ],
        ),
        title: Text(
          exercise.nombre,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
          ),
        ),
        subtitle: Text(
          '${exercise.grupoMuscular} • ${exercise.series}x${exercise.repeticiones} • ${exercise.peso}kg',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.grey,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.remove_circle, color: Colors.red),
          onPressed: () {
            setState(() {
              _selectedExercises.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  Widget _buildExerciseSelector() {
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
            'Agregar Ejercicios',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 16),

          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _muscleGroups.length,
              itemBuilder: (context, index) {
                final group = _muscleGroups[index];
                final isSelected = group == _selectedMuscleFilter;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMuscleFilter = group;
                    });
                    _filterExercises();
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 12),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.pastelBlue : AppColors.surfaceBlack,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? AppColors.pastelBlue : AppColors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      group,
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
          ),

          SizedBox(height: 20),

          Container(
            height: 300,
            child: ListView.builder(
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                final isSelected = _selectedExercises.any((e) => e.id == exercise.id);

                return _buildExerciseSelectItem(exercise, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSelectItem(Exercise exercise, bool isSelected) {
    final color = _getColorByMuscleGroup(exercise.grupoMuscular);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceBlack,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: color, width: 2) : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.fitness_center,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          exercise.nombre,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
          ),
        ),
        subtitle: Text(
          '${exercise.grupoMuscular} • ${exercise.series}x${exercise.repeticiones} • ${exercise.peso}kg',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.grey,
          ),
        ),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.add_circle_outline,
          color: isSelected ? color : AppColors.grey,
        ),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedExercises.removeWhere((e) => e.id == exercise.id);
            } else {
              _selectedExercises.add(exercise);
            }
          });
        },
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
      default: return AppColors.grey;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _duracionController.dispose();
    super.dispose();
  }
}