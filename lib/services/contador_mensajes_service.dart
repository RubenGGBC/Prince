import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MessageCounterService {
  static const String _messageCountKey = 'daily_message_count';
  static const String _lastUsageDateKey = 'last_usage_date';
  static const int _dailyLimit = 16;

  static final MessageCounterService _instance = MessageCounterService._internal();
  factory MessageCounterService() => _instance;
  MessageCounterService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    print('📊 MessageCounterService inicializado');
  }

  String _getCurrentDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _checkAndResetIfNewDay() async {
    await initialize();

    final today = _getCurrentDate();
    final lastUsageDate = _prefs!.getString(_lastUsageDateKey);

    print('📅 Fecha hoy: $today');
    print('📅 Última fecha de uso: $lastUsageDate');

    if (lastUsageDate != today) {
      await _prefs!.setInt(_messageCountKey, 0);
      await _prefs!.setString(_lastUsageDateKey, today);
      print('🔄 Contador reseteado para nuevo día');
    }
  }

  Future<int> getCurrentCount() async {
    await _checkAndResetIfNewDay();
    final count = _prefs!.getInt(_messageCountKey) ?? 0;
    print('📊 Contador actual: $count');
    return count;
  }

  Future<int> getRemainingMessages() async {
    final current = await getCurrentCount();
    final remaining = _dailyLimit - current;
    print('📉 Mensajes restantes: $remaining');
    return remaining > 0 ? remaining : 0;
  }

  // ✅ Verificar si puede enviar más mensajes
  Future<bool> canSendMessage() async {
    final remaining = await getRemainingMessages();
    return remaining > 0;
  }

  Future<bool> incrementCounter() async {
    if (await canSendMessage()) {
      await _checkAndResetIfNewDay();
      final currentCount = await getCurrentCount();
      final newCount = currentCount + 1;

      await _prefs!.setInt(_messageCountKey, newCount);
      print('➕ Contador incrementado a: $newCount');
      return true;
    }

    print('❌ No se puede incrementar: límite alcanzado');
    return false;
  }

  Future<Map<String, dynamic>> getStats() async {
    final current = await getCurrentCount();
    final remaining = await getRemainingMessages();
    final canSend = await canSendMessage();

    return {
      'currentCount': current,
      'remainingMessages': remaining,
      'dailyLimit': _dailyLimit,
      'canSendMessage': canSend,
      'date': _getCurrentDate(),
      'limitReached': current >= _dailyLimit,
    };
  }

  // 🔄 Método para resetear manualmente (útil para testing)
  Future<void> resetCounterManually() async {
    await initialize();
    await _prefs!.setInt(_messageCountKey, 0);
    await _prefs!.setString(_lastUsageDateKey, _getCurrentDate());
    print('🔄 Contador reseteado manualmente');
  }

  // 📈 Obtener progreso como porcentaje
  Future<double> getUsageProgress() async {
    final current = await getCurrentCount();
    return (current / _dailyLimit).clamp(0.0, 1.0);
  }

  // 🎯 Obtener mensaje de estado
  Future<String> getStatusMessage() async {
    final stats = await getStats();
    final remaining = stats['remainingMessages'] as int;
    final current = stats['currentCount'] as int;

    if (remaining == 0) {
      return '❌ Sin mensajes restantes hoy';
    } else if (remaining == 1) {
      return '⚠️ Último mensaje del día';
    } else if (current == 0) {
      return '✅ 5 mensajes disponibles hoy';
    } else {
      return '📝 $remaining mensajes restantes';
    }
  }

  // 🔔 Obtener notificación de advertencia si quedan pocos mensajes
  Future<String?> getWarningMessage() async {
    final remaining = await getRemainingMessages();

    if (remaining == 1) {
      return '⚠️ ¡Cuidado! Este es tu último mensaje de hoy';
    } else if (remaining == 2) {
      return '🔔 Solo te quedan 2 mensajes para hoy';
    }

    return null;
  }

  Future<String> getMotivationalMessage() async {
    final current = await getCurrentCount();

    switch (current) {
      case 0:
        return '🌟 ¡Perfecto! Tienes todo el día para conversar con PrinceIA';
      case 1:
        return '💪 ¡Buen comienzo! Te quedan 4 mensajes más';
      case 2:
        return '🔥 ¡Siguiendo fuerte! 3 mensajes restantes';
      case 3:
        return '⚡ ¡Casi llegando! 2 mensajes más';
      case 4:
        return '🎯 ¡Último mensaje! Hazlo contar';
      case 5:
        return '🏆 ¡Has usado todos tus mensajes! Vuelve mañana para más consejos';
      default:
        return '🤖 PrinceIA está listo para ayudarte';
    }
  }
}