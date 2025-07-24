import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../domain/user.dart';
import '../domain/nutricion.dart';
import '../database/database_helper.dart';

class NutritionTab extends StatefulWidget {
  final User? user;

  const NutritionTab({
    Key? key,
    this.user,
  }) : super(key: key);

  @override
  _NutritionTabState createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  // 📝 VARIABLES - Aquí puedes agregar tus datos
  int _selectedTabIndex = 0; // 0: Hoy, 1: Historial, 2: Alimentos
  final List<String> _tabs = ['Hoy', 'Historial', 'Alimentos'];
  
  // Database and nutrition data
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Nutricion> _nutritionItems = [];
  bool _isLoading = true;

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
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  Future<void> _loadNutritionData() async {
    setState(() => _isLoading = true);
    try {
      final nutritionData = await _dbHelper.getAllNutrition();
      if (mounted) {
        setState(() {
          _nutritionItems = nutritionData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error cargando datos de nutrición: $e');
    }
  }

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
        backgroundColor: AppColors.nutritionOrange,
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
                  color: isSelected ? AppColors.nutritionOrange : Colors.transparent,
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
        gradient: AppColors.nutritionGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.nutritionGreen.withOpacity(0.3),
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
    _showAddRecipeDialog();
  }

  void _showAddRecipeDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _caloriasController = TextEditingController();
    final _proteinasController = TextEditingController();
    final _grasasController = TextEditingController();
    final _carbohidratosController = TextEditingController();
    final _descripcionController = TextEditingController();
    String _selectedCategory = 'Desayuno';
    
    final categories = ['Desayuno', 'Almuerzo', 'Cena', 'Snack'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              gradient: AppColors.nutritionGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.createBlueShadow(AppColors.nutritionGreen),
            ),
            child: Container(
              decoration: AppColors.createGlassmorphism(
                opacity: 0.1,
                borderRadius: 20,
                borderColor: AppColors.nutritionGreen.withOpacity(0.3),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppColors.auroraGradient,
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
                              Icons.restaurant_menu,
                              color: AppColors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Agregar Nueva Receta',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: AppColors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      
                      // Form Content
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Photo Upload Section
                              Container(
                                height: 120,
                                decoration: AppColors.createGlassmorphism(
                                  opacity: 0.15,
                                  borderRadius: 16,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.orangeGradient,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Icon(
                                          Icons.add_a_photo,
                                          color: AppColors.white,
                                          size: 28,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Agregar Foto (Opcional)',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              
                              // Recipe Name
                              _buildGlassFormField(
                                controller: _nameController,
                                label: 'Nombre de la Receta',
                                icon: Icons.restaurant,
                                gradient: AppColors.nutritionGradient,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa el nombre de la receta';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              
                              // Category Selector
                              Container(
                                decoration: AppColors.createGlassmorphism(opacity: 0.15),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: InputDecoration(
                                    labelText: 'Categoría',
                                    labelStyle: GoogleFonts.poppins(color: AppColors.white.withOpacity(0.8)),
                                    prefixIcon: Container(
                                      margin: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.purpleGradient,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.category, color: AppColors.white, size: 20),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                  ),
                                  dropdownColor: AppColors.surfaceBlack,
                                  style: GoogleFonts.poppins(color: AppColors.white),
                                  items: categories.map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category, style: GoogleFonts.poppins(color: AppColors.white)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value!;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              // Macronutrients Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildGlassFormField(
                                      controller: _caloriasController,
                                      label: 'Calorías',
                                      icon: Icons.local_fire_department,
                                      gradient: AppColors.fitnessGradient,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Requerido';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Número inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildGlassFormField(
                                      controller: _proteinasController,
                                      label: 'Proteínas (g)',
                                      icon: Icons.fitness_center,
                                      gradient: AppColors.purpleGradient,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Requerido';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Número inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildGlassFormField(
                                      controller: _carbohidratosController,
                                      label: 'Carbohidratos (g)',
                                      icon: Icons.grain,
                                      gradient: AppColors.orangeGradient,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Requerido';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Número inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildGlassFormField(
                                      controller: _grasasController,
                                      label: 'Grasas (g)',
                                      icon: Icons.opacity,
                                      gradient: AppColors.mintGradient,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Requerido';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Número inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              
                              // Description
                              _buildGlassFormField(
                                controller: _descripcionController,
                                label: 'Descripción (Opcional)',
                                icon: Icons.description,
                                gradient: AppColors.auroraGradient,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Action Buttons
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: AppColors.white.withOpacity(0.1),
                              ),
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.poppins(
                                  color: AppColors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _saveRecipe(
                                _formKey,
                                _nameController,
                                _caloriasController,
                                _proteinasController,
                                _grasasController,
                                _carbohidratosController,
                                _descripcionController,
                                _selectedCategory,
                                context,
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: AppColors.nutritionOrange,
                                elevation: 8,
                                shadowColor: AppColors.nutritionOrange.withOpacity(0.4),
                              ),
                              child: Text(
                                'Guardar Receta',
                                style: GoogleFonts.poppins(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildGlassFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: AppColors.createGlassmorphism(opacity: 0.15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: GoogleFonts.poppins(color: AppColors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: AppColors.white.withOpacity(0.8)),
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          errorStyle: GoogleFonts.poppins(color: AppColors.fitnessRed),
        ),
      ),
    );
  }

  Future<void> _saveRecipe(
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController caloriasController,
    TextEditingController proteinasController,
    TextEditingController grasasController,
    TextEditingController carbohidratosController,
    TextEditingController descripcionController,
    String selectedCategory,
    BuildContext context,
  ) async {
    if (formKey.currentState!.validate()) {
      try {
        final newRecipe = Nutricion(
          name: nameController.text,
          calorias: double.parse(caloriasController.text),
          proteinas: double.parse(proteinasController.text),
          grasas: double.parse(grasasController.text),
          carbohidratos: double.parse(carbohidratosController.text),
          categoria: selectedCategory,
          descripcion: descripcionController.text.isEmpty ? null : descripcionController.text,
        );

        await _dbHelper.addNutrition(newRecipe);
        await _loadNutritionData(); // Reload the data

        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receta "${nameController.text}" agregada exitosamente'),
            backgroundColor: AppColors.nutritionGreen,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la receta: $e'),
            backgroundColor: AppColors.fitnessRed,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
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
        backgroundColor: AppColors.nutritionOrange,
      ),
    );
  }
}