import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class ProfileTab extends StatefulWidget {
  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // 📝 DATOS DEL USUARIO - Reemplaza con tu base de datos
  final Map<String, dynamic> _userProfile = {
    'name': 'Usuario FitLife',
    'email': 'usuario@fitlife.com',
    'age': 25,
    'weight': 75.2,
    'height': 175,
    'gender': 'Masculino',
    'goal': 'Perder peso',
    'activityLevel': 'Moderado',
    'joinDate': '2024-01-15',
    'profileImage': null, // Ruta de imagen de perfil
  };

  final Map<String, dynamic> _userStats = {
    'totalWorkouts': 48,
    'totalCaloriesBurned': 12450,
    'averageWorkoutTime': 45,
    'favoriteExercise': 'Push-ups',
    'longestStreak': 12,
    'currentStreak': 5,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header con foto de perfil
              _buildProfileHeader(),

              // Estadísticas rápidas
              _buildQuickStats(),

              // Información personal
              _buildPersonalInfo(),

              // Configuraciones
              _buildSettings(),

              // Opciones adicionales
              _buildAdditionalOptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
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
              // 🔧 TU LÓGICA: Cambiar foto de perfil
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
                  child: _userProfile['profileImage'] != null
                      ? ClipOval(
                    child: Image.asset(
                      _userProfile['profileImage'],
                      fit: BoxFit.cover,
                    ),
                  )
                      : Icon(
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
            _userProfile['name'],
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          Text(
            _userProfile['email'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.8),
            ),
          ),

          SizedBox(height: 16),

          // Botón editar perfil
          ElevatedButton(
            onPressed: () {
              // 🔧 TU LÓGICA: Editar perfil
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

  Widget _buildQuickStats() {
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
        // 🔧 TU LÓGICA: Editar campo específico
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

  // 🔧 MÉTODOS PARA TU LÓGICA - Implementa estos métodos con tu lógica de negocio

  void _changeProfilePhoto() {
    // 🔧 TU LÓGICA: Cambiar foto de perfil
    print("Cambiar foto de perfil");

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
                // 🔧 TU LÓGICA: Abrir cámara
                print("Abrir cámara");
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.pastelGreen),
              title: Text('Elegir de galería', style: GoogleFonts.poppins(color: AppColors.white)),
              onTap: () {
                Navigator.pop(context);
                // 🔧 TU LÓGICA: Abrir galería
                print("Abrir galería");
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    // 🔧 TU LÓGICA: Editar perfil completo
    print("Editar perfil");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pantalla de edición próximamente'),
        backgroundColor: AppColors.pastelBlue,
      ),
    );
  }

  void _editField(String field, String currentValue) {
    // 🔧 TU LÓGICA: Editar campo específico
    print("Editar $field: $currentValue");
  }

  void _openNotificationSettings() {
    // 🔧 TU LÓGICA: Configuración de notificaciones
    print("Configuración de notificaciones");
  }

  void _openPrivacySettings() {
    // 🔧 TU LÓGICA: Configuración de privacidad
    print("Configuración de privacidad");
  }

  void _openUnitsSettings() {
    // 🔧 TU LÓGICA: Configuración de unidades
    print("Configuración de unidades");
  }

  void _openBackupSettings() {
    // 🔧 TU LÓGICA: Configuración de respaldo
    print("Configuración de respaldo");
  }

  void _openHelp() {
    // 🔧 TU LÓGICA: Abrir ayuda
    print("Abrir ayuda");
  }

  void _openAbout() {
    // 🔧 TU LÓGICA: Acerca de la app
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'FitLife Pro',
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
    // 🔧 TU LÓGICA: Calificar app en store
    print("Calificar app");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Gracias por tu feedback!'),
        backgroundColor: AppColors.pastelOrange,
      ),
    );
  }

  void _logout() {
    // 🔧 TU LÓGICA: Cerrar sesión
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
              // 🔧 TU LÓGICA: Cerrar sesión y navegar al login
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              print("Sesión cerrada");
            },
            child: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}