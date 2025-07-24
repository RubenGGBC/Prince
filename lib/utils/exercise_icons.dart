import 'package:flutter/material.dart';
import 'app_colors.dart';

class ExerciseIcons {
  // 🎯 ICONOS POR GRUPO MUSCULAR
  static IconData getIconByMuscleGroup(String grupoMuscular) {
    switch (grupoMuscular.toLowerCase()) {
      case 'pecho':
        return Icons.fitness_center; // Barra de pesas para pecho
      case 'espalda':
        return Icons.back_hand; // Mano hacia atrás para espalda
      case 'piernas':
        return Icons.accessibility_new; // Figura humana para piernas
      case 'hombros':
        return Icons.airline_seat_recline_extra; // Figura reclinada para hombros
      case 'brazos':
        return Icons.sports_martial_arts; // Artes marciales para brazos
      case 'cardio':
        return Icons.directions_run; // Corriendo para cardio
      case 'abdomen':
        return Icons.fitness_center; // Pesas para abdomen
      case 'core':
        return Icons.circle_outlined; // Círculo para core
      default:
        return Icons.fitness_center; // Icono por defecto
    }
  }

  // 🎨 COLORES POR GRUPO MUSCULAR
  static Color getColorByMuscleGroup(String grupoMuscular) {
    switch (grupoMuscular.toLowerCase()) {
      case 'pecho':
        return AppColors.pastelPink; // Rosa para pecho
      case 'espalda':
        return AppColors.pastelGreen; // Verde para espalda
      case 'piernas':
        return AppColors.pastelBlue; // Azul para piernas
      case 'hombros':
        return AppColors.pastelPurple; // Púrpura para hombros
      case 'brazos':
        return AppColors.pastelOrange; // Naranja para brazos
      case 'cardio':
        return Colors.red; // Rojo para cardio
      case 'abdomen':
        return AppColors.pastelGreen; // Verde para abdomen
      case 'core':
        return AppColors.pastelPurple; // Púrpura para core
      default:
        return AppColors.grey; // Gris por defecto
    }
  }

  // 🏋️ ICONOS ESPECÍFICOS POR EJERCICIO
  static IconData getIconByExerciseName(String nombreEjercicio) {
    final nombre = nombreEjercicio.toLowerCase();

    // Ejercicios de pecho
    if (nombre.contains('press') && nombre.contains('banca')) {
      return Icons.fitness_center;
    } else if (nombre.contains('flexiones') || nombre.contains('push')) {
      return Icons.sports_gymnastics;
    } else if (nombre.contains('aperturas')) {
      return Icons.open_in_full;
    }

    // Ejercicios de espalda
    else if (nombre.contains('dominadas') || nombre.contains('pull')) {
      return Icons.sports_gymnastics;
    } else if (nombre.contains('remo')) {
      return Icons.rowing;
    } else if (nombre.contains('peso muerto') || nombre.contains('deadlift')) {
      return Icons.fitness_center;
    } else if (nombre.contains('jalones')) {
      return Icons.vertical_align_bottom;
    }

    // Ejercicios de piernas
    else if (nombre.contains('sentadillas') || nombre.contains('squat')) {
      return Icons.airline_seat_recline_normal;
    } else if (nombre.contains('prensa')) {
      return Icons.fitness_center;
    } else if (nombre.contains('zancadas') || nombre.contains('lunge')) {
      return Icons.directions_walk;
    } else if (nombre.contains('extensiones')) {
      return Icons.straighten;
    } else if (nombre.contains('curl') && nombre.contains('femoral')) {
      return Icons.fitness_center;
    }

    // Ejercicios de hombros
    else if (nombre.contains('press') && nombre.contains('militar')) {
      return Icons.fitness_center;
    } else if (nombre.contains('elevaciones')) {
      return Icons.arrow_upward;
    } else if (nombre.contains('pájaros') || nombre.contains('pajaros')) {
      return Icons.open_in_full;
    }

    // Ejercicios de brazos
    else if (nombre.contains('curl')) {
      return Icons.sports_martial_arts;
    } else if (nombre.contains('tríceps') || nombre.contains('francés')) {
      return Icons.fitness_center;
    } else if (nombre.contains('fondos')) {
      return Icons.sports_gymnastics;
    }

    // Ejercicios de cardio
    else if (nombre.contains('burpees')) {
      return Icons.sports_gymnastics;
    } else if (nombre.contains('mountain')) {
      return Icons.terrain;
    } else if (nombre.contains('jumping')) {
      return Icons.sports_gymnastics;
    } else if (nombre.contains('running') || nombre.contains('correr')) {
      return Icons.directions_run;
    }

    // Por defecto, usar el icono del grupo muscular
    else {
      return Icons.fitness_center;
    }
  }

  // 🏆 ICONOS POR CATEGORÍA DE RUTINA
  static IconData getIconByCategory(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'fuerza':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'funcional':
        return Icons.sports_gymnastics;
      case 'principiante':
        return Icons.school;
      case 'avanzado':
        return Icons.star;
      case 'hiit':
        return Icons.local_fire_department;
      case 'yoga':
        return Icons.self_improvement;
      case 'pilates':
        return Icons.spa;
      default:
        return Icons.fitness_center;
    }
  }

  // 🎨 COLORES POR CATEGORÍA
  static Color getColorByCategory(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'fuerza':
        return AppColors.pastelBlue;
      case 'cardio':
        return Colors.red;
      case 'funcional':
        return AppColors.pastelGreen;
      case 'principiante':
        return AppColors.pastelOrange;
      case 'avanzado':
        return AppColors.pastelPurple;
      case 'hiit':
        return Colors.orange;
      case 'yoga':
        return AppColors.pastelGreen;
      case 'pilates':
        return AppColors.pastelPink;
      default:
        return AppColors.grey;
    }
  }

  // 💎 CREAR WIDGET DE ICONO CON ESTILO
  static Widget buildStyledIcon({
    required String grupoMuscular,
    String? nombreEjercicio,
    double size = 24,
    bool useSpecificIcon = true,
  }) {
    final IconData icon = useSpecificIcon && nombreEjercicio != null
        ? getIconByExerciseName(nombreEjercicio)
        : getIconByMuscleGroup(grupoMuscular);

    final Color color = getColorByMuscleGroup(grupoMuscular);

    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }

  // 🔥 CREAR BADGE CON ICONO Y TEXTO
  static Widget buildCategoryBadge({
    required String categoria,
    double fontSize = 12,
  }) {
    final icon = getIconByCategory(categoria);
    final color = getColorByCategory(categoria);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: color),
          SizedBox(width: 4),
          Text(
            categoria,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 📊 ICONOS PARA ESTADÍSTICAS
  static const Map<String, IconData> statsIcons = {
    'series': Icons.repeat,
    'repeticiones': Icons.numbers,
    'peso': Icons.monitor_weight,
    'tiempo': Icons.timer,
    'volumen': Icons.bar_chart,
    'calorias': Icons.local_fire_department,
    'frecuencia': Icons.calendar_today,
    'progreso': Icons.trending_up,
  };

  // 🎯 ICONOS PARA ACCIONES
  static const Map<String, IconData> actionIcons = {
    'play': Icons.play_circle_filled,
    'pause': Icons.pause_circle_filled,
    'stop': Icons.stop_circle,
    'edit': Icons.edit,
    'delete': Icons.delete,
    'add': Icons.add_circle,
    'info': Icons.info_outline,
    'share': Icons.share,
    'favorite': Icons.favorite,
    'timer': Icons.timer,
    'check': Icons.check_circle,
  };

  // 🚀 MÉTODO PARA OBTENER ICONO DE ACCIÓN
  static IconData getActionIcon(String action) {
    return actionIcons[action] ?? Icons.help_outline;
  }

  // 📈 MÉTODO PARA OBTENER ICONO DE ESTADÍSTICA
  static IconData getStatsIcon(String stat) {
    return statsIcons[stat] ?? Icons.analytics;
  }
}