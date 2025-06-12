import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class ExercisesTab extends StatefulWidget {
  @override
  _ExercisesTabState createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> {
  // 📝 VARIABLES - Aquí puedes agregar tus datos
  String _selectedCategory = 'Todos';
  final List<String> _categories = ['Todos', 'Pecho', 'Espalda', 'Piernas', 'Hombros', 'Brazos', 'Cardio'];

  // 📝 DATOS DE EJERCICIOS - Reemplaza esto con tu base de datos
  final List<Map<String, dynamic>> _exercises = [
    {
      'name': 'Push-ups',
      'category': 'Pecho',
      'duration': '3 sets x 15 reps',
      'difficulty': 'Intermedio',
      'calories': '45 cal',
      'icon': Icons.fitness_center,
      'color': AppColors.pastelPink,
    },
    {
      'name': 'Squats',
      'category': 'Piernas',
      'duration': '4 sets x 20 reps',
      'difficulty': 'Principiante',
      'calories': '60 cal',
      'icon': Icons.accessibility_new,
      'color': AppColors.pastelBlue,
    },
    {
      'name': 'Pull-ups',
      'category': 'Espalda',
      'duration': '3 sets x 8 reps',
      'difficulty': 'Avanzado',
      'calories': '55 cal',
      'icon': Icons.fitness_center,
      'color': AppColors.pastelGreen,
    },
    {
      'name': 'Planks',
      'category': 'Core',
      'duration': '3 sets x 60 seg',
      'difficulty': 'Intermedio',
      'calories': '35 cal',
      'icon': Icons.timer,
      'color': AppColors.pastelPurple,
    },
    {
      'name': 'Burpees',
      'category': 'Cardio',
      'duration': '4 sets x 10 reps',
      'difficulty': 'Avanzado',
      'calories': '80 cal',
      'icon': Icons.directions_run,
      'color': AppColors.pastelOrange,
    },
    {
      'name': 'Lunges',
      'category': 'Piernas',
      'duration': '3 sets x 12 reps',
      'difficulty': 'Intermedio',
      'calories': '50 cal',
      'icon': Icons.accessibility_new,
      'color': AppColors.pastelBlue,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Header con búsqueda
            _buildHeader(),

            // Categorías horizontales
            _buildCategories(),

            // Lista de ejercicios
            Expanded(child: _buildExercisesList()),
          ],
        ),
      ),
      // Botón flotante para agregar ejercicio
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 🔧 TU LÓGICA: Agregar nuevo ejercicio
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

          // Barra de búsqueda
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
              onChanged: (value) {
                // 🔧 TU LÓGICA: Filtrar ejercicios por búsqueda
                print("Buscando: $value");
              },
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
              // 🔧 TU LÓGICA: Filtrar ejercicios por categoría
              print("Categoría seleccionada: $category");
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
    // 🔧 TU LÓGICA: Aquí filtrarías los ejercicios según categoría y búsqueda
    final filteredExercises = _exercises.where((exercise) {
      if (_selectedCategory == 'Todos') return true;
      return exercise['category'] == _selectedCategory;
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = filteredExercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: exercise['color'].withOpacity(0.1),
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
            // 🔧 TU LÓGICA: Navegar a detalles del ejercicio
            _openExerciseDetails(exercise);
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                // Icono del ejercicio
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: exercise['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    exercise['icon'],
                    color: exercise['color'],
                    size: 30,
                  ),
                ),

                SizedBox(width: 16),

                // Información del ejercicio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        exercise['duration'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChip(exercise['difficulty'], _getDifficultyColor(exercise['difficulty'])),
                          SizedBox(width: 8),
                          _buildChip(exercise['calories'], AppColors.pastelOrange),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botón de acción
                IconButton(
                  onPressed: () {
                    // 🔧 TU LÓGICA: Iniciar ejercicio o agregar a rutina
                    _startExercise(exercise);
                  },
                  icon: Icon(
                    Icons.play_circle_filled,
                    color: exercise['color'],
                    size: 32,
                  ),
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Principiante':
        return AppColors.pastelGreen;
      case 'Intermedio':
        return AppColors.pastelOrange;
      case 'Avanzado':
        return AppColors.pastelPink;
      default:
        return AppColors.grey;
    }
  }

  // 🔧 MÉTODOS PARA TU LÓGICA - Implementa estos métodos con tu lógica de negocio

  void _showAddExerciseDialog() {
    // 🔧 TU LÓGICA: Mostrar diálogo para agregar ejercicio
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Agregar Ejercicio',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Text(
          'Aquí implementarías tu formulario para agregar ejercicios',
          style: GoogleFonts.poppins(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              // 🔧 TU LÓGICA: Guardar ejercicio en la base de datos
              Navigator.pop(context);
              print("Guardar ejercicio en BD");
            },
            child: Text('Guardar', style: TextStyle(color: AppColors.pastelBlue)),
          ),
        ],
      ),
    );
  }

  void _openExerciseDetails(Map<String, dynamic> exercise) {
    // 🔧 TU LÓGICA: Navegar a pantalla de detalles del ejercicio
    print("Abrir detalles de: ${exercise['name']}");

    // Ejemplo de navegación a otra pantalla:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ExerciseDetailScreen(exercise: exercise),
    //   ),
    // );
  }

  void _startExercise(Map<String, dynamic> exercise) {
    // 🔧 TU LÓGICA: Iniciar entrenamiento o agregar a rutina
    print("Iniciar ejercicio: ${exercise['name']}");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando ${exercise['name']}'),
        backgroundColor: exercise['color'],
      ),
    );
  }
}