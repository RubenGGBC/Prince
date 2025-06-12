import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import 'home_tab.dart';
import 'exercises_tab.dart';
import 'nutrition_tab.dart';
import 'progress_tab.dart';
import 'profile_tab.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeTab(),
    ExercisesTab(),
    NutritionTab(),
    ProgressTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceBlack,
          boxShadow: [
            BoxShadow(
              color: AppColors.pastelBlue.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surfaceBlack,
          selectedItemColor: AppColors.pastelBlue,
          unselectedItemColor: AppColors.grey,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home_outlined, Icons.home, 0),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.fitness_center_outlined, Icons.fitness_center, 1),
              label: 'Ejercicios',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.restaurant_outlined, Icons.restaurant, 2),
              label: 'Nutrición',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.trending_up_outlined, Icons.trending_up, 3),
              label: 'Progreso',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.person_outline, Icons.person, 4),
              label: 'Perfil',
            ),
          ],
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    bool isSelected = _selectedIndex == index;

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.pastelBlue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isSelected ? filledIcon : outlinedIcon,
        size: 24,
        color: isSelected ? AppColors.pastelBlue : AppColors.grey,
      ),
    );
  }
}