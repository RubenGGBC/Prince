import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'progress_tab.dart';
import 'nutrition_tab.dart';
import '../utils/app_colors.dart';
import '../domain/exercise.dart';
import '../domain/user.dart'; // ✅ IMPORTAR User
import '../database/database_helper.dart';
import 'exercises_tab.dart';
import 'añadir_rutina.dart';
import 'workout_session_screen.dart';
import 'prince_ai_chat_screen.dart';
import 'ml_simple.dart';

class HomeTab extends StatefulWidget {
  // ✅ AGREGAR PARÁMETRO REQUERIDO User
  final User user;

  const HomeTab({
    Key? key,
    required this.user, // ← Usuario requerido desde login
  }) : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // 🔄 PAGEVIEW INTERNO PARA SWIPE HACIA CHAT IA
  final PageController _internalPageController = PageController();
  int _internalPageIndex = 0;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Exercise> _recentExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentExercises();
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

  // ✅ MÉTODO PARA EXTRAER NOMBRE DEL EMAIL
  String _getUserDisplayName() {
    // Si el email es "usuario@example.com", extraer "usuario"
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
  // 📱 PAGEVIEW INTERNO CON USER PROPAGADO A TODAS LAS CLASES
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Stack(
          children: [
            // 📱 PAGEVIEW INTERNO CON USER PROPAGADO A TODAS LAS CLASES
            PageView(
              controller: _internalPageController,
              onPageChanged: (index) {
                setState(() {
                  _internalPageIndex = index;
                });
              },
              children: [
                // 🏠 PÁGINA 0: CONTENIDO DEL HOME
                _buildHomePage(),

                // 🤖 PÁGINA 1: CHAT CON PRINCE IA (CON USER)
                PrinceAIChatScreen(user: widget.user),

                // 📊 PÁGINA 2: PROGRESO (YA TIENE USER)
                ProgressTab(user: widget.user),

                // 🥗 PÁGINA 3: NUTRICIÓN (YA TIENE USER)
                NutritionTab(user: widget.user),

                // 👤 PÁGINA 4: PERFIL (BUILT-IN CON USER)
                _buildProfilePage(),
              ],
            ),

            // 📍 INDICADOR DE PÁGINA
            if (_internalPageIndex == 0)
              Positioned(
                top: 20,
                right: 20,
                child: _buildSwipeIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  // 🏠 PÁGINA PRINCIPAL DEL HOME (SIN BOTÓN DE IA)
  Widget _buildHomePage() {
    return LayoutBuilder(
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

              // ✨ INDICADOR DE SWIPE PARA IA
              _buildSwipeHint(isTablet, isDesktop),
              SizedBox(height: isTablet ? 30 : 20),

              // 📊 Quick Stats Compactas (3 tarjetas)
              _buildQuickStatsCompact(isTablet, isDesktop),
              SizedBox(height: isTablet ? 40 : 30),

              // 🏋️ Management of routines and exercises
              _buildRoutineManagement(isTablet, isDesktop),
              SizedBox(height: isTablet ? 40 : 30),

              // 💪 BOTÓN PRINCIPAL - Start Routine (MANTENER CON GRADIENTE)
              _buildStartWorkoutButton(isTablet, isDesktop),
              SizedBox(height: isTablet ? 40 : 30),

            ],
          ),
        );
      },
    );
  }

  Widget _buildSwipeHint(bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.pastelPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 👑 CORONA AZUL EN LUGAR DE smart_toy
          Container(
            width: isDesktop ? 40 : (isTablet ? 36 : 32),
            height: isDesktop ? 40 : (isTablet ? 36 : 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.pastelBlue, AppColors.pastelPurple],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium, // ← CORONA AZUL
              color: AppColors.white,
              size: isDesktop ? 20 : (isTablet ? 18 : 16),
            ),
          ),

          SizedBox(width: 12),

          // 📝 Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PrinceIA disponible',
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'Desliza hacia la derecha para chatear →',
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),

          // ➡️ Icono de flecha
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.pastelPurple,
            size: isTablet ? 20 : 16,
          ),
        ],
      ),
    );
  }

  // 📍 INDICADOR DE PÁGINA (arriba a la derecha) - CAMBIAR ICONO A CORONA
  Widget _buildSwipeIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBlack.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.pastelPurple.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Punto Home
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _internalPageIndex == 0 ? AppColors.pastelBlue : AppColors.grey,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          // Punto IA
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _internalPageIndex == 1 ? AppColors.pastelPurple : AppColors.grey,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          // Punto Progreso
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _internalPageIndex == 2 ? AppColors.pastelGreen : AppColors.grey,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          // Punto Nutrición
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _internalPageIndex == 3 ? AppColors.pastelOrange : AppColors.grey,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          // Punto Perfil
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _internalPageIndex == 4 ? AppColors.pastelPink : AppColors.grey,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Icon(
            Icons.workspace_premium, // ← CORONA AZUL
            color: AppColors.pastelPurple,
            size: 16,
          ),
        ],
      ),
    );
  }

  // 📱 HEADER - MOSTRAR NOMBRE DEL USUARIO + CORONA
  Widget _buildHeader(bool isTablet, bool isDesktop) {
    //final userName = _capitalizeFirst(_getUserDisplayName());
    final userName = _capitalizeFirst(widget.user.name);

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
              // ✅ MOSTRAR NOMBRE DEL USUARIO
              Text(
                userName,
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

        // 👑 BOTÓN CORONA PARA IR AL CHAT IA
        GestureDetector(
          onTap: () {
            // Ir directamente al chat con IA
            _internalPageController.animateToPage(
              1,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.pastelBlue, AppColors.pastelPurple],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pastelBlue.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.workspace_premium, // ← CORONA AZUL
              color: AppColors.white,
              size: isTablet ? 28 : 24,
            ),
          ),
        ),
      ],
    );
  }

  // 📊 QUICK STATS COMPACTAS (mantener igual)
  Widget _buildQuickStatsCompact(bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildCompactStatCard(
                'Calories',
                '1,247',
                '2,648',
                Icons.local_fire_department,
                AppColors.pastelOrange,
                0.47,
                isTablet,
                isDesktop,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildCompactStatCard(
                'Cardio Active',
                '32',
                '60 min',
                Icons.favorite,
                AppColors.pastelPink,
                0.53,
                isTablet,
                isDesktop,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildCompactStatCard(
                'Steps',
                '6,547',
                '10,000',
                Icons.directions_walk,
                AppColors.pastelGreen,
                0.65,
                isTablet,
                isDesktop,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactStatCard(
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
      height: isDesktop ? 100 : (isTablet ? 90 : 80),
      padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 14 : 12)),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: isDesktop ? 20 : (isTablet ? 18 : 16),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 12 : (isTablet ? 11 : 10),
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 12 : (isTablet ? 11 : 10),
              color: AppColors.grey,
            ),
          ),

          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: isDesktop ? 16 : (isTablet ? 14 : 12),
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
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

  // 🏋️ MANAGEMENT OF ROUTINES AND EXERCISES (mantener igual)
  Widget _buildRoutineManagement(bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management of routines and exercises',
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 20),

        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: isTablet ? 20 : 15,
          mainAxisSpacing: isTablet ? 20 : 15,
          childAspectRatio: isDesktop ? 1.8 : (isTablet ? 1.6 : 1.4),
          children: [
            _buildManagementButton(
              'Create new routine',
              Icons.add_circle_outline,
              AppColors.pastelGreen,
                  () => _navigateToCreateRoutine(),
              isTablet,
              isDesktop,
            ),
            _buildManagementButton(
              'Edit routine',
              Icons.edit_outlined,
              AppColors.pastelPurple,
                  () => _showEditRoutineOptions(),
              isTablet,
              isDesktop,
            ),
            _buildManagementButton(
              'My routines',
              Icons.library_books_outlined,
              AppColors.pastelBlue,
                  () => _showMyRoutines(),
              isTablet,
              isDesktop,
            ),
            _buildManagementButton(
              'Show exercises',
              Icons.fitness_center_outlined,
              AppColors.pastelOrange,
                  () => _navigateToExercises(),
              isTablet,
              isDesktop,
            ),
            _buildManagementButton(
              'ML Kit Simple',
              Icons.camera_alt,
              AppColors.pastelPink,
                  () => _navigateToMLKit(),
              isTablet,
              isDesktop,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementButton(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      bool isTablet,
      bool isDesktop,
      ) {
    LinearGradient buttonGradient = _getButtonGradient(title);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 18 : 16)),
        decoration: BoxDecoration(
          gradient: buttonGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isDesktop ? 50 : (isTablet ? 45 : 40),
              height: isDesktop ? 50 : (isTablet ? 45 : 40),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: AppColors.white,
                size: isDesktop ? 26 : (isTablet ? 24 : 22),
              ),
            ),

            SizedBox(height: 12),

            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
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

  LinearGradient _getButtonGradient(String title) {
    switch (title) {
      case 'Create new routine':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pastelGreen, AppColors.pastelBlue, AppColors.pastelPurple],
        );
      case 'Edit routine':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pastelPurple, AppColors.pastelPink, AppColors.pastelOrange],
        );
      case 'My routines':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pastelBlue, AppColors.pastelGreen, AppColors.pastelPink],
        );
      case 'Show exercises':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pastelOrange, AppColors.pastelPink, AppColors.pastelBlue],
        );
      case 'ML Kit Simple':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pastelPink, AppColors.pastelOrange, AppColors.pastelGreen],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pastelPink, AppColors.pastelPurple, AppColors.pastelBlue],
        );
    }
  }

  // 🚀 BOTÓN PRINCIPAL - Start Routine (mantener igual)
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isDesktop ? 60 : (isTablet ? 50 : 40),
                  height: isDesktop ? 60 : (isTablet ? 50 : 40),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.white,
                    size: isDesktop ? 36 : (isTablet ? 30 : 24),
                  ),
                ),

                SizedBox(width: isTablet ? 20 : 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start routine',
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      'Select your routine and begin',
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 16 : (isTablet ? 14 : 12),
                        color: AppColors.white.withOpacity(0.8),
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

  // 📜 RECENT ACTIVITY (simplificada)
  Widget _buildRecentActivity(bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 16),
        _buildActivityItem('Chest workout completed', '2 hours ago', Icons.fitness_center, AppColors.pastelBlue, isTablet, isDesktop),
        _buildActivityItem('New exercise added', '4 hours ago', Icons.add_circle, AppColors.pastelGreen, isTablet, isDesktop),
        _buildActivityItem('Progress photo taken', 'Yesterday', Icons.camera_alt, AppColors.pastelPink, isTablet, isDesktop),
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
      padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 14 : 12)),
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
              size: isDesktop ? 20 : (isTablet ? 18 : 16),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 12 : (isTablet ? 11 : 10),
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

  // 🧭 MÉTODOS DE NAVEGACIÓN CON USER PROPAGADO
  void _navigateToCreateRoutine() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearRutinaScreen(user: widget.user), // ← PASAR USER
      ),
    );
  }

  void _showEditRoutineOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.edit, color: AppColors.white),
            SizedBox(width: 8),
            Text('Lista de rutinas para editar próximamente'),
          ],
        ),
        backgroundColor: AppColors.pastelPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMyRoutines() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.library_books, color: AppColors.white),
            SizedBox(width: 8),
            Text('Mis rutinas próximamente'),
          ],
        ),
        backgroundColor: AppColors.pastelBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToExercises() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExercisesTab(user: widget.user), // ← PASAR USER
      ),
    );
  }

  void _navigateToMLKit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MLSimple(user: widget.user), // ← PASAR USER
      ),
    );
  }

  void _startWorkoutSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(user: widget.user), // ← PASAR USER
      ),
    );
  }

  // 👤 PÁGINA DE PERFIL
  Widget _buildProfilePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con foto de perfil
          _buildProfileHeader(),

          // Estadísticas rápidas
          _buildProfileQuickStats(),

          // Información personal
          _buildPersonalInfo(),

          // Configuraciones
          _buildSettings(),

          // Opciones adicionales
          _buildAdditionalOptions(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(20),
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
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 20),

          // Foto de perfil
          GestureDetector(
            onTap: () {
              _changeProfilePhoto();
            },
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.2),
                    border: Border.all(
                      color: AppColors.white,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.white,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Nombre y email
          Text(
            widget.user.name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          Text(
            widget.user.email,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.8),
            ),
          ),

          SizedBox(height: 16),

          // Botón editar perfil
          ElevatedButton(
            onPressed: () {
              _editProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primaryBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: Text(
              'Editar Perfil',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileQuickStats() {
    final Map<String, dynamic> _userStats = {
      'totalWorkouts': 48,
      'currentStreak': 5,
      'averageWorkoutTime': 45,
    };

    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Entrenamientos',
              '${_userStats['totalWorkouts']}',
              Icons.fitness_center,
              AppColors.pastelBlue,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Racha actual',
              '${_userStats['currentStreak']} días',
              Icons.local_fire_department,
              AppColors.pastelOrange,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Tiempo promedio',
              '${_userStats['averageWorkoutTime']} min',
              Icons.timer,
              AppColors.pastelGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
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
          Icon(icon, color: color, size: 24),
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
              fontSize: 10,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    final Map<String, dynamic> _userProfile = {
      'age': 25,
      'weight': 75.2,
      'height': 175,
      'gender': 'Masculino',
      'goal': 'Perder peso',
      'activityLevel': 'Moderado',
      'joinDate': '2024-01-15',
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Personal',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 16),

          _buildInfoCard([
            _buildInfoItem('Edad', '${_userProfile['age']} años', Icons.cake),
            _buildInfoItem('Peso', '${_userProfile['weight']} kg', Icons.monitor_weight),
            _buildInfoItem('Altura', '${_userProfile['height']} cm', Icons.height),
            _buildInfoItem('Género', _userProfile['gender'], Icons.person),
          ]),

          SizedBox(height: 16),

          _buildInfoCard([
            _buildInfoItem('Objetivo', _userProfile['goal'], Icons.flag),
            _buildInfoItem('Nivel de actividad', _userProfile['activityLevel'], Icons.directions_run),
            _buildInfoItem('Miembro desde', _formatDate(_userProfile['joinDate']), Icons.calendar_today),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.pastelPurple),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.grey,
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),
      onTap: () {
        _editField(label, value);
      },
    );
  }

  Widget _buildSettings() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSettingItem(
                  'Notificaciones',
                  'Recordatorios de entrenamientos',
                  Icons.notifications,
                  AppColors.pastelBlue,
                      () => _openNotificationSettings(),
                ),
                _buildSettingItem(
                  'Privacidad',
                  'Configuración de datos',
                  Icons.privacy_tip,
                  AppColors.pastelGreen,
                      () => _openPrivacySettings(),
                ),
                _buildSettingItem(
                  'Unidades',
                  'Kg, cm, calorías',
                  Icons.straighten,
                  AppColors.pastelOrange,
                      () => _openUnitsSettings(),
                ),
                _buildSettingItem(
                  'Respaldo',
                  'Sincronizar datos',
                  Icons.backup,
                  AppColors.pastelPurple,
                      () => _openBackupSettings(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.grey,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.grey,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildAdditionalOptions() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Más Opciones',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildActionItem(
                  'Ayuda y Soporte',
                  Icons.help,
                  AppColors.pastelBlue,
                      () => _openHelp(),
                ),
                _buildActionItem(
                  'Acerca de',
                  Icons.info,
                  AppColors.pastelGreen,
                      () => _openAbout(),
                ),
                _buildActionItem(
                  'Calificar App',
                  Icons.star,
                  AppColors.pastelOrange,
                      () => _rateApp(),
                ),
                _buildActionItem(
                  'Cerrar Sesión',
                  Icons.logout,
                  Colors.red,
                      () => _logout(),
                ),
              ],
            ),
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionItem(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.grey,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _changeProfilePhoto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Cambiar Foto',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.pastelBlue),
              title: Text('Tomar foto', style: GoogleFonts.poppins(color: AppColors.white)),
              onTap: () {
                Navigator.pop(context);
                print("Abrir cámara");
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.pastelGreen),
              title: Text('Elegir de galería', style: GoogleFonts.poppins(color: AppColors.white)),
              onTap: () {
                Navigator.pop(context);
                print("Abrir galería");
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pantalla de edición próximamente'),
        backgroundColor: AppColors.pastelBlue,
      ),
    );
  }

  void _editField(String field, String currentValue) {
    print("Editar $field: $currentValue");
  }

  void _openNotificationSettings() {
    print("Configuración de notificaciones");
  }

  void _openPrivacySettings() {
    print("Configuración de privacidad");
  }

  void _openUnitsSettings() {
    print("Configuración de unidades");
  }

  void _openBackupSettings() {
    print("Configuración de respaldo");
  }

  void _openHelp() {
    print("Abrir ayuda");
  }

  void _openAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Prince App',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 60,
              color: AppColors.pastelPink,
            ),
            SizedBox(height: 16),
            Text(
              'Versión 1.0.0',
              style: GoogleFonts.poppins(color: AppColors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tu compañero de fitness completo',
              style: GoogleFonts.poppins(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
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

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Gracias por tu feedback!'),
        backgroundColor: AppColors.pastelOrange,
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Cerrar Sesión',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: GoogleFonts.poppins(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              print("Sesión cerrada");
            },
            child: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _internalPageController.dispose();
    super.dispose();
  }
}