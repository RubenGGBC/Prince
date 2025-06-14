import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../domain/exercise.dart';
import '../database/DatabaseHelper.dart';
import 'exercises_tab.dart';
import 'añadir_rutina.dart';
import 'workout_session_screen.dart';
import 'prince_ai_chat_screen.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PageController _pageController = PageController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int _currentTipIndex = 0;
  List<Exercise> _recentExercises = [];
  bool _isLoading = true;

  final List<Map<String, String>> _fitnessQuotes = [
    {
      'quote': 'El único ejercicio malo es el que no haces.',
      'author': 'Prince'
    },
    {
      'quote': 'Tu cuerpo puede hacerlo. Es tu mente la que necesitas convencer.',
      'author': 'Prince'
    },
    {
      'quote': 'El progreso, no la perfección.',
      'author': 'Prince'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentExercises();
    Future.delayed(Duration(seconds: 5), _autoScrollQuotes);
  }

  Future<void> _loadRecentExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _dbHelper.getAllExercises();
      setState(() {
        _recentExercises = exercises.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error cargando ejercicios: $e');
    }
  }

  void _autoScrollQuotes() {
    if (mounted) {
      _currentTipIndex = (_currentTipIndex + 1) % _fitnessQuotes.length;
      _pageController.animateToPage(
        _currentTipIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      Future.delayed(Duration(seconds: 5), _autoScrollQuotes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final isDesktop = constraints.maxWidth > 1024;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : (isTablet ? 30 : 20),
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📱 Header
                  _buildHeader(isTablet, isDesktop),
                  SizedBox(height: isTablet ? 30 : 20),

                  // 🤖 BOTÓN DESTACADO - PrinceIA
                  _buildPrinceAIButton(isTablet, isDesktop),
                  SizedBox(height: isTablet ? 30 : 20),

                  // 💪 BOTÓN PRINCIPAL - Empezar Entrenamiento
                  _buildStartWorkoutButton(isTablet, isDesktop),
                  SizedBox(height: isTablet ? 40 : 30),

                  // 📊 Quick Stats
                  _buildQuickStats(isTablet, isDesktop),
                  SizedBox(height: isTablet ? 40 : 30),

                  // 💭 Quote Carousel
                  _buildQuoteCarousel(isTablet, isDesktop),
                  SizedBox(height: isTablet ? 40 : 30),

                  // 📈 Today Summary
                  _buildTodaySummary(isTablet, isDesktop),
                  SizedBox(height: isTablet ? 40 : 30),

                  // ⚡ Quick Actions
                  _buildQuickActions(isTablet, isDesktop),
                  SizedBox(height: isTablet ? 40 : 30),

                  // 📜 Recent Activity
                  _buildRecentActivity(isTablet, isDesktop),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 📱 HEADER
  Widget _buildHeader(bool isTablet, bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola!',
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 32 : (isTablet ? 28 : 24),
                  fontWeight: FontWeight.w300,
                  color: AppColors.grey,
                ),
              ),
              Text(
                'Usuario',
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 36 : (isTablet ? 32 : 28),
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Text(
                'Es hora de entrenar 💪',
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                  color: AppColors.pastelBlue,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: AppColors.cardBlack,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.pastelPink.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: AppColors.pastelPink,
            size: isTablet ? 28 : 24,
          ),
        ),
      ],
    );
  }

  // 🤖 BOTÓN DESTACADO - PrinceIA
  Widget _buildPrinceAIButton(bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      height: isDesktop ? 100 : (isTablet ? 90 : 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.pastelPurple,
            AppColors.pastelPink,
            AppColors.pastelBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.pastelPink.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 3,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrinceAIChatScreen())
            );
          },
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Row(
              children: [
                // 🤖 Icono de IA
                Container(
                  width: isDesktop ? 50 : (isTablet ? 45 : 40),
                  height: isDesktop ? 50 : (isTablet ? 45 : 40),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: AppColors.white,
                    size: isDesktop ? 28 : (isTablet ? 24 : 20),
                  ),
                ),

                SizedBox(width: isTablet ? 16 : 12),

                // 📝 Texto principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            'PrinceIA',
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'BETA',
                              style: GoogleFonts.poppins(
                                fontSize: isDesktop ? 10 : (isTablet ? 9 : 8),
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Tu entrenador personal con IA • 5 mensajes diarios',
                        style: GoogleFonts.poppins(
                          fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // ➡️ Icono de chat
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.white,
                    size: isTablet ? 24 : 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🚀 BOTÓN PRINCIPAL - Empezar Entrenamiento
  Widget _buildStartWorkoutButton(bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      height: isDesktop ? 120 : (isTablet ? 100 : 80),
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
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.pastelPink.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 3,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            _startWorkoutSession();
          },
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Row(
              children: [
                Container(
                  width: isDesktop ? 60 : (isTablet ? 50 : 40),
                  height: isDesktop ? 60 : (isTablet ? 50 : 40),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.white,
                    size: isDesktop ? 36 : (isTablet ? 30 : 24),
                  ),
                ),

                SizedBox(width: isTablet ? 20 : 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Empezar Entrenamiento',
                        style: GoogleFonts.poppins(
                          fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        'Selecciona tu rutina y comienza',
                        style: GoogleFonts.poppins(
                          fontSize: isDesktop ? 16 : (isTablet ? 14 : 12),
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.white,
                  size: isTablet ? 24 : 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 📊 QUICK STATS
  Widget _buildQuickStats(bool isTablet, bool isDesktop) {
    final crossAxisCount = isDesktop ? 4 : 3;

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isTablet ? 20 : 15,
      mainAxisSpacing: isTablet ? 20 : 15,
      childAspectRatio: isDesktop ? 1.2 : (isTablet ? 1.1 : 1.0),
      children: [
        _buildStatCard(
          'Calorías',
          '1,247',
          '/ 2,000',
          Icons.local_fire_department,
          AppColors.pastelOrange,
          0.62,
          isTablet,
          isDesktop,
        ),
        _buildStatCard(
          'Agua',
          '1.2L',
          '/ 2.5L',
          Icons.water_drop,
          AppColors.pastelBlue,
          0.48,
          isTablet,
          isDesktop,
        ),
        _buildStatCard(
          'Pasos',
          '6,547',
          '/ 10,000',
          Icons.directions_walk,
          AppColors.pastelGreen,
          0.65,
          isTablet,
          isDesktop,
        ),
        if (isDesktop)
          _buildStatCard(
            'Entrenamientos',
            '12',
            '/ 20',
            Icons.fitness_center,
            AppColors.pastelPurple,
            0.60,
            isTablet,
            isDesktop,
          ),
      ],
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      String target,
      IconData icon,
      Color color,
      double progress,
      bool isTablet,
      bool isDesktop,
      ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 18 : 16)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: isDesktop ? 24 : (isTablet ? 22 : 20),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                    color: AppColors.grey,
                  ),
                ),
                SizedBox(height: 4),
                FittedBox(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
                Text(
                  target,
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 12 : (isTablet ? 11 : 10),
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),

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

  // 💭 QUOTE CAROUSEL
  Widget _buildQuoteCarousel(bool isTablet, bool isDesktop) {
    return Container(
      height: isDesktop ? 140 : (isTablet ? 130 : 120),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentTipIndex = index;
          });
        },
        itemCount: _fitnessQuotes.length,
        itemBuilder: (context, index) {
          final quote = _fitnessQuotes[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 5),
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 22 : 20)),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.format_quote,
                  color: AppColors.white,
                  size: isDesktop ? 28 : (isTablet ? 26 : 24),
                ),
                SizedBox(height: 8),
                Text(
                  quote['quote']!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '- ${quote['author']}',
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                    fontWeight: FontWeight.w300,
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 📈 TODAY SUMMARY
  Widget _buildTodaySummary(bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 22 : 20)),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(20),
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
                Icons.today,
                color: AppColors.pastelPurple,
                size: isDesktop ? 28 : (isTablet ? 26 : 24),
              ),
              SizedBox(width: 12),
              Text(
                'Resumen de Hoy',
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          if (isTablet || isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Entrenamientos', '1', Icons.fitness_center, isTablet, isDesktop),
                _buildSummaryItem('Tiempo activo', '45min', Icons.timer, isTablet, isDesktop),
                _buildSummaryItem('Calorías quemadas', '312', Icons.local_fire_department, isTablet, isDesktop),
              ],
            )
          else
            Column(
              children: [
                _buildSummaryItem('Entrenamientos', '1', Icons.fitness_center, isTablet, isDesktop),
                SizedBox(height: 12),
                _buildSummaryItem('Tiempo activo', '45min', Icons.timer, isTablet, isDesktop),
                SizedBox(height: 12),
                _buildSummaryItem('Calorías quemadas', '312', Icons.local_fire_department, isTablet, isDesktop),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, bool isTablet, bool isDesktop) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.pastelPurple,
            size: isDesktop ? 24 : (isTablet ? 22 : 20),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ⚡ QUICK ACTIONS
  Widget _buildQuickActions(bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 16),

        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? 4 : (isTablet ? 4 : 2),
          crossAxisSpacing: isTablet ? 20 : 15,
          mainAxisSpacing: isTablet ? 20 : 15,
          childAspectRatio: isDesktop ? 1.0 : (isTablet ? 0.9 : 1.0),
          children: [
            _buildActionButton('Ver Ejercicios', Icons.fitness_center, AppColors.pastelGreen, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ExercisesTab()));
            }, isTablet, isDesktop),
            _buildActionButton('Crear Rutina', Icons.playlist_add, AppColors.pastelPurple, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CrearRutinaScreen()));
            }, isTablet, isDesktop),
            _buildActionButton('Mis Rutinas', Icons.library_books, AppColors.pastelBlue, () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lista de rutinas próximamente'), backgroundColor: AppColors.pastelBlue),
              );
            }, isTablet, isDesktop),
            _buildActionButton('Registrar Comida', Icons.restaurant, AppColors.pastelOrange, () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Función de nutrición próximamente'), backgroundColor: AppColors.pastelOrange),
              );
            }, isTablet, isDesktop),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      bool isTablet,
      bool isDesktop,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 22 : 20)),
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: isDesktop ? 36 : (isTablet ? 34 : 32),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 📜 RECENT ACTIVITY
  Widget _buildRecentActivity(bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad Reciente',
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 16),
        _buildActivityItem('Entrenamiento de Pecho', '2 horas ago', Icons.fitness_center, AppColors.pastelBlue, isTablet, isDesktop),
        _buildActivityItem('Registraste almuerzo', '4 horas ago', Icons.restaurant, AppColors.pastelOrange, isTablet, isDesktop),
        _buildActivityItem('Tomaste progreso', 'Ayer', Icons.camera_alt, AppColors.pastelPink, isTablet, isDesktop),
      ],
    );
  }

  Widget _buildActivityItem(
      String title,
      String time,
      IconData icon,
      Color color,
      bool isTablet,
      bool isDesktop,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 18 : 16)),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 10 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: isDesktop ? 24 : (isTablet ? 22 : 20),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 MÉTODOS AUXILIARES

  void _startWorkoutSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}