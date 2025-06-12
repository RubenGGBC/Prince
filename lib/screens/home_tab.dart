import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PageController _pageController = PageController();
  int _currentTipIndex = 0;

  final List<Map<String, String>> _fitnessQuotes = [
    {
      'quote': 'El único ejercicio malo es el que no haces.',
      'author': 'Motivación FitLife'
    },
    {
      'quote': 'Tu cuerpo puede hacerlo. Es tu mente la que necesitas convencer.',
      'author': 'Motivación FitLife'
    },
    {
      'quote': 'El progreso, no la perfección.',
      'author': 'Motivación FitLife'
    },
  ];

  @override
  void initState() {
    super.initState();
    // Auto-scroll quotes every 5 seconds
    Future.delayed(Duration(seconds: 5), _autoScrollQuotes);
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              SizedBox(height: 30),

              // Quick Stats Cards
              _buildQuickStats(),

              SizedBox(height: 30),

              // Motivational Quote Carousel
              _buildQuoteCarousel(),

              SizedBox(height: 30),

              // Today's Summary
              _buildTodaySummary(),

              SizedBox(height: 30),

              // Quick Actions
              _buildQuickActions(),

              SizedBox(height: 30),

              // Recent Activity
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Hola!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: AppColors.grey,
              ),
            ),
            Text(
              'Usuario', // TODO: Reemplazar con nombre real del usuario
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            Text(
              'Es hora de entrenar 💪',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.pastelBlue,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(12),
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
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Calorías',
            '1,247',
            '/ 2,000',
            Icons.local_fire_department,
            AppColors.pastelOrange,
            0.62,
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            'Agua',
            '1.2L',
            '/ 2.5L',
            Icons.water_drop,
            AppColors.pastelBlue,
            0.48,
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            'Pasos',
            '6,547',
            '/ 10,000',
            Icons.directions_walk,
            AppColors.pastelGreen,
            0.65,
          ),
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
      ) {
    return Container(
      padding: EdgeInsets.all(16),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          Text(
            target,
            style: GoogleFonts.poppins(
              fontSize: 10,
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

  Widget _buildQuoteCarousel() {
    return Container(
      height: 120,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.format_quote,
                  color: AppColors.white,
                  size: 24,
                ),
                SizedBox(height: 8),
                Text(
                  quote['quote']!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '- ${quote['author']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
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

  Widget _buildTodaySummary() {
    return Container(
      padding: EdgeInsets.all(20),
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
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Resumen de Hoy',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Entrenamientos', '1', Icons.fitness_center),
              _buildSummaryItem('Tiempo activo', '45min', Icons.timer),
              _buildSummaryItem('Calorías quemadas', '312', Icons.local_fire_department),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.pastelPurple,
          size: 20,
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Entrenar',
                Icons.play_circle_filled,
                AppColors.pastelGreen,
                    () {
                  // TODO: Navegar a ejercicios
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Función de entrenamiento próximamente'),
                      backgroundColor: AppColors.pastelGreen,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: _buildActionButton(
                'Registrar Comida',
                Icons.restaurant,
                AppColors.pastelOrange,
                    () {
                  // TODO: Navegar a nutrición
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Función de nutrición próximamente'),
                      backgroundColor: AppColors.pastelOrange,
                    ),
                  );
                },
              ),
            ),
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
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
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
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad Reciente',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 16),
        _buildActivityItem(
          'Entrenamiento de Pecho',
          '2 horas ago',
          Icons.fitness_center,
          AppColors.pastelBlue,
        ),
        _buildActivityItem(
          'Registraste almuerzo',
          '4 horas ago',
          Icons.restaurant,
          AppColors.pastelOrange,
        ),
        _buildActivityItem(
          'Tomaste progreso',
          'Ayer',
          Icons.camera_alt,
          AppColors.pastelPink,
        ),
      ],
    );
  }

  Widget _buildActivityItem(
      String title,
      String time,
      IconData icon,
      Color color,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}