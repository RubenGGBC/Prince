import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class ProgressTab extends StatefulWidget {
  @override
  _ProgressTabState createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  // 📝 VARIABLES - Aquí puedes agregar tus datos
  int _selectedTabIndex = 0; // 0: Fotos, 1: Medidas, 2: Estadísticas
  final List<String> _tabs = ['Fotos', 'Medidas', 'Estadísticas'];

  // 📝 DATOS DE PROGRESO - Reemplaza con tu base de datos
  final List<Map<String, dynamic>> _progressPhotos = [
    {
      'date': '2024-01-15',
      'type': 'Frontal',
      'imagePath': 'assets/progress/front_jan.jpg', // Ruta de imagen
      'notes': 'Inicio del programa',
    },
    {
      'date': '2024-02-15',
      'type': 'Lateral',
      'imagePath': 'assets/progress/side_feb.jpg',
      'notes': 'Un mes de progreso',
    },
    {
      'date': '2024-03-15',
      'type': 'Espalda',
      'imagePath': 'assets/progress/back_mar.jpg',
      'notes': 'Definición mejorada',
    },
  ];

  final List<Map<String, dynamic>> _bodyMeasurements = [
    {
      'name': 'Peso',
      'value': 75.2,
      'unit': 'kg',
      'change': -2.3,
      'icon': Icons.monitor_weight,
      'color': AppColors.pastelBlue,
      'history': [77.5, 76.8, 76.2, 75.8, 75.2],
    },
    {
      'name': 'Cintura',
      'value': 82.0,
      'unit': 'cm',
      'change': -3.5,
      'icon': Icons.straighten,
      'color': AppColors.pastelGreen,
      'history': [85.5, 84.2, 83.1, 82.5, 82.0],
    },
    {
      'name': 'Pecho',
      'value': 102.5,
      'unit': 'cm',
      'change': 2.1,
      'icon': Icons.fitness_center,
      'color': AppColors.pastelPink,
      'history': [100.4, 101.1, 101.8, 102.2, 102.5],
    },
    {
      'name': 'Brazos',
      'value': 36.8,
      'unit': 'cm',
      'change': 1.3,
      'icon': Icons.fitness_center,
      'color': AppColors.pastelPurple,
      'history': [35.5, 36.0, 36.3, 36.6, 36.8],
    },
  ];

  final Map<String, List<int>> _weeklyStats = {
    'workouts': [3, 4, 2, 5, 3, 4, 3],
    'calories': [2100, 1950, 2200, 1800, 2050, 1900, 2100],
    'weight': [77, 76, 76, 75, 75, 75, 75],
  };

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
      floatingActionButton: _selectedTabIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          // 🔧 TU LÓGICA: Tomar nueva foto de progreso
          _takeProgressPhoto();
        },
        backgroundColor: AppColors.pastelPink,
        child: Icon(Icons.camera_alt, color: AppColors.white),
      )
          : _selectedTabIndex == 1
          ? FloatingActionButton(
        onPressed: () {
          // 🔧 TU LÓGICA: Agregar nueva medida
          _addMeasurement();
        },
        backgroundColor: AppColors.pastelGreen,
        child: Icon(Icons.add, color: AppColors.white),
      )
          : null,
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
                'Mi Progreso',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Text(
                'Seguimiento de tu transformación',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // 🔧 TU LÓGICA: Exportar progreso o compartir
              _shareProgress();
            },
            icon: Icon(
              Icons.share,
              color: AppColors.pastelPink,
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
                  color: isSelected ? AppColors.pastelPink : Colors.transparent,
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
        return _buildPhotosContent();
      case 1:
        return _buildMeasurementsContent();
      case 2:
        return _buildStatsContent();
      default:
        return _buildPhotosContent();
    }
  }

  Widget _buildPhotosContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comparación antes/después
          _buildBeforeAfterComparison(),

          SizedBox(height: 30),

          // Galería de fotos
          Text(
            'Galería de Progreso',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 16),

          _buildPhotoGrid(),
        ],
      ),
    );
  }

  Widget _buildBeforeAfterComparison() {
    return Container(
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
        children: [
          Text(
            'Transformación',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.white.withOpacity(0.7),
                            ),
                            Text(
                              'ANTES',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enero 2024',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Icon(
                Icons.arrow_forward,
                color: AppColors.white,
                size: 32,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.white.withOpacity(0.7),
                            ),
                            Text(
                              'AHORA',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Marzo 2024',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _progressPhotos.length,
      itemBuilder: (context, index) {
        final photo = _progressPhotos[index];
        return _buildPhotoCard(photo);
      },
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> photo) {
    return GestureDetector(
      onTap: () {
        // 🔧 TU LÓGICA: Ver foto en detalle
        _viewPhotoDetail(photo);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.pastelPink.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlack,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_camera,
                        size: 40,
                        color: AppColors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        photo['type'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo['date'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    photo['notes'],
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
    );
  }

  Widget _buildMeasurementsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medidas Corporales',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 16),

          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _bodyMeasurements.length,
            itemBuilder: (context, index) {
              final measurement = _bodyMeasurements[index];
              return _buildMeasurementCard(measurement);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(Map<String, dynamic> measurement) {
    final isPositiveChange = measurement['change'] > 0;
    final changeColor = measurement['name'] == 'Peso' || measurement['name'] == 'Cintura'
        ? (isPositiveChange ? Colors.red : AppColors.pastelGreen)
        : (isPositiveChange ? AppColors.pastelGreen : Colors.red);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: measurement['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: measurement['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              measurement['icon'],
              color: measurement['color'],
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  measurement['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '${measurement['value']} ${measurement['unit']}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: measurement['color'],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      isPositiveChange ? Icons.arrow_upward : Icons.arrow_downward,
                      color: changeColor,
                      size: 16,
                    ),
                    Text(
                      '${isPositiveChange ? '+' : ''}${measurement['change']} ${measurement['unit']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: changeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' este mes',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // 🔧 TU LÓGICA: Ver historial de medidas
              _viewMeasurementHistory(measurement);
            },
            icon: Icon(
              Icons.timeline,
              color: measurement['color'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas Semanales',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 16),

          _buildStatCard('Entrenamientos', _weeklyStats['workouts']!, 'entrenamientos', Icons.fitness_center, AppColors.pastelBlue),
          _buildStatCard('Calorías promedio', _weeklyStats['calories']!, 'cal', Icons.local_fire_department, AppColors.pastelOrange),
          _buildStatCard('Peso', _weeklyStats['weight']!, 'kg', Icons.monitor_weight, AppColors.pastelGreen),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, List<int> data, String unit, IconData icon, Color color) {
    final average = data.reduce((a, b) => a + b) / data.length;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Promedio: ${average.toStringAsFixed(1)} $unit',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 16),

          // Gráfico simple con barras
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data.asMap().entries.map((entry) {
              int index = entry.key;
              int value = entry.value;
              double height = (value / data.reduce((a, b) => a > b ? a : b)) * 60;

              return Column(
                children: [
                  Container(
                    width: 25,
                    height: height,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    ['L', 'M', 'X', 'J', 'V', 'S', 'D'][index],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 🔧 MÉTODOS PARA TU LÓGICA - Implementa estos métodos con tu lógica de negocio

  void _takeProgressPhoto() {
    // 🔧 TU LÓGICA: Abrir cámara para tomar foto de progreso
    print("Tomar foto de progreso");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Nueva Foto de Progreso',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Text(
          'Aquí integrarías la cámara para tomar fotos',
          style: GoogleFonts.poppins(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              // 🔧 TU LÓGICA: Guardar foto en galería
              Navigator.pop(context);
              print("Guardar foto de progreso");
            },
            child: Text('Tomar Foto', style: TextStyle(color: AppColors.pastelPink)),
          ),
        ],
      ),
    );
  }

  void _addMeasurement() {
    // 🔧 TU LÓGICA: Agregar nueva medida corporal
    print("Agregar nueva medida");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Nueva Medida',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Text(
          'Aquí implementarías formulario para nuevas medidas',
          style: GoogleFonts.poppins(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              // 🔧 TU LÓGICA: Guardar medida en BD
              Navigator.pop(context);
              print("Guardar medida en BD");
            },
            child: Text('Guardar', style: TextStyle(color: AppColors.pastelGreen)),
          ),
        ],
      ),
    );
  }

  void _shareProgress() {
    // 🔧 TU LÓGICA: Compartir progreso
    print("Compartir progreso");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidad de compartir próximamente'),
        backgroundColor: AppColors.pastelPink,
      ),
    );
  }

  void _viewPhotoDetail(Map<String, dynamic> photo) {
    // 🔧 TU LÓGICA: Ver foto en detalle
    print("Ver foto: ${photo['date']}");
  }

  void _viewMeasurementHistory(Map<String, dynamic> measurement) {
    // 🔧 TU LÓGICA: Ver historial de medidas
    print("Ver historial de: ${measurement['name']}");
  }
}