import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../domain/exercise.dart';
import '../domain/rutina.dart';
import '../database/database_helper.dart';

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
  String _errorMessage = ''; // 🔍 Para mostrar errores al usuario

  final List<String> _categorias = ['Fuerza', 'Cardio', 'Funcional', 'Principiante', 'Avanzado'];
  final List<String> _muscleGroups = ['Todos', 'Pecho', 'Espalda', 'Piernas', 'Hombros', 'Brazos', 'Cardio'];

  @override
  void initState() {
    super.initState();
    print('🚀 Iniciando CrearRutinaScreen'); // 🔍 Debug
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
        _availableExercises = exercises;
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
    print('🔍 Filtrando ejercicios por: $_selectedMuscleFilter'); // 🔍 Debug
    setState(() {
      if (_selectedMuscleFilter == 'Todos') {
        _filteredExercises = _availableExercises;
      } else {
        _filteredExercises = _availableExercises
            .where((exercise) => exercise.grupoMuscular == _selectedMuscleFilter)
            .toList();
      }
    });
    print('📊 Ejercicios filtrados: ${_filteredExercises.length}'); // 🔍 Debug
  }

  Future<void> _saveRoutine() async {
    print('💾 Intentando guardar rutina...'); // 🔍 Debug

    if (_formKey.currentState!.validate() && _selectedExercises.isNotEmpty) {
      final exerciseIds = _selectedExercises.map((e) => e.id!).toList();
      print('📝 IDs de ejercicios seleccionados: $exerciseIds'); // 🔍 Debug

      final rutina = Rutina(
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        ejercicioIds: exerciseIds,
        duracionEstimada: int.tryParse(_duracionController.text) ?? 60,
        categoria: _selectedCategoria,
      );

      try {
        await _dbHelper.addRutina(rutina);
        print('✅ Rutina guardada exitosamente'); // 🔍 Debug

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.white),
                SizedBox(width: 8),
                Text('Rutina creada exitosamente'),
              ],
            ),
            backgroundColor: AppColors.pastelGreen,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        print('❌ Error guardando rutina: $e'); // 🔍 Debug
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppColors.white),
                SizedBox(width: 8),
                Text('Error al crear rutina: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (_selectedExercises.isEmpty) {
      print('⚠️ No hay ejercicios seleccionados'); // 🔍 Debug
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: AppColors.white),
              SizedBox(width: 8),
              Text('Selecciona al menos un ejercicio'),
            ],
          ),
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
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.fitnessGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.createBlueShadow(AppColors.fitnessRed),
              ),
              child: Icon(
                Icons.playlist_add_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Crear Rutina',
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _saveRoutine,
              icon: Icon(Icons.save_rounded, color: AppColors.nutritionGreen, size: 18),
              label: Text(
                'Guardar',
                style: GoogleFonts.poppins(
                  color: AppColors.nutritionGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      // 🔍 Debug: Botón flotante para testing
      floatingActionButton: FloatingActionButton(
        onPressed: _showDebugInfo,
        backgroundColor: AppColors.pastelPurple,
        child: Icon(Icons.bug_report, color: AppColors.white),
      ),
    );
  }

  Widget _buildBody() {
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

    if (_availableExercises.isEmpty) {
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
              'No hay ejercicios disponibles',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Primero agrega algunos ejercicios',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.grey,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/exercises');
              },
              icon: Icon(Icons.add),
              label: Text('Ir a Ejercicios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pastelGreen,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
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
    );
  }

  // 🔍 Debug: Mostrar información del estado
  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          '🔍 Debug Info',
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
              Text('• Disponibles: ${_availableExercises.length}', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12)),
              Text('• Filtrados: ${_filteredExercises.length}', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12)),
              Text('• Seleccionados: ${_selectedExercises.length}', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12)),

              SizedBox(height: 12),
              Text('🔍 Filtros:', style: GoogleFonts.poppins(color: AppColors.pastelPurple, fontWeight: FontWeight.bold)),
              Text('• Grupo muscular: $_selectedMuscleFilter', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12)),
              Text('• Categoría: $_selectedCategoria', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 12)),

              if (_availableExercises.isNotEmpty) ...[
                SizedBox(height: 12),
                Text('📝 Primeros ejercicios:', style: GoogleFonts.poppins(color: AppColors.pastelOrange, fontWeight: FontWeight.bold)),
                ...(_availableExercises.take(3).map((e) =>
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

  // 🔧 RESTO DE LOS WIDGETS (mismo código anterior pero con validaciones mejoradas)

  Widget _buildBasicInfo() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.techGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.pastelBlue.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pastelBlue.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: AppColors.createGlassmorphism(
          opacity: 0.1,
          blurRadius: 25,
          borderRadius: 16,
          borderColor: AppColors.pastelBlue.withOpacity(0.3),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.auroraGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.createBlueShadow(AppColors.pastelBlue),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Información Básica',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Nombre field with glassmorphism
            _buildGlassFormField(
              controller: _nombreController,
              label: 'Nombre de la rutina',
              hint: 'Ej: Push Day, Rutina de Piernas',
              icon: Icons.title_rounded,
              iconColor: AppColors.nutritionGreen,
              gradient: AppColors.nutritionGradient,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un nombre para la rutina';
                }
                return null;
              },
            ),
            SizedBox(height: 20),

            // Descripción field with glassmorphism
            _buildGlassFormField(
              controller: _descripcionController,
              label: 'Descripción',
              hint: 'Describe los objetivos de esta rutina',
              icon: Icons.description_rounded,
              iconColor: AppColors.fitnessRed,
              gradient: AppColors.fitnessGradient,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Agrega una descripción';
                }
                return null;
              },
            ),
            SizedBox(height: 20),

            // Row with category and duration
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: AppColors.createGlassmorphism(
                      opacity: 0.08,
                      blurRadius: 15,
                      borderRadius: 12,
                      borderColor: AppColors.pastelPurple.withOpacity(0.3),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategoria,
                      dropdownColor: AppColors.cardBlack,
                      style: GoogleFonts.poppins(color: AppColors.white),
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        labelStyle: GoogleFonts.poppins(
                          color: AppColors.pastelPurple,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Container(
                          margin: EdgeInsets.all(8),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.purpleGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getCategoriaIcon(_selectedCategoria),
                            color: AppColors.white,
                            size: 18,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      items: _categorias.map((categoria) => DropdownMenuItem(
                        value: categoria,
                        child: Row(
                          children: [
                            Icon(_getCategoriaIcon(categoria), color: _getCategoriaColor(categoria), size: 18),
                            SizedBox(width: 8),
                            Text(categoria),
                          ],
                        ),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoria = value!;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildGlassFormField(
                    controller: _duracionController,
                    label: 'Duración (min)',
                    hint: '60',
                    icon: Icons.timer_rounded,
                    iconColor: AppColors.nutritionOrange,
                    gradient: AppColors.orangeGradient,
                    keyboardType: TextInputType.number,
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
      ),
    );
  }

  // Helper method to create glassmorphism form fields
  Widget _buildGlassFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required LinearGradient gradient,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: AppColors.createGlassmorphism(
        opacity: 0.08,
        blurRadius: 15,
        borderRadius: 12,
        borderColor: iconColor.withOpacity(0.3),
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.poppins(
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: iconColor,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: AppColors.grey.withOpacity(0.7),
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.white,
              size: 18,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          errorStyle: GoogleFonts.poppins(
            color: AppColors.fitnessRed,
            fontSize: 12,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSelectedExercises() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.nutritionGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.createBlueShadow(AppColors.nutritionGreen),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: AppColors.createGlassmorphism(
          opacity: 0.1,
          borderRadius: 20,
          borderColor: AppColors.nutritionGreen.withOpacity(0.3),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.mintGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.nutritionGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.playlist_play_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Ejercicios Seleccionados',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.auroraGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.nutritionGreen.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fitness_center, color: AppColors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '${_selectedExercises.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ],
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
                      Icons.playlist_add_check_circle_rounded,
                      size: 64,
                      color: AppColors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No hay ejercicios seleccionados',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      'Agrega ejercicios desde la lista de abajo',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _selectedExercises.length,
              itemBuilder: (context, index) {
                final exercise = _selectedExercises[index];
                return _buildSelectedExerciseItem(exercise, index);
              },
            ),
        ],
      ),
    )
    );
  }

  Widget _buildSelectedExerciseItem(Exercise exercise, int index) {
    final color = _getColorByMuscleGroup(exercise.grupoMuscular);

    return Card(
      key: ValueKey(exercise.id),
      margin: EdgeInsets.only(bottom: 12),
      color: AppColors.surfaceBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.4), width: 1),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${index + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.drag_indicator_rounded, color: AppColors.grey, size: 24),
            ],
          ),
          title: Text(
            exercise.nombre,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                _buildInfoChip(
                  icon: _getIconByMuscleGroup(exercise.grupoMuscular),
                  label: exercise.grupoMuscular,
                  color: color,
                ),
                _buildInfoChip(
                  icon: Icons.repeat_rounded,
                  label: '${exercise.series}x${exercise.repeticiones}',
                  color: AppColors.pastelBlue,
                ),
                _buildInfoChip(
                  icon: Icons.fitness_center_rounded,
                  label: '${exercise.peso}kg',
                  color: AppColors.pastelGreen,
                ),
              ],
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_sweep_rounded, color: AppColors.fitnessRed, size: 24),
            onPressed: () {
              setState(() {
                _selectedExercises.removeAt(index);
              });
            },
            tooltip: 'Eliminar ejercicio',
          ),
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
        border: Border.all(
          color: AppColors.pastelPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.pastelPurple,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Agregar Ejercicios',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
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
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.pastelBlue : AppColors.surfaceBlack,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? AppColors.pastelBlue : AppColors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getMuscleGroupIcon(group),
                          color: isSelected ? AppColors.white : AppColors.grey,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          group,
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
          ),

          SizedBox(height: 20),

          Container(
            height: 300,
            decoration: BoxDecoration(
              color: AppColors.surfaceBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _filteredExercises.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No hay ejercicios',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.grey,
                    ),
                  ),
                  Text(
                    'en esta categoría',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(8),
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

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isSelected ? color.withOpacity(0.2) : AppColors.surfaceBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : AppColors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(
            _getIconByMuscleGroup(exercise.grupoMuscular),
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          exercise.nombre,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
          ),
        ),
        subtitle: Text(
          '${exercise.series}x${exercise.repeticiones}  •  ${exercise.peso}kg',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.grey,
          ),
        ),
        trailing: Icon(
          isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
          color: isSelected ? color : AppColors.grey,
          size: 28,
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

  // Helper method to create styled info chips
  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.white.withOpacity(0.9),
        ),
      ),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  // FUNCIONES DE ICONOS (mismo código anterior)

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria) {
      case 'Fuerza': return Icons.fitness_center;
      case 'Cardio': return Icons.favorite;
      case 'Funcional': return Icons.sports_gymnastics;
      case 'Principiante': return Icons.school_rounded;
      case 'Avanzado': return Icons.workspace_premium;
      default: return Icons.category;
    }
  }

  Color _getCategoriaColor(String categoria) {
    switch (categoria) {
      case 'Fuerza': return AppColors.pastelBlue;
      case 'Cardio': return Colors.red;
      case 'Funcional': return AppColors.pastelGreen;
      case 'Principiante': return AppColors.pastelOrange;
      case 'Avanzado': return AppColors.pastelPurple;
      default: return AppColors.grey;
    }
  }

  IconData _getMuscleGroupIcon(String group) {
    switch (group) {
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