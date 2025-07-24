import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../domain/user.dart';
import '../database/database_helper.dart';

/// Pantalla que muestra el progreso del usuario
/// Incluye estadísticas, comparaciones y progreso de ejercicios
class ProgressTab extends StatefulWidget {
  final User user;

  const ProgressTab({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  // ==================== CONSTANTES ====================
  
  static const List<String> _tabTitles = ['Stats', 'Comparación', 'Ejercicios'];
  static const String _motivationalQuote = '"Your body can do it. Your mind is what stops you"';
  static const String _quoteAuthor = '- Prince';
  
  // Constantes de estilos
  static const double _defaultPadding = 20.0;
  static const double _headerPadding = 16.0;
  static const double _cardBorderRadius = 16.0;
  static const double _tabBorderRadius = 12.0;

  // ==================== VARIABLES DE ESTADO ====================
  
  int _selectedTabIndex = 0;
  bool _isLoadingProgress = true;
  List<Map<String, dynamic>> _exerciseProgress = [];
  
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ==================== DATOS ESTÁTICOS ====================
  
  /// Estadísticas principales del usuario
  Map<String, dynamic> get _mainStats => {
    'weight': {
      'current': 84, 
      'previous': 75, 
      'unit': 'kg'
    },
    'training_streak': {
      'current': 8, 
      'unit': 'días'
    },
    'total_training': {
      'current': 81, 
      'unit': 'días'
    },
  };

  // ==================== CICLO DE VIDA ====================

  @override
  void initState() {
    super.initState();
    _loadExerciseProgress();
  }

  // ==================== MÉTODOS DE DATOS ====================

  /// Carga el progreso de ejercicios desde la base de datos
  Future<void> _loadExerciseProgress() async {
    if (!mounted) return;
    
    setState(() => _isLoadingProgress = true);
    
    try {
      final exercises = await _dbHelper.getAllExercises();
      final progressData = _processExerciseData(exercises);
      
      if (mounted) {
        setState(() {
          _exerciseProgress = progressData;
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando progreso de ejercicios: $e');
      
      if (mounted) {
        setState(() {
          _exerciseProgress = _getDefaultExerciseProgress();
          _isLoadingProgress = false;
        });
      }
    }
  }

  /// Procesa los datos de ejercicios para crear estadísticas de progreso
  List<Map<String, dynamic>> _processExerciseData(List<dynamic> exercises) {
    final Map<String, List<Map<String, dynamic>>> exercisesByName = {};
    
    // Agrupar ejercicios por nombre
    for (final exercise in exercises) {
      final name = exercise.nombre;
      if (!exercisesByName.containsKey(name)) {
        exercisesByName[name] = [];
      }
      
      exercisesByName[name]!.add({
        'peso': exercise.peso,
        'fecha': exercise.fechaCreacion,
        'repeticiones': exercise.repeticiones,
        'series': exercise.series,
      });
    }
    
    // Crear datos de progreso
    final List<Map<String, dynamic>> progressData = [];
    
    exercisesByName.forEach((name, records) {
      if (records.isNotEmpty) {
        records.sort((a, b) => a['fecha'].compareTo(b['fecha']));
        
        final weights = records.map<double>((r) => r['peso']).toList();
        final maxWeight = weights.reduce((a, b) => a > b ? a : b);
        
        progressData.add({
          'name': name,
          'first_record': weights.first,
          'last_record': weights.last,
          'pr': maxWeight,
          'unit': 'kg',
          'total_sessions': records.length,
        });
      }
    });
    
    return progressData;
  }

  /// Datos por defecto cuando no hay información en la base de datos
  List<Map<String, dynamic>> _getDefaultExerciseProgress() {
    return [
      _createExerciseRecord('Bench press', 65, 74, 80, 'kg'),
      _createExerciseRecord('Squat', 70, 73, 75, 'kg'),
      _createExerciseRecord('Deadlift', 80, 90, 95, 'kg'),
      _createExerciseRecord('Pull-ups', 5, 8, 12, 'reps'),
    ];
  }

  /// Helper para crear registros de ejercicios
  Map<String, dynamic> _createExerciseRecord(
    String name, 
    num firstRecord, 
    num lastRecord, 
    num pr, 
    String unit
  ) {
    return {
      'name': name,
      'first_record': firstRecord,
      'last_record': lastRecord,
      'pr': pr,
      'unit': unit,
    };
  }

  // ==================== MÉTODOS DE UTILIDAD ====================

  /// Formatea el nombre del usuario
  String get _formattedUserName {
    final name = widget.user.name;
    return name.isNotEmpty 
        ? name[0].toUpperCase() + name.substring(1) 
        : 'Usuario';
  }

  /// Cambia el tab seleccionado
  void _changeTab(int index) {
    setState(() => _selectedTabIndex = index);
  }

  /// Comparte el progreso del usuario
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

  // ==================== MÉTODOS DE CONSTRUCCIÓN DE UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabSelector(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  /// Construye el header con el título y botón de compartir
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(_defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleSection(),
          SizedBox(height: _headerPadding),
          _buildMotivationalQuote(),
        ],
      ),
    );
  }

  /// Construye la sección del título con botón de compartir
  Widget _buildTitleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progreso de $_formattedUserName',
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
        _buildShareButton(),
      ],
    );
  }

  /// Construye el botón de compartir
  Widget _buildShareButton() {
    return IconButton(
      onPressed: _shareProgress,
      icon: Icon(
        Icons.share,
        color: AppColors.pastelPink,
        size: 24,
      ),
    );
  }

  /// Construye la cita motivacional
  Widget _buildMotivationalQuote() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$_motivationalQuote ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          TextSpan(
            text: _quoteAuthor,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.pastelPink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el selector de tabs
  Widget _buildTabSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _defaultPadding),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: Row(
        children: _tabTitles.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          return _buildTabItem(index, title);
        }).toList(),
      ),
    );
  }

  /// Construye un item individual del tab selector
  Widget _buildTabItem(int index, String title) {
    final isSelected = index == _selectedTabIndex;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeTab(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.pastelPink : Colors.transparent,
            borderRadius: BorderRadius.circular(_tabBorderRadius),
          ),
          child: Text(
            title,
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
  }

  /// Construye el contenido del tab seleccionado
  Widget _buildTabContent() {
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

  // ==================== CONTENIDO DE STATS ====================

  /// Construye el contenido de estadísticas
  Widget _buildStatsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_defaultPadding),
      child: Column(
        children: [
          SizedBox(height: _defaultPadding),
          _buildStatsRow(),
          SizedBox(height: _headerPadding),
          _buildTotalTrainingCard(),
        ],
      ),
    );
  }

  /// Construye la fila de estadísticas principales
  Widget _buildStatsRow() {
    return Row(
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
    );
  }

  /// Construye la tarjeta de total entrenado
  Widget _buildTotalTrainingCard() {
    return _buildStatCard(
      title: 'Total entrenado',
      value: '${_mainStats['total_training']['current']}',
      unit: _mainStats['total_training']['unit'],
      subtitle: 'días completados',
      color: AppColors.pastelGreen,
      icon: Icons.fitness_center,
      isWide: true,
    );
  }

  /// Construye una tarjeta de estadística individual
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
      padding: EdgeInsets.all(_defaultPadding),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
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
          _buildStatCardHeader(title, icon, color),
          SizedBox(height: 12),
          _buildStatCardValue(value, unit, color, isWide),
          SizedBox(height: 4),
          _buildStatCardSubtitle(subtitle),
        ],
      ),
    );
  }

  /// Construye el header de una tarjeta de estadística
  Widget _buildStatCardHeader(String title, IconData icon, Color color) {
    return Row(
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
    );
  }

  /// Construye el valor principal de una tarjeta de estadística
  Widget _buildStatCardValue(String value, String unit, Color color, bool isWide) {
    return Row(
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
    );
  }

  /// Construye el subtítulo de una tarjeta de estadística
  Widget _buildStatCardSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: GoogleFonts.poppins(
        fontSize: 12,
        color: AppColors.grey,
      ),
    );
  }

  // ==================== CONTENIDO DE COMPARACIÓN ====================

  /// Construye el contenido de comparación corporal
  Widget _buildComparisonContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComparisonTitle(),
          SizedBox(height: _defaultPadding),
          _buildComparisonCard(),
        ],
      ),
    );
  }

  /// Construye el título de la sección de comparación
  Widget _buildComparisonTitle() {
    return Text(
      'Comparación Corporal',
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }

  /// Construye la tarjeta principal de comparación
  Widget _buildComparisonCard() {
    return Container(
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
        borderRadius: BorderRadius.circular(_defaultPadding),
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
          _buildComparisonCardTitle(),
          SizedBox(height: 30),
          _buildComparisonRow(),
        ],
      ),
    );
  }

  /// Construye el título de la tarjeta de comparación
  Widget _buildComparisonCardTitle() {
    return Text(
      'Comparación de Estadísticas',
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }

  /// Construye la fila de comparación (inicial vs actual)
  Widget _buildComparisonRow() {
    return Row(
      children: [
        Expanded(
          child: _buildComparisonSide(
            title: 'Inicial',
            bodyParts: ['cardio', 'brazos', 'glúteos', 'espalda'],
            isInitial: true,
          ),
        ),
        SizedBox(width: _defaultPadding),
        _buildComparisonVersus(),
        SizedBox(width: _defaultPadding),
        Expanded(
          child: _buildComparisonSide(
            title: 'Actual',
            bodyParts: ['cardio', 'pecho', 'piernas', 'espalda'],
            isInitial: false,
          ),
        ),
      ],
    );
  }

  /// Construye el elemento "VS" entre las comparaciones
  Widget _buildComparisonVersus() {
    return Column(
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
    );
  }

  /// Construye un lado de la comparación (inicial o actual)
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
        SizedBox(height: _headerPadding),
        _buildBodyFigure(bodyParts, isInitial),
      ],
    );
  }

  /// Construye la figura corporal con etiquetas
  Widget _buildBodyFigure(List<String> bodyParts, bool isInitial) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_tabBorderRadius),
      ),
      child: Stack(
        children: [
          _buildHumanFigure(isInitial),
          ..._buildBodyPartLabels(bodyParts),
        ],
      ),
    );
  }

  /// Construye la figura humana simplificada
  Widget _buildHumanFigure(bool isInitial) {
    return Center(
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
          _buildLegs(isInitial),
        ],
      ),
    );
  }

  /// Construye las piernas de la figura
  Widget _buildLegs(bool isInitial) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLeg(isInitial),
        SizedBox(width: 4),
        _buildLeg(isInitial),
      ],
    );
  }

  /// Construye una pierna individual
  Widget _buildLeg(bool isInitial) {
    return Container(
      width: isInitial ? 12 : 15,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Construye las etiquetas de las partes del cuerpo
  List<Widget> _buildBodyPartLabels(List<String> bodyParts) {
    return bodyParts.asMap().entries.map((entry) {
      final index = entry.key;
      final part = entry.value;
      
      return Positioned(
        left: index.isEven ? 10 : null,
        right: index.isOdd ? 10 : null,
        top: 20 + (index * 30.0),
        child: _buildBodyPartLabel(part),
      );
    }).toList();
  }

  /// Construye una etiqueta individual de parte del cuerpo
  Widget _buildBodyPartLabel(String part) {
    return Container(
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
    );
  }

  // ==================== CONTENIDO DE PROGRESO DE EJERCICIOS ====================

  /// Construye el contenido de progreso de ejercicios
  Widget _buildExerciseProgressContent() {
    if (_isLoadingProgress) {
      return _buildLoadingIndicator();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(_defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExerciseProgressTitle(),
          SizedBox(height: _defaultPadding),
          _buildExerciseProgressTable(),
        ],
      ),
    );
  }

  /// Construye el indicador de carga
  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.pastelBlue),
            ),
            SizedBox(height: _headerPadding),
            Text(
              'Cargando progreso...',
              style: GoogleFonts.poppins(
                color: AppColors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el título de la sección de progreso de ejercicios
  Widget _buildExerciseProgressTitle() {
    return Text(
      'Progreso de Ejercicios',
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }

  /// Construye la tabla de progreso de ejercicios
  Widget _buildExerciseProgressTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        border: Border.all(
          color: AppColors.pastelBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          ..._buildTableRows(),
        ],
      ),
    );
  }

  /// Construye el header de la tabla
  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.all(_headerPadding),
      decoration: BoxDecoration(
        color: AppColors.pastelBlue.withOpacity(0.1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(_cardBorderRadius)),
      ),
      child: Row(
        children: [
          _buildTableHeaderCell('Ejercicio', flex: 3),
          _buildTableHeaderCell('Inicial', flex: 2, centered: true),
          _buildTableHeaderCell('Último', flex: 2, centered: true),
          _buildTableHeaderCell('PR', flex: 2, centered: true),
        ],
      ),
    );
  }

  /// Construye una celda del header de la tabla
  Widget _buildTableHeaderCell(String title, {int flex = 1, bool centered = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
    );
  }

  /// Construye las filas de la tabla
  List<Widget> _buildTableRows() {
    return _exerciseProgress.asMap().entries.map((entry) {
      final index = entry.key;
      final exercise = entry.value;
      final isLast = index == _exerciseProgress.length - 1;
      
      return _buildTableRow(exercise, isLast);
    }).toList();
  }

  /// Construye una fila individual de la tabla
  Widget _buildTableRow(Map<String, dynamic> exercise, bool isLast) {
    return Container(
      padding: EdgeInsets.all(_headerPadding),
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
          _buildTableCell(
            exercise['name'], 
            color: AppColors.white, 
            fontWeight: FontWeight.w500,
            flex: 3,
          ),
          _buildTableCell(
            '${exercise['first_record']} ${exercise['unit']}',
            color: AppColors.grey,
            flex: 2,
            centered: true,
          ),
          _buildTableCell(
            '${exercise['last_record']} ${exercise['unit']}',
            color: AppColors.pastelGreen,
            fontWeight: FontWeight.w600,
            flex: 2,
            centered: true,
          ),
          _buildTableCell(
            '${exercise['pr']} ${exercise['unit']}',
            color: AppColors.pastelPink,
            fontWeight: FontWeight.bold,
            flex: 2,
            centered: true,
          ),
        ],
      ),
    );
  }

  /// Construye una celda individual de la tabla
  Widget _buildTableCell(
    String text, {
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
    int flex = 1,
    bool centered = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: color,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}