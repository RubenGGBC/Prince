import 'package:flutter/material.dart';

class AppColors {
  // Colores principales (manteniendo nombres originales)
  static const Color primaryBlack = Color(0xFF0D1117);     // Negro GitHub dark
  static const Color surfaceBlack = Color(0xFF161B22);     // Negro azulado
  static const Color cardBlack = Color(0xFF21262D);        // Gris oscuro azulado
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF64B5F6);
  static const Color pastelBlue = Color(0xFF81D4FA);

  // COLORES DE FONDO
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2C2C2C);

  // COLORES DE TEXTO
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF424242);

  // COLORES DE ESTADO
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // COLORES PARA ML KIT
  static const Color mlKitActive = Color(0xFF00E676);
  static const Color mlKitInactive = Color(0xFF757575);
  static const Color mlKitError = Color(0xFFFF5722);

  // GRADIENTES
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, darkBlue],
  );
  // "Colores pasteles" (ahora son tonos azules y blancos)
  static const Color pastelPink = Color(0xFF79C0FF);       // Azul claro brillante
  static const Color pastelGreen = Color(0xFFF0F6FF);      // Blanco azulado
  static const Color pastelPurple = Color(0xFF1F6FEB);     // Azul intenso
  static const Color pastelOrange = Color(0xFF388BFD);     // Azul eléctrico

  // Tonos azules adicionales
  static const Color iceBlue = Color(0xFFE6F3FF);          // Azul hielo
  static const Color skyBlue = Color(0xFF87CEEB);          // Azul cielo
  static const Color navyBlue = Color(0xFF1E3A8A);         // Azul marino
  static const Color steelBlue = Color(0xFF4682B4);        // Azul acero
  static const Color royalBlue = Color(0xFF4169E1);        // Azul real

  // Tonos blancos y grises
  static const Color pureWhite = Color(0xFFFFFFFF);        // Blanco puro
  static const Color offWhite = Color(0xFFF8FAFC);         // Blanco cremoso
  static const Color lightGray = Color(0xFFE2E8F0);        // Gris muy claro
  static const Color mediumGray = Color(0xFF64748B);       // Gris medio
  static const Color darkGray = Color(0xFF334155);         // Gris oscuro

  // Colores básicos



  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF79C0FF),    // Azul claro
      Color(0xFFF0F6FF),    // Blanco azulado
      Color(0xFFFFFFFF),    // Blanco puro
    ],
  );

  // Gradiente de fondo profesional
  static const RadialGradient backgroundGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [
      Color(0xFF21262D),    // Centro gris azulado
      Color(0xFF161B22),    // Medio negro azulado
      Color(0xFF0D1117),    // Exterior negro profundo
    ],
  );

  // Gradiente océano
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1E3A8A),    // Azul marino profundo
      Color(0xFF3B82F6),    // Azul medio
      Color(0xFF60A5FA),    // Azul claro
      Color(0xFF93C5FD),    // Azul muy claro
    ],
  );

  // Gradiente hielo
  static const LinearGradient iceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),    // Blanco puro
      Color(0xFFF0F9FF),    // Blanco azul muy claro
      Color(0xFFE0F2FE),    // Azul hielo
      Color(0xFFBAE6FD),    // Azul hielo medio
    ],
  );

  // Gradiente profesional
  static const LinearGradient corporateGradient = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(1.0, 1.0),
    colors: [
      Color(0xFF0F172A),    // Negro azulado
      Color(0xFF1E293B),    // Gris muy oscuro
      Color(0xFF334155),    // Gris oscuro
      Color(0xFF475569),    // Gris medio
    ],
  );

  // Gradiente tecnológico
  static const LinearGradient techGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1F6FEB),    // Azul GitHub
      Color(0xFF388BFD),    // Azul eléctrico
      Color(0xFF58A6FF),    // Azul medio
      Color(0xFF79C0FF),    // Azul claro
      Color(0xFFF0F6FF),    // Blanco azulado
    ],
  );

  // Shimmer azul
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(1.0, 1.0),
    colors: [
      Color(0x00FFFFFF),    // Transparente
      Color(0x4079C0FF),    // Azul claro semi-transparente
      Color(0x00FFFFFF),    // Transparente
    ],
  );

  // Gradiente de cristal
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x40FFFFFF),    // Blanco transparente
      Color(0x2079C0FF),    // Azul transparente
      Color(0x10FFFFFF),    // Blanco muy transparente
    ],
  );

  // Colores de estado en tonos azules
  static const Color successGlow = Color(0xFF58A6FF);      // Azul medio (éxito)
  static const Color warningGlow = Color(0xFF79C0FF);      // Azul claro (advertencia)
  static const Color errorGlow = Color(0xFF1F6FEB);        // Azul intenso (error)
  static const Color infoGlow = Color(0xFFF0F6FF);         // Blanco azulado (info)

  // Función para crear gradientes azules con opacidad
  static LinearGradient createBlueGlowGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.9),
        color.withOpacity(0.5),
        color.withOpacity(0.1),
      ],
    );
  }

  // Función para crear sombras azules elegantes
  static List<BoxShadow> createBlueShadow(Color color) {
    return [
      BoxShadow(
        color: color.withOpacity(0.25),
        blurRadius: 15,
        spreadRadius: 1,
        offset: Offset(0, 4),
      ),
      BoxShadow(
        color: color.withOpacity(0.1),
        blurRadius: 30,
        spreadRadius: 3,
        offset: Offset(0, 8),
      ),
    ];
  }

  // Función para crear efecto de vidrio esmerilado
  static BoxDecoration createGlassEffect() {
    return BoxDecoration(
      gradient: glassGradient,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Color(0x2079C0FF),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0x1058A6FF),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // Función para crear efecto de cristal
  static BoxDecoration createCrystalEffect() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x60FFFFFF),
          Color(0x3079C0FF),
          Color(0x1058A6FF),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Color(0x4079C0FF),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0x2058A6FF),
          blurRadius: 25,
          spreadRadius: 3,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  // ==================== NUEVOS COLORES MODERNOS ====================
  
  // Colores para nutrición (verdes y naranjas modernos)
  static const Color nutritionGreen = Color(0xFF10B981);
  static const Color nutritionLightGreen = Color(0xFF34D399);
  static const Color nutritionOrange = Color(0xFFF59E0B);
  static const Color nutritionLightOrange = Color(0xFFFBBF24);
  
  // Colores para fitness (rojos y morados vibrantes)
  static const Color fitnessRed = Color(0xFFEF4444);
  static const Color fitnessLightRed = Color(0xFFF87171);
  static const Color fitnessPurple = Color(0xFF8B5CF6);
  static const Color fitnessLightPurple = Color(0xFFA78BFA);
  
  // Gradientes modernos para nutrición
  static const LinearGradient nutritionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // Verde esmeralda
      Color(0xFF059669), // Verde más oscuro
      Color(0xFF047857), // Verde profundo
    ],
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B), // Ámbar
      Color(0xFFD97706), // Ámbar oscuro
      Color(0xFFB45309), // Ámbar profundo
    ],
  );
  
  // Gradientes modernos para fitness
  static const LinearGradient fitnessGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444), // Rojo vibrante
      Color(0xFFDC2626), // Rojo más oscuro
      Color(0xFFB91C1C), // Rojo profundo
    ],
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B5CF6), // Violeta
      Color(0xFF7C3AED), // Violeta oscuro
      Color(0xFF6D28D9), // Violeta profundo
    ],
  );
  
  // Gradiente rainbow moderno
  static const LinearGradient rainbowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6366F1), // Índigo
      Color(0xFF8B5CF6), // Violeta
      Color(0xFFEC4899), // Rosa
      Color(0xFFF59E0B), // Ámbar
      Color(0xFF10B981), // Verde esmeralda
    ],
  );
  
  // Gradiente sunset
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFBBF24), // Amarillo dorado
      Color(0xFFF59E0B), // Ámbar
      Color(0xFFEF4444), // Rojo
      Color(0xFFDC2626), // Rojo oscuro
      Color(0xFF7C2D12), // Rojo muy oscuro
    ],
  );
  
  // Gradiente aurora
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF06B6D4), // Cian
      Color(0xFF3B82F6), // Azul
      Color(0xFF8B5CF6), // Violeta
      Color(0xFFEC4899), // Rosa
      Color(0xFF10B981), // Verde
    ],
  );
  
  // Gradiente neon
  static const LinearGradient neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00F5FF), // Cian eléctrico
      Color(0xFF0080FF), // Azul eléctrico
      Color(0xFF8000FF), // Violeta eléctrico
      Color(0xFFFF0080), // Rosa eléctrico
    ],
  );
  
  // Gradiente mint fresh
  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6EE7B7), // Verde menta
      Color(0xFF34D399), // Verde esmeralda claro
      Color(0xFF10B981), // Verde esmeralda
      Color(0xFF059669), // Verde profundo
    ],
  );
  
  // Función para crear gradientes dinámicos
  static LinearGradient createDynamicGradient({
    required List<Color> colors,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
    );
  }
  
  // Función para crear efectos de glassmorphism
  static BoxDecoration createGlassmorphism({
    double opacity = 0.15,
    double blurRadius = 20,
    double borderRadius = 16,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: blurRadius,
          spreadRadius: 2,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
  
  // Función para crear efectos neomorfism
  static BoxDecoration createNeumorphism({
    Color? backgroundColor,
    double borderRadius = 16,
    double blurRadius = 20,
  }) {
    final bgColor = backgroundColor ?? AppColors.surfaceBlack;
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: blurRadius,
          offset: Offset(-8, -8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: blurRadius,
          offset: Offset(8, 8),
        ),
      ],
    );
  }
}