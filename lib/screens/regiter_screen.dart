import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../domain/user.dart';
import '../database/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _dbHelper = DatabaseHelper();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;
  String _selectedGender = 'Masculino';


  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = User(
          email: _emailController.text,
          password: _passwordController.text,
          createdAt: DateTime.now(),
          genre: _selectedGender,
          name: _nameController.text,
          weight: double.tryParse(_weightController.text) ?? 0.0,
          height: double.tryParse(_heightController.text) ?? 0.0,
          age: int.tryParse(_ageController.text) ?? 0,
        );

        await _dbHelper.registerUser(user);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario registrao exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        _showError('Error al registrar: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }


  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBlack,
              AppColors.surfaceBlack,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40),

                        // Back Button
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.white,
                          ),
                        ),

                        SizedBox(height: 20),

                        // Header
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: AppColors.secondaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.pastelPurple.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.person_add,
                                  size: 40,
                                  color: AppColors.white,
                                ),
                              ),

                              SizedBox(height: 24),

                              Text(
                                'Crear nueva cuenta',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),

                              SizedBox(height: 8),

                              Text(
                                'Completa tu información para comenzar',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: AppColors.grey,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40),

                        // Formulario
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Información Personal
                              _buildSectionTitle('Información Personal'),
                              SizedBox(height: 16),

                              _buildTextField(
                                controller: _nameController,
                                label: 'Nombre completo',
                                hint: 'Ingresa tu nombre',
                                icon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu nombre';
                                  }
                                  if (value.length < 2) {
                                    return 'El nombre debe tener al menos 2 caracteres';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 20),

                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'Ingresa tu email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Ingresa un email válido';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 20),

                              _buildTextField(
                                controller: _passwordController,
                                label: 'Contraseña',
                                hint: 'Mínimo 6 caracteres',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa una contraseña';
                                  }
                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 20),

                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirmar contraseña',
                                hint: 'Repite tu contraseña',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                isConfirmPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor confirma tu contraseña';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 30),

                              // Información Fitness
                              _buildSectionTitle('Información Fitness'),
                              SizedBox(height: 16),

                              // Gender Selection
                              _buildGenderSelector(),

                              SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _ageController,
                                      label: 'Edad',
                                      hint: 'Años',
                                      icon: Icons.cake_outlined,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Ingresa tu edad';
                                        }
                                        int? age = int.tryParse(value);
                                        if (age == null || age < 13 || age > 100) {
                                          return 'Edad inválida';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _weightController,
                                      label: 'Peso',
                                      hint: 'kg',
                                      icon: Icons.monitor_weight_outlined,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Ingresa tu peso';
                                        }
                                        double? weight = double.tryParse(value);
                                        if (weight == null || weight < 30.0 || weight > 300.0) {
                                          return 'Peso inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20),

                              _buildTextField(
                                controller: _heightController,
                                label: 'Altura',
                                hint: 'cm',
                                icon: Icons.height,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingresa tu altura';
                                  }
                                  double? height = double.tryParse(value);
                                  if (height == null || height < 100 || height > 250) {
                                    return 'Altura inválida';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 30),

                              // Terms and Conditions
                              _buildTermsCheckbox(),

                              SizedBox(height: 30),

                              // Register Button
                              _buildRegisterButton(),

                              SizedBox(height: 30),

                              // Login Link
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '¿Ya tienes cuenta? ',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Inicia sesión',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.pastelPurple,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    bool isPasswordField = isPassword || isConfirmPassword;
    bool isVisible = isConfirmPassword ? _isConfirmPasswordVisible : _isPasswordVisible;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.pastelPurple.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPasswordField && !isVisible,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(
          color: AppColors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.pastelPurple),
          suffixIcon: isPasswordField
              ? IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: AppColors.grey,
            ),
            onPressed: () {
              setState(() {
                if (isConfirmPassword) {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                } else {
                  _isPasswordVisible = !_isPasswordVisible;
                }
              });
            },
          )
              : null,
          labelStyle: GoogleFonts.poppins(
            color: AppColors.pastelPurple,
            fontSize: 14,
          ),
          hintStyle: GoogleFonts.poppins(
            color: AppColors.grey,
            fontSize: 14,
          ),
          filled: true,
          fillColor: AppColors.cardBlack,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.pastelPurple,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.red.withOpacity(0.7),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.cardBlack,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: 'Género',
          labelStyle: GoogleFonts.poppins(
            color: AppColors.pastelPurple,
            fontSize: 14,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.person, color: AppColors.pastelPurple),
        ),
        dropdownColor: AppColors.cardBlack,
        style: GoogleFonts.poppins(color: AppColors.white),
        items: ['Masculino', 'Femenino', 'Otro'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGender = newValue!;
          });
        },
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          activeColor: AppColors.pastelPurple,
          checkColor: AppColors.white,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: Padding(
              padding: EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    color: AppColors.grey,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(text: 'Acepto los '),
                    TextSpan(
                      text: 'Términos y Condiciones',
                      style: GoogleFonts.poppins(
                        color: AppColors.pastelPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: ' y la '),
                    TextSpan(
                      text: 'Política de Privacidad',
                      style: GoogleFonts.poppins(
                        color: AppColors.pastelPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.secondaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.pastelPurple.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isLoading || !_acceptTerms) ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
        )
            : Text(
          'Crear Cuenta',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  /*void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debes aceptar los términos y condiciones'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Simulación de registro (reemplazaremos con Firebase después)
        await Future.delayed(Duration(seconds: 3));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Cuenta creada exitosamente! Dashboard próximamente'),
            backgroundColor: AppColors.pastelGreen,
          ),
        );

        // TODO: Navegar al dashboard cuando lo creemos
        // Navigator.pushReplacementNamed(context, '/dashboard');

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear cuenta: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }*/
}