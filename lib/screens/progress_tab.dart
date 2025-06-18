import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../domain/user.dart';

class ProgressTab extends StatefulWidget {
  final User user;

  const ProgressTab({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  _ProgressTabState createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  // 📝 VARIABLES - Datos del progreso del usuario
  int _selectedTabIndex = 0; // 0: Stats, 1: Comparison, 2: Exercise Progress
  final List<String> _tabs = ['Stats', 'Comparación', 'Ejercicios'];

  // 📝 DATOS DE ESTADÍSTICAS PRINCIPALES
  final Map<String, dynamic> _mainStats = {
    'weight': {'current': 84, 'previous': 75, 'unit': 'kg'},
    'training_streak': {'current': 8, 'unit': 'días'},
    'total_training': {'current': 81, 'unit': 'días'},
  };

  // 📝 DATOS DE PROGRESO DE EJERCICIOS
  final List<Map<String, dynamic>> _exerciseProgress = [
    {
      'name': 'Bench press',
      'first_record': 65,
      'last_record': 74,
      'pr': 80,
      'unit': 'kg',
    },
    {
      'name': 'Squat',
      'first_record': 70,
      'last_record': 73,
      'pr': 75,
      'unit': 'kg',
    },
    {
      'name': 'Deadlift',
      'first_record': 80,
      'last_record': 90,
      'pr': 95,
      'unit': 'kg',
    },
    {
      'name': 'Pull-ups',
      'first_record': 5,
      'last_record': 8,
      'pr': 12,
      'unit': 'reps',
    },
  ];

  // ✅ MÉTODO PARA EXTRAER NOMBRE DEL EMAIL
  String _getUserDisplayName() {
    String email = widget.user.email;
    if (email.contains('@')) {
      return email.split('@')[0].toLowerCase();
    }
    return email;
  }

  // ✅ MÉTODO PARA CAPITALIZAR PRIMERA LETRA
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
    );
  }

  Widget _buildHeader() {
    final userName = _capitalizeFirst(widget.user.name);

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progreso de $userName',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Revisa tus estadísticas y mejoras',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _shareProgress(),
                icon: Icon(
                  Icons.share,
                  color: AppColors.pastelPink,
                  size: 24,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '"Your body can do it. Your mind is what stops you" ',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextSpan(
                  text: '- Prince',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.pastelPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.pastelPink : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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
        return _buildStatsContent();
      case 1:
        return _buildComparisonContent();
      case 2:
        return _buildExerciseProgressContent();
      default:
        return _buildStatsContent();
    }
  }

  Widget _buildStatsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 20),
          // Main Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Peso',
                  value: '${_mainStats['weight']['current']}',
                  unit: _mainStats['weight']['unit'],
                  subtitle: 'desde ${_mainStats['weight']['previous']}kg',
                  color: AppColors.pastelBlue,
                  icon: Icons.monitor_weight,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Racha',
                  value: '${_mainStats['training_streak']['current']}',
                  unit: _mainStats['training_streak']['unit'],
                  subtitle: 'días seguidos',
                  color: AppColors.pastelOrange,
                  icon: Icons.local_fire_department,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildStatCard(
            title: 'Total entrenado',
            value: '${_mainStats['total_training']['current']}',
            unit: _mainStats['total_training']['unit'],
            subtitle: 'días completados',
            color: AppColors.pastelGreen,
            icon: Icons.fitness_center,
            isWide: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required Color color,
    required IconData icon,
    bool isWide = false,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: isWide ? 36 : 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparación Corporal',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.pastelPink,
                  AppColors.pastelPurple,
                  AppColors.pastelBlue,
                ],
              ),
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
                  'Comparación de Estadísticas',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _buildComparisonSide(
                        title: 'Inicial',
                        bodyParts: ['cardio', 'brazos', 'glúteos', 'espalda'],
                        isInitial: true,
                      ),
                    ),
                    SizedBox(width: 20),
                    Column(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          color: AppColors.white,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'VS',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: _buildComparisonSide(
                        title: 'Actual',
                        bodyParts: ['cardio', 'pecho', 'piernas', 'espalda'],
                        isInitial: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSide({
    required String title,
    required List<String> bodyParts,
    required bool isInitial,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Figura humana simplificada
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cabeza
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Cuerpo
                    Container(
                      width: isInitial ? 30 : 35,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 4),
                    // Piernas
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isInitial ? 12 : 15,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: 4),
                        Container(
                          width: isInitial ? 12 : 15,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Etiquetas de partes del cuerpo
              ...bodyParts.asMap().entries.map((entry) {
                int index = entry.key;
                String part = entry.value;
                return Positioned(
                  left: index.isEven ? 10 : null,
                  right: index.isOdd ? 10 : null,
                  top: 20 + (index * 30.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.pastelPink.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      part,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseProgressContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progreso de Ejercicios',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.pastelBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Header de la tabla
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.pastelBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Ejercicio',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Inicial',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Último',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'PR',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Filas de la tabla
                ..._exerciseProgress.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> exercise = entry.value;
                  bool isLast = index == _exerciseProgress.length - 1;

                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: isLast ? null : Border(
                        bottom: BorderSide(
                          color: AppColors.grey.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            exercise['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${exercise['first_record']} ${exercise['unit']}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${exercise['last_record']} ${exercise['unit']}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.pastelGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${exercise['pr']} ${exercise['unit']}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.pastelPink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 MÉTODOS PARA LÓGICA DE NEGOCIO

  void _shareProgress() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.share, color: AppColors.white),
            SizedBox(width: 8),
            Text('Compartir progreso próximamente'),
          ],
        ),
        backgroundColor: AppColors.pastelPink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}