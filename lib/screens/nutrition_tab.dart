import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class NutritionTab extends StatefulWidget {
  @override
  _NutritionTabState createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  // 📝 VARIABLES - Aquí puedes agregar tus datos
  int _selectedTabIndex = 0; // 0: Hoy, 1: Historial, 2: Alimentos
  final List<String> _tabs = ['Hoy', 'Historial', 'Alimentos'];

  // 📝 DATOS DE NUTRICIÓN - Reemplaza con tu base de datos
  final Map<String, dynamic> _todayNutrition = {
    'calories': 1247,
    'targetCalories': 2000,
    'protein': 45,
    'targetProtein': 120,
    'carbs': 180,
    'targetCarbs': 250,
    'fat': 35,
    'targetFat': 70,
    'water': 1.2,
    'targetWater': 2.5,
  };

  final List<Map<String, dynamic>> _todayMeals = [
    {
      'name': 'Desayuno',
      'time': '08:30',
      'calories': 420,
      'foods': ['Avena con frutas', 'Café con leche', 'Plátano'],
      'color': AppColors.pastelOrange,
      'icon': Icons.wb_sunny,
    },
    {
      'name': 'Almuerzo',
      'time': '13:15',
      'calories': 580,
      'foods': ['Pollo a la plancha', 'Arroz integral', 'Ensalada'],
      'color': AppColors.pastelGreen,
      'icon': Icons.restaurant,
    },
    {
      'name': 'Cena',
      'time': '19:00',
      'calories': 247,
      'foods': ['Salmón', 'Verduras al vapor'],
      'color': AppColors.pastelPurple,
      'icon': Icons.dinner_dining,
    },
  ];

  final List<Map<String, dynamic>> _foodDatabase = [
    {
      'name': 'Pollo (100g)',
      'calories': 239,
      'protein': 27,
      'carbs': 0,
      'fat': 14,
      'category': 'Proteína',
    },
    {
      'name': 'Arroz integral (100g)',
      'calories': 123,
      'protein': 3,
      'carbs': 23,
      'fat': 1,
      'category': 'Carbohidrato',
    },
    {
      'name': 'Brócoli (100g)',
      'calories': 34,
      'protein': 3,
      'carbs': 7,
      'fat': 0,
      'category': 'Verdura',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Tabs
            _buildTabs(),

            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 🔧 TU LÓGICA: Agregar nueva comida
          _showAddFoodDialog();
        },
        backgroundColor: AppColors.pastelOrange,
        child: Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nutrición',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Text(
                'Hoy - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // 🔧 TU LÓGICA: Abrir configuración de nutrición
              print("Configuración de nutrición");
            },
            icon: Icon(
              Icons.settings,
              color: AppColors.pastelOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          int index = entry.key;
          String tab = entry.value;
          bool isSelected = index == _selectedTabIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
                // 🔧 TU LÓGICA: Cambiar contenido según tab
                print("Tab seleccionado: $tab");
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.pastelOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.white : AppColors.grey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildTodayContent();
      case 1:
        return _buildHistoryContent();
      case 2:
        return _buildFoodsContent();
      default:
        return _buildTodayContent();
    }
  }

  Widget _buildTodayContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de calorías
          _buildCaloriesSummary(),

          SizedBox(height: 20),

          // Macronutrientes
          _buildMacronutrients(),

          SizedBox(height: 20),

          // Agua
          _buildWaterIntake(),

          SizedBox(height: 20),

          // Comidas de hoy
          _buildTodayMeals(),
        ],
      ),
    );
  }

  Widget _buildCaloriesSummary() {
    final progress = _todayNutrition['calories'] / _todayNutrition['targetCalories'];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.pastelPink.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Calorías de Hoy',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${_todayNutrition['calories']}',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                TextSpan(
                  text: ' / ${_todayNutrition['targetCalories']} cal',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            borderRadius: BorderRadius.circular(10),
          ),
          SizedBox(height: 8),
          Text(
            'Quedan ${_todayNutrition['targetCalories'] - _todayNutrition['calories']} calorías',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacronutrients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Macronutrientes',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMacroCard('Proteína', _todayNutrition['protein'], _todayNutrition['targetProtein'], 'g', AppColors.pastelBlue)),
            SizedBox(width: 12),
            Expanded(child: _buildMacroCard('Carbohidratos', _todayNutrition['carbs'], _todayNutrition['targetCarbs'], 'g', AppColors.pastelGreen)),
            SizedBox(width: 12),
            Expanded(child: _buildMacroCard('Grasas', _todayNutrition['fat'], _todayNutrition['targetFat'], 'g', AppColors.pastelPink)),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroCard(String name, int current, int target, String unit, Color color) {
    final progress = current / target;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '$current$unit',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          Text(
            '/ $target$unit',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceBlack,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIntake() {
    final progress = _todayNutrition['water'] / _todayNutrition['targetWater'];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.water_drop,
            color: AppColors.pastelBlue,
            size: 32,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agua',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '${_todayNutrition['water']}L / ${_todayNutrition['targetWater']}L',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surfaceBlack,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.pastelBlue),
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // 🔧 TU LÓGICA: Agregar agua
              setState(() {
                _todayNutrition['water'] += 0.25;
              });
              print("Agua agregada: ${_todayNutrition['water']}L");
            },
            icon: Icon(
              Icons.add_circle,
              color: AppColors.pastelBlue,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMeals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comidas de Hoy',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _todayMeals.length,
          itemBuilder: (context, index) {
            final meal = _todayMeals[index];
            return _buildMealCard(meal);
          },
        ),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // 🔧 TU LÓGICA: Editar comida
            _editMeal(meal);
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: meal['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    meal['icon'],
                    color: meal['color'],
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            meal['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            '${meal['calories']} cal',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: meal['color'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        meal['time'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        meal['foods'].join(', '),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryContent() {
    return Center(
      child: Text(
        '🔧 Aquí implementarás el historial de nutrición',
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColors.grey,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFoodsContent() {
    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: _foodDatabase.length,
      itemBuilder: (context, index) {
        final food = _foodDatabase[index];
        return _buildFoodItem(food);
      },
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          food['name'],
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
          ),
        ),
        subtitle: Text(
          '${food['calories']} cal | P: ${food['protein']}g | C: ${food['carbs']}g | G: ${food['fat']}g',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.grey,
          ),
        ),
        trailing: IconButton(
          onPressed: () {
            // 🔧 TU LÓGICA: Agregar alimento a comida
            _addFoodToMeal(food);
          },
          icon: Icon(
            Icons.add_circle,
            color: AppColors.pastelOrange,
          ),
        ),
      ),
    );
  }

  // 🔧 MÉTODOS PARA TU LÓGICA - Implementa estos métodos con tu lógica de negocio

  void _showAddFoodDialog() {
    // 🔧 TU LÓGICA: Mostrar diálogo para agregar comida
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Agregar Alimento',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Text(
          'Aquí implementarías tu formulario para agregar alimentos',
          style: GoogleFonts.poppins(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              // 🔧 TU LÓGICA: Guardar alimento en BD
              Navigator.pop(context);
              print("Guardar alimento en BD");
            },
            child: Text('Guardar', style: TextStyle(color: AppColors.pastelOrange)),
          ),
        ],
      ),
    );
  }

  void _editMeal(Map<String, dynamic> meal) {
    // 🔧 TU LÓGICA: Editar comida
    print("Editar comida: ${meal['name']}");
  }

  void _addFoodToMeal(Map<String, dynamic> food) {
    // 🔧 TU LÓGICA: Agregar alimento a una comida
    print("Agregar ${food['name']} a comida");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food['name']} agregado'),
        backgroundColor: AppColors.pastelOrange,
      ),
    );
  }
}