import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../domain/user.dart';
import 'home_tab.dart';
import 'exercises_tab.dart';
import 'nutrition_tab.dart';
import 'progress_tab.dart';
import 'profile_tab.dart';

class DashboardScreen extends StatefulWidget {
  final User? user;

  const DashboardScreen({Key? key, this.user}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  List<Widget> get _pages {
    final defaultUser = User(
      email: 'guest@example.com',
      password: '',
      createdAt: DateTime.now(),
      genre: 'Other',
      name: 'Guest',
      weight: 70.0,
      height: 170.0,
      age: 25,
    );

    return [
      HomeTab(user: widget.user ?? defaultUser),
      ExercisesTab(),
      NutritionTab(),
      ProgressTab(user: widget.user ?? defaultUser),
      ProfileTab(),
    ];
  }

  final List<String> _titles = [
    'Inicio',
    'Ejercicios',
    'Nutrición',
    'Progreso',
    'Perfil',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _animationController.forward().then((_) {
      _animationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.pastelBlue,
              unselectedItemColor: AppColors.grey,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.home_outlined, Icons.home, 0),
                  label: _titles[0],
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.fitness_center_outlined, Icons.fitness_center, 1),
                  label: _titles[1],
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.restaurant_outlined, Icons.restaurant, 2),
                  label: _titles[2],
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.trending_up_outlined, Icons.trending_up, 3),
                  label: _titles[3],
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.person_outline, Icons.person, 4),
                  label: _titles[4],
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
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    bool isSelected = _selectedIndex == index;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.pastelBlue.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(
          color: AppColors.pastelBlue.withOpacity(0.3),
          width: 1,
        ) : null,
      ),
      child: Icon(
        isSelected ? filledIcon : outlinedIcon,
        size: 24,
        color: isSelected ? AppColors.pastelBlue : AppColors.grey,
      ),
    );
  }

}
