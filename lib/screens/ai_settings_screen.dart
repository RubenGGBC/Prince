// lib/screens/ai_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../services/gemini_service.dart';
import '../services/contador_mensajes_service.dart';

/// ⚙️ PANTALLA DE CONFIGURACIÓN DE CHAT IA
class AISettingsScreen extends StatefulWidget {
  @override
  _AISettingsScreenState createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {

  final GeminiService _geminiService = GeminiService();
  final ContadorMensajesService _counterService = ContadorMensajesService();

  // Estado de configuraciones
  bool _isLoading = true;
  Map<String, dynamic> _settings = {};

  // Configuraciones de Chat IA
  bool _chatEnabled = true;
  int _dailyMessageLimit = 20;
  bool _contextualResponses = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 📥 CARGAR CONFIGURACIONES
  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();

      // Cargar configuraciones de Chat IA
      _chatEnabled = prefs.getBool('chat_enabled') ?? true;
      _dailyMessageLimit = prefs.getInt('daily_message_limit') ?? 20;
      _contextualResponses = prefs.getBool('contextual_responses') ?? true;

      // Cargar estadísticas de mensajes
      final remainingMessages = await _counterService.getRemainingMessages();
      final usedToday = await _counterService.getUsedMessages();
      
      _settings = {
        'remainingMessages': remainingMessages,
        'usedToday': usedToday,
        'totalLimit': _dailyMessageLimit,
      };

      setState(() => _isLoading = false);

    } catch (e) {
      print('❌ Error cargando configuraciones: $e');
      setState(() => _isLoading = false);
      _showError('Error cargando configuraciones');
    }
  }

  /// 💾 GUARDAR CONFIGURACIONES
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar configuraciones de Chat IA
      await prefs.setBool('chat_enabled', _chatEnabled);
      await prefs.setInt('daily_message_limit', _dailyMessageLimit);
      await prefs.setBool('contextual_responses', _contextualResponses);

      _showSuccess('Configuraciones guardadas');

    } catch (e) {
      print('❌ Error guardando configuraciones: $e');
      _showError('Error guardando configuraciones');
    }
  }

  /// 🔄 RESETEAR CONTADOR DE MENSAJES
  Future<void> _resetMessageCounter() async {
    try {
      await _counterService.resetCounter();
      await _loadSettings(); // Recargar para mostrar datos actualizados
      _showSuccess('Contador de mensajes reseteado');
    } catch (e) {
      print('❌ Error reseteando contador: $e');
      _showError('Error reseteando contador');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlack,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '⚙️ Configuración Chat IA',
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: AppColors.pastelBlue),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _buildSettingsList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.pastelBlue),
          SizedBox(height: 16),
          Text(
            'Cargando configuraciones...',
            style: GoogleFonts.poppins(color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estadísticas de uso
          _buildUsageStats(),
          SizedBox(height: 24),

          // Configuraciones de Chat
          _buildChatSection(),
          SizedBox(height: 24),

          // Acciones
          _buildActions(),
        ],
      ),
    );
  }

  /// 📊 ESTADÍSTICAS DE USO
  Widget _buildUsageStats() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.pastelBlue.withOpacity(0.1), AppColors.pastelGreen.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pastelBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat, color: AppColors.pastelBlue),
              SizedBox(width: 12),
              Text(
                'Uso del Chat IA',
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Estadísticas de mensajes
          Row(
            children: [
              Expanded(
                child: _buildQuickStat('Usados Hoy', '${_settings['usedToday'] ?? 0}'),
              ),
              Expanded(
                child: _buildQuickStat('Restantes', '${_settings['remainingMessages'] ?? 0}'),
              ),
              Expanded(
                child: _buildQuickStat('Límite Diario', '${_settings['totalLimit'] ?? 0}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🤖 SECCIÓN CHAT IA
  Widget _buildChatSection() {
    return _buildSection(
      title: '🤖 Configuración del Chat',
      icon: Icons.smart_toy,
      children: [
        _buildSwitchTile(
          title: 'Chat Habilitado',
          subtitle: 'Activar/desactivar el chat con IA',
          value: _chatEnabled,
          onChanged: (value) => setState(() => _chatEnabled = value),
        ),

        _buildSliderTile(
          title: 'Límite Diario de Mensajes',
          subtitle: '$_dailyMessageLimit mensajes por día',
          value: _dailyMessageLimit.toDouble(),
          min: 5.0,
          max: 50.0,
          divisions: 45,
          onChanged: (value) => setState(() => _dailyMessageLimit = value.round()),
        ),

        _buildSwitchTile(
          title: 'Respuestas Contextuales',
          subtitle: 'Usar datos de entrenamiento para respuestas personalizadas',
          value: _contextualResponses,
          onChanged: (value) => setState(() => _contextualResponses = value),
        ),
      ],
    );
  }

  /// ⚡ ACCIONES
  Widget _buildActions() {
    return _buildSection(
      title: '⚡ Acciones',
      icon: Icons.settings_applications,
      children: [
        _buildActionTile(
          title: 'Resetear Contador de Mensajes',
          subtitle: 'Reiniciar el contador diario a 0',
          icon: Icons.refresh,
          onTap: _resetMessageCounter,
        ),

        _buildActionTile(
          title: 'Restablecer Configuración',
          subtitle: 'Volver a la configuración por defecto',
          icon: Icons.restore,
          onTap: _resetToDefaults,
          isDestructive: true,
        ),
      ],
    );
  }

  /// 🔄 RESTABLECER A VALORES POR DEFECTO
  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text('⚠️ Confirmar Reset', style: GoogleFonts.poppins(color: AppColors.white)),
        content: Text(
          '¿Estás seguro de que quieres restablecer la configuración a los valores por defecto?',
          style: GoogleFonts.poppins(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Restablecer', style: TextStyle(color: AppColors.pastelOrange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Restablecer a valores por defecto
        setState(() {
          _chatEnabled = true;
          _dailyMessageLimit = 20;
          _contextualResponses = true;
        });

        await _saveSettings();
        _showSuccess('Configuración restablecida a valores por defecto');

      } catch (e) {
        _showError('Error restableciendo configuración: $e');
      }
    }
  }

  // WIDGETS DE UTILIDAD

  /// 📦 SECCIÓN
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBlack),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlack,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.pastelBlue),
                SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Contenido de la sección
          ...children,
        ],
      ),
    );
  }

  /// 🔘 SWITCH TILE
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.poppins(color: AppColors.white)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.pastelBlue,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// 📝 SLIDER TILE
  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    int? divisions,
  }) {
    return ListTile(
      title: Text(title, style: GoogleFonts.poppins(color: AppColors.white)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12)),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      trailing: Container(
        width: 120,
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: AppColors.pastelBlue,
          inactiveColor: AppColors.surfaceBlack,
        ),
      ),
    );
  }

  /// 🎬 ACTION TILE
  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.pastelOrange : AppColors.pastelBlue,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isDestructive ? AppColors.pastelOrange : AppColors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.grey,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// 📊 ESTADÍSTICA RÁPIDA
  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // MÉTODOS DE UTILIDAD

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.pastelGreen,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}