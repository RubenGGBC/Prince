// lib/screens/ai_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../services/voice_coaching_service.dart';
import '../services/smart_notifications_service.dart';
import '../services/ai_form_coach.dart';
import '../widgets/realtime_ml_stats_widget.dart';

/// ⚙️ PANTALLA DE CONFIGURACIÓN AVANZADA IA
class AISettingsScreen extends StatefulWidget {
  @override
  _AISettingsScreenState createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen>
    with TickerProviderStateMixin {

  final VoiceCoachingService _voiceService = VoiceCoachingService();
  final SmartNotificationsService _notificationService = SmartNotificationsService();
  final AIFormCoach _aiCoach = AIFormCoach();

  // Estado de configuraciones
  bool _isLoading = true;
  Map<String, dynamic> _settings = {};

  // Configuraciones ML Kit
  bool _mlKitEnabled = true;
  double _analysisFrequency = 1.0; // veces por segundo
  double _confidenceThreshold = 0.6;
  bool _realTimeCoaching = true;
  bool _postWorkoutAnalysis = true;

  // Configuraciones de voz
  bool _voiceCoachingEnabled = true;
  double _voiceVolume = 0.8;
  double _voiceSpeechRate = 0.6;
  double _voicePitch = 1.0;
  String _voiceLanguage = 'es-ES';

  // Configuraciones de notificaciones
  bool _notificationsEnabled = true;
  bool _workoutReminders = true;
  bool _techniqueNotifications = true;
  bool _motivationalMessages = true;
  bool _progressReports = true;

  // Configuraciones de PrinceIA
  bool _contextualChat = true;
  bool _autoProgressAnalysis = true;
  bool _personalizedTips = true;
  double _aiSensitivity = 0.7; // qué tan sensible es el análisis

  // Animaciones
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSettings();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        // Cargar configuraciones ML Kit
        _mlKitEnabled = prefs.getBool('ml_kit_enabled') ?? true;
        _analysisFrequency = prefs.getDouble('analysis_frequency') ?? 1.0;
        _confidenceThreshold = prefs.getDouble('confidence_threshold') ?? 0.6;
        _realTimeCoaching = prefs.getBool('realtime_coaching') ?? true;
        _postWorkoutAnalysis = prefs.getBool('post_workout_analysis') ?? true;

        // Cargar configuraciones de voz
        _voiceCoachingEnabled = _voiceService.isEnabled;
        _voiceVolume = _voiceService.volume;
        _voiceSpeechRate = _voiceService.speechRate;
        _voicePitch = _voiceService.pitch;
        _voiceLanguage = _voiceService.currentLanguage;

        // Cargar configuraciones de notificaciones
        _notificationsEnabled = _notificationService.isEnabled;
        _workoutReminders = prefs.getBool('workout_reminders') ?? true;
        _techniqueNotifications = prefs.getBool('technique_notifications') ?? true;
        _motivationalMessages = prefs.getBool('motivational_messages') ?? true;
        _progressReports = prefs.getBool('progress_reports') ?? true;

        // Cargar configuraciones de IA
        _contextualChat = prefs.getBool('contextual_chat') ?? true;
        _autoProgressAnalysis = prefs.getBool('auto_progress_analysis') ?? true;
        _personalizedTips = prefs.getBool('personalized_tips') ?? true;
        _aiSensitivity = prefs.getDouble('ai_sensitivity') ?? 0.7;

        _isLoading = false;
      });

      _slideController.forward();

    } catch (e) {
      print('❌ Error cargando configuraciones: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar configuraciones ML Kit
      await prefs.setBool('ml_kit_enabled', _mlKitEnabled);
      await prefs.setDouble('analysis_frequency', _analysisFrequency);
      await prefs.setDouble('confidence_threshold', _confidenceThreshold);
      await prefs.setBool('realtime_coaching', _realTimeCoaching);
      await prefs.setBool('post_workout_analysis', _postWorkoutAnalysis);

      // Guardar configuraciones de voz
      _voiceService.setEnabled(_voiceCoachingEnabled);
      await _voiceService.setVolume(_voiceVolume);
      await _voiceService.setSpeechRate(_voiceSpeechRate);
      await _voiceService.setPitch(_voicePitch);
      await _voiceService.setLanguage(_voiceLanguage);

      // Guardar configuraciones de notificaciones
      await _notificationService.setNotificationsEnabled(_notificationsEnabled);
      await prefs.setBool('workout_reminders', _workoutReminders);
      await prefs.setBool('technique_notifications', _techniqueNotifications);
      await prefs.setBool('motivational_messages', _motivationalMessages);
      await prefs.setBool('progress_reports', _progressReports);

      // Guardar configuraciones de IA
      await prefs.setBool('contextual_chat', _contextualChat);
      await prefs.setBool('auto_progress_analysis', _autoProgressAnalysis);
      await prefs.setBool('personalized_tips', _personalizedTips);
      await prefs.setDouble('ai_sensitivity', _aiSensitivity);

      _showSuccessMessage('Configuración guardada exitosamente');

    } catch (e) {
      print('❌ Error guardando configuraciones: $e');
      _showErrorMessage('Error guardando configuración');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(),
      body: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('🤖 Análisis ML Kit', 'Configuración del análisis de técnica'),
              _buildMLKitSection(),

              SizedBox(height: 32),

              _buildSectionHeader('🎙️ Coaching de Voz', 'Configuración del entrenador virtual'),
              _buildVoiceSection(),

              SizedBox(height: 32),

              _buildSectionHeader('📱 Notificaciones', 'Configuración de alertas y recordatorios'),
              _buildNotificationsSection(),

              SizedBox(height: 32),

              _buildSectionHeader('🧠 PrinceIA', 'Configuración del asistente inteligente'),
              _buildAISection(),

              SizedBox(height: 32),

              _buildActionButtons(),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlack,
        title: Text('Configuración IA', style: GoogleFonts.poppins(color: AppColors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.pastelBlue),
            SizedBox(height: 16),
            Text(
              'Cargando configuración...',
              style: GoogleFonts.poppins(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryBlack,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Configuración IA',
        style: GoogleFonts.poppins(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.restore, color: AppColors.white),
          onPressed: _resetToDefaults,
          tooltip: 'Restaurar valores por defecto',
        ),
        IconButton(
          icon: Icon(Icons.help_outline, color: AppColors.white),
          onPressed: _showHelp,
          tooltip: 'Ayuda',
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: AppColors.grey,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMLKitSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pastelGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Análisis ML Kit',
            'Habilitar análisis de técnica en tiempo real',
            _mlKitEnabled,
                (value) => setState(() => _mlKitEnabled = value),
            Icons.analytics,
            AppColors.pastelGreen,
          ),

          if (_mlKitEnabled) ...[
            SizedBox(height: 20),

            _buildSliderTile(
              'Frecuencia de Análisis',
              'Veces por segundo que se analiza la técnica',
              _analysisFrequency,
              0.5,
              2.0,
              '${_analysisFrequency.toStringAsFixed(1)}x/s',
                  (value) => setState(() => _analysisFrequency = value),
            ),

            SizedBox(height: 16),

            _buildSliderTile(
              'Umbral de Confianza',
              'Nivel mínimo de confianza para mostrar resultados',
              _confidenceThreshold,
              0.3,
              0.9,
              '${(_confidenceThreshold * 100).toInt()}%',
                  (value) => setState(() => _confidenceThreshold = value),
            ),

            SizedBox(height: 16),

            _buildSwitchTile(
              'Coaching en Tiempo Real',
              'Recibir consejos durante el ejercicio',
              _realTimeCoaching,
                  (value) => setState(() => _realTimeCoaching = value),
              Icons.chat_bubble,
              AppColors.pastelBlue,
            ),

            SizedBox(height: 16),

            _buildSwitchTile(
              'Análisis Post-Entrenamiento',
              'Generar reporte detallado al finalizar',
              _postWorkoutAnalysis,
                  (value) => setState(() => _postWorkoutAnalysis = value),
              Icons.assessment,
              AppColors.pastelOrange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pastelBlue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Coaching de Voz',
            'Habilitar instrucciones por voz durante el entrenamiento',
            _voiceCoachingEnabled,
                (value) => setState(() => _voiceCoachingEnabled = value),
            Icons.volume_up,
            AppColors.pastelBlue,
          ),

          if (_voiceCoachingEnabled) ...[
            SizedBox(height: 20),

            _buildSliderTile(
              'Volumen',
              'Nivel de volumen de las instrucciones',
              _voiceVolume,
              0.0,
              1.0,
              '${(_voiceVolume * 100).toInt()}%',
                  (value) => setState(() => _voiceVolume = value),
            ),

            SizedBox(height: 16),

            _buildSliderTile(
              'Velocidad de Habla',
              'Qué tan rápido habla el entrenador',
              _voiceSpeechRate,
              0.3,
              1.0,
              '${(_voiceSpeechRate * 100).toInt()}%',
                  (value) => setState(() => _voiceSpeechRate = value),
            ),

            SizedBox(height: 16),

            _buildSliderTile(
              'Tono de Voz',
              'Grave a agudo de la voz',
              _voicePitch,
              0.5,
              2.0,
              '${_voicePitch.toStringAsFixed(1)}x',
                  (value) => setState(() => _voicePitch = value),
            ),

            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testVoice,
                    icon: Icon(Icons.play_arrow, size: 16),
                    label: Text('Probar Voz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pastelBlue,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pastelOrange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Notificaciones',
            'Habilitar todas las notificaciones de la app',
            _notificationsEnabled,
                (value) => setState(() => _notificationsEnabled = value),
            Icons.notifications,
            AppColors.pastelOrange,
          ),

          if (_notificationsEnabled) ...[
            SizedBox(height: 20),

            _buildSwitchTile(
              'Recordatorios de Entrenamiento',
              'Avisos para mantener la constancia',
              _workoutReminders,
                  (value) => setState(() => _workoutReminders = value),
              Icons.alarm,
              AppColors.pastelGreen,
            ),

            SizedBox(height: 16),

            _buildSwitchTile(
              'Notificaciones de Técnica',
              'Alerts sobre mejoras en la técnica',
              _techniqueNotifications,
                  (value) => setState(() => _techniqueNotifications = value),
              Icons.star,
              AppColors.pastelBlue,
            ),

            SizedBox(height: 16),

            _buildSwitchTile(
              'Mensajes Motivacionales',
              'Frases inspiradoras durante el día',
              _motivationalMessages,
                  (value) => setState(() => _motivationalMessages = value),
              Icons.psychology,
              AppColors.pastelOrange,
            ),

            SizedBox(height: 16),

            _buildSwitchTile(
              'Reportes de Progreso',
              'Resúmenes semanales de tu evolución',
              _progressReports,
                  (value) => setState(() => _progressReports = value),
              Icons.trending_up,
              AppColors.pastelGreen,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAISection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pastelBlue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Chat Contextual',
            'PrinceIA recuerda tu historial de entrenamiento',
            _contextualChat,
                (value) => setState(() => _contextualChat = value),
            Icons.smart_toy,
            AppColors.pastelBlue,
          ),

          SizedBox(height: 16),

          _buildSwitchTile(
            'Análisis Automático de Progreso',
            'Generar insights semanales automáticamente',
            _autoProgressAnalysis,
                (value) => setState(() => _autoProgressAnalysis = value),
            Icons.analytics,
            AppColors.pastelGreen,
          ),

          SizedBox(height: 16),

          _buildSwitchTile(
            'Tips Personalizados',
            'Consejos específicos basados en tu historial',
            _personalizedTips,
                (value) => setState(() => _personalizedTips = value),
            Icons.lightbulb,
            AppColors.pastelOrange,
          ),

          SizedBox(height: 20),

          _buildSliderTile(
            'Sensibilidad de IA',
            'Qué tan detallado es el análisis de PrinceIA',
            _aiSensitivity,
            0.3,
            1.0,
            _aiSensitivity > 0.8 ? 'Alta' : _aiSensitivity > 0.6 ? 'Media' : 'Baja',
                (value) => setState(() => _aiSensitivity = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      bool value,
      Function(bool) onChanged,
      IconData icon,
      Color color,
      ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: AppColors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ],
    );
  }

  Widget _buildSliderTile(
      String title,
      String subtitle,
      double value,
      double min,
      double max,
      String displayValue,
      Function(double) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Text(
              displayValue,
              style: GoogleFonts.poppins(
                color: AppColors.pastelBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: AppColors.pastelBlue,
          inactiveColor: AppColors.surfaceBlack,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: Icon(Icons.save, color: AppColors.white),
            label: Text(
              'Guardar Configuración',
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pastelGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportSettings,
                icon: Icon(Icons.upload, color: AppColors.pastelBlue),
                label: Text(
                  'Exportar',
                  style: GoogleFonts.poppins(color: AppColors.pastelBlue),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.pastelBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(width: 12),

            Expanded(
              child: OutlinedButton.icon(
                onPressed: _importSettings,
                icon: Icon(Icons.download, color: AppColors.pastelOrange),
                label: Text(
                  'Importar',
                  style: GoogleFonts.poppins(color: AppColors.pastelOrange),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.pastelOrange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // MÉTODOS DE ACCIÓN

  void _testVoice() async {
    await _voiceService.testVoice();
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Restaurar Configuración',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres restaurar todos los valores por defecto?',
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
              _performReset();
            },
            child: Text('Restaurar', style: TextStyle(color: AppColors.pastelOrange)),
          ),
        ],
      ),
    );
  }

  void _performReset() {
    setState(() {
      // Valores por defecto ML Kit
      _mlKitEnabled = true;
      _analysisFrequency = 1.0;
      _confidenceThreshold = 0.6;
      _realTimeCoaching = true;
      _postWorkoutAnalysis = true;

      // Valores por defecto de voz
      _voiceCoachingEnabled = true;
      _voiceVolume = 0.8;
      _voiceSpeechRate = 0.6;
      _voicePitch = 1.0;

      // Valores por defecto de notificaciones
      _notificationsEnabled = true;
      _workoutReminders = true;
      _techniqueNotifications = true;
      _motivationalMessages = true;
      _progressReports = true;

      // Valores por defecto de IA
      _contextualChat = true;
      _autoProgressAnalysis = true;
      _personalizedTips = true;
      _aiSensitivity = 0.7;
    });

    _showSuccessMessage('Configuración restaurada a valores por defecto');
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Row(
          children: [
            Icon(Icons.help, color: AppColors.pastelBlue),
            SizedBox(width: 8),
            Text(
              'Ayuda de Configuración',
              style: GoogleFonts.poppins(color: AppColors.white),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem('🤖 ML Kit', 'Controla cómo funciona el análisis de técnica en tiempo real'),
              _buildHelpItem('🎙️ Coaching de Voz', 'Configura las instrucciones habladas durante el entrenamiento'),
              _buildHelpItem('📱 Notificaciones', 'Personaliza qué tipo de avisos quieres recibir'),
              _buildHelpItem('🧠 PrinceIA', 'Ajusta la inteligencia y personalización del asistente'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido', style: TextStyle(color: AppColors.pastelBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            description,
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _exportSettings() {
    // Implementar exportación de configuración
    _showSuccessMessage('Configuración exportada (función en desarrollo)');
  }

  void _importSettings() {
    // Implementar importación de configuración
    _showSuccessMessage('Importación de configuración (función en desarrollo)');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.pastelGreen,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}