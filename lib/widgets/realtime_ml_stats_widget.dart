// lib/screens/ai_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../utils/app_colors.dart';
import '../services/ai_form_coach.dart';
import '../services/voice_coaching_service.dart';
import '../services/smart_notifications_service.dart';
import '../domain/user.dart';
import '../widgets/realtime_ml_stats_widget.dart';
import 'ai_progress_analysis_screen.dart';
import 'prince_ai_chat_screen.dart';
import 'workout_session_screen.dart';

/// 🏠 DASHBOARD PRINCIPAL CON MÉTRICAS DE IA
class AIDashboardScreen extends StatefulWidget {
  final User? user;

  const AIDashboardScreen({Key? key, this.user}) : super(key: key);

  @override
  _AIDashboardScreenState createState() => _AIDashboardScreenState();
}

class _AIDashboardScreenState extends State<AIDashboardScreen>
    with TickerProviderStateMixin {

  final AIFormCoach _aiCoach = AIFormCoach();
  final VoiceCoachingService _voiceService = VoiceCoachingService();
  final SmartNotificationsService _notificationService = SmartNotificationsService();

  // Estado del dashboard
  bool _isLoading = true;
  String _todayMotivation = '';
  Map<String, dynamic> _aiStats = {};
  List<QuickAction> _quickActions = [];

  // Animaciones
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Datos de rendimiento
  double _weeklyProgress = 0.0;
  int _totalWorkouts = 0;
  double _averageTechnique = 0.0;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeDashboard();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  Future<void> _initializeDashboard() async {
    try {
      // Inicializar servicios
      await _voiceService.initialize();
      await _notificationService.initialize();

      // Cargar datos del dashboard
      await _loadDashboardData();

      // Configurar acciones rápidas
      _setupQuickActions();

      setState(() => _isLoading = false);

      // Iniciar animaciones
      _slideController.forward();
      _fadeController.forward();

    } catch (e) {
      print('❌ Error inicializando dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      // Obtener análisis de progreso
      final progressAnalysis = await _aiCoach.getProgressAnalysis(7);

      // Simular datos de rendimiento (en una app real, vendrían de la base de datos)
      _weeklyProgress = 0.75; // 75% de progreso semanal
      _totalWorkouts = 12;
      _averageTechnique = 7.8;
      _currentStreak = 5;

      // Motivación del día
      _todayMotivation = _getTodayMotivation();

      // Estadísticas de IA
      _aiStats = {
        'totalAnalyses': 42,
        'improvementRate': 0.23,
        'favoriteExercise': 'Flexiones',
        'weakestArea': 'Consistencia',
        'strongestArea': 'Rango de movimiento',
      };

    } catch (e) {
      print('❌ Error cargando datos: $e');
    }
  }

  void _setupQuickActions() {
    _quickActions = [
      QuickAction(
        title: 'Entrenar con IA',
        subtitle: 'Análisis en tiempo real',
        icon: Icons.fitness_center,
        color: AppColors.pastelGreen,
        onTap: () => _navigateToWorkout(),
      ),
      QuickAction(
        title: 'Chat con PrinceIA',
        subtitle: 'Pregunta sobre técnica',
        icon: Icons.smart_toy,
        color: AppColors.pastelBlue,
        onTap: () => _navigateToChat(),
      ),
      QuickAction(
        title: 'Análisis de Progreso',
        subtitle: 'Ver métricas detalladas',
        icon: Icons.analytics,
        color: AppColors.pastelOrange,
        onTap: () => _navigateToProgress(),
      ),
      QuickAction(
        title: 'Configurar IA',
        subtitle: 'Personalizar experiencia',
        icon: Icons.settings,
        color: AppColors.grey,
        onTap: () => _navigateToSettings(),
      ),
    ];
  }

  String _getTodayMotivation() {
    final motivations = [
      'Hoy es el día perfecto para superar tus límites 🔥',
      'Tu técnica de ayer es el punto de partida de hoy 💪',
      'Cada repetición te acerca a la excelencia ⭐',
      'La consistencia es tu superpoder secreto 🚀',
      'PrinceIA está aquí para impulsar tu progreso 🤖',
    ];

    final index = DateTime.now().day % motivations.length;
    return motivations[index];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          color: AppColors.pastelBlue,
          backgroundColor: AppColors.cardBlack,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(20),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 24),
                    _buildMotivationCard(),
                    SizedBox(height: 24),
                    _buildProgressOverview(),
                    SizedBox(height: 24),
                    _buildAIInsights(),
                    SizedBox(height: 24),
                    _buildQuickActions(),
                    SizedBox(height: 24),
                    _buildRecentActivity(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.pastelBlue, AppColors.pastelGreen],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: AppColors.white, size: 40),
            ),
            SizedBox(height: 24),
            Text(
              '🤖 Preparando tu Dashboard IA',
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Analizando tu progreso y preparando insights',
              style: GoogleFonts.poppins(color: AppColors.grey),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.pastelBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting = 'Buenos días';
    String emoji = '🌅';

    if (hour >= 12 && hour < 18) {
      greeting = 'Buenas tardes';
      emoji = '☀️';
    } else if (hour >= 18) {
      greeting = 'Buenas noches';
      emoji = '🌙';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting ${emoji}',
          style: GoogleFonts.poppins(
            color: AppColors.grey,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 4),
        Text(
          widget.user?.nombre ?? 'Atleta',
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.local_fire_department, color: AppColors.pastelOrange, size: 20),
            SizedBox(width: 6),
            Text(
              'Racha: $_currentStreak días',
              style: GoogleFonts.poppins(
                color: AppColors.pastelOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 16),
            Icon(Icons.star, color: AppColors.pastelGreen, size: 20),
            SizedBox(width: 6),
            Text(
              'Técnica: ${_averageTechnique.toStringAsFixed(1)}/10',
              style: GoogleFonts.poppins(
                color: AppColors.pastelGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.pastelBlue.withOpacity(0.8),
            AppColors.pastelGreen.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppColors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Motivación del Día',
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            _todayMotivation,
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontSize: 18,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBlack),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progreso de Esta Semana',
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),

          // Barra de progreso semanal
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Objetivo Semanal',
                    style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 14),
                  ),
                  Text(
                    '${(_weeklyProgress * 100).toInt()}%',
                    style: GoogleFonts.poppins(
                      color: AppColors.pastelGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: _weeklyProgress,
                backgroundColor: AppColors.surfaceBlack,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.pastelGreen),
                minHeight: 8,
              ),
            ],
          ),

          SizedBox(height: 20),

          // Métricas rápidas
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Entrenamientos',
                  '$_totalWorkouts',
                  Icons.fitness_center,
                  AppColors.pastelBlue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Técnica Promedio',
                  '${_averageTechnique.toStringAsFixed(1)}',
                  Icons.star,
                  AppColors.pastelOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pastelBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppColors.pastelBlue, size: 24),
              SizedBox(width: 8),
              Text(
                'Insights de PrinceIA',
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          _buildInsightRow(
            'Análisis Completados',
            '${_aiStats['totalAnalyses']}',
            Icons.analytics,
          ),

          _buildInsightRow(
            'Mejora Semanal',
            '+${((_aiStats['improvementRate'] as double) * 100).toInt()}%',
            Icons.trending_up,
          ),

          _buildInsightRow(
            'Ejercicio Favorito',
            '${_aiStats['favoriteExercise']}',
            Icons.favorite,
          ),

          _buildInsightRow(
            'Área Fuerte',
            '${_aiStats['strongestArea']}',
            Icons.shield,
          ),

          _buildInsightRow(
            'A Mejorar',
            '${_aiStats['weakestArea']}',
            Icons.flag,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grey, size: 16),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: _quickActions.length,
          itemBuilder: (context, index) {
            final action = _quickActions[index];
            return _buildQuickActionCard(action);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: action.color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            SizedBox(height: 12),
            Text(
              action.title,
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              action.subtitle,
              style: GoogleFonts.poppins(
                color: AppColors.grey,
                fontSize: 11,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Actividad Reciente',
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToProgress(),
              child: Text(
                'Ver todo',
                style: GoogleFonts.poppins(color: AppColors.pastelBlue),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Lista de actividades recientes (simulada)
        ..._buildRecentActivityItems(),
      ],
    );
  }

  List<Widget> _buildRecentActivityItems() {
    final activities = [
      {'type': 'workout', 'title': 'Flexiones analizadas', 'subtitle': 'Técnica: 8.2/10', 'time': 'Hace 2 horas'},
      {'type': 'chat', 'title': 'Pregunta a PrinceIA', 'subtitle': 'Sobre técnica de sentadillas', 'time': 'Ayer'},
      {'type': 'achievement', 'title': 'Logro desbloqueado', 'subtitle': '7 días consecutivos', 'time': 'Hace 3 días'},
    ];

    return activities.map((activity) {
      IconData icon;
      Color color;

      switch (activity['type']) {
        case 'workout':
          icon = Icons.fitness_center;
          color = AppColors.pastelGreen;
          break;
        case 'chat':
          icon = Icons.smart_toy;
          color = AppColors.pastelBlue;
          break;
        case 'achievement':
          icon = Icons.star;
          color = AppColors.pastelOrange;
          break;
        default:
          icon = Icons.circle;
          color = AppColors.grey;
      }

      return Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBlack),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['title']!,
                    style: GoogleFonts.poppins(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    activity['subtitle']!,
                    style: GoogleFonts.poppins(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              activity['time']!,
              style: GoogleFonts.poppins(
                color: AppColors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // NAVEGACIÓN

  void _navigateToWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(user: widget.user),
      ),
    );
  }

  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrinceAIChatScreen(user: widget.user),
      ),
    );
  }

  void _navigateToProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIProgressAnalysisScreen(user: widget.user),
      ),
    );
  }

  void _navigateToSettings() {
    // Implementar navegación a configuración
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Configuración de IA próximamente'),
        backgroundColor: AppColors.pastelBlue,
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
    setState(() {});
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

/// 🎯 MODELO PARA ACCIONES RÁPIDAS
class QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}