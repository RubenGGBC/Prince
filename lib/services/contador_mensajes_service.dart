import 'package:shared_preferences/shared_preferences.dart';

class ContadorMensajesService {
  static const String _keyDailyCount = 'daily_message_count';
  static const String _keyLastResetDate = 'last_reset_date';
  static const int _dailyLimit = 20;

  Future<bool> canSendMessage() async {
    final remaining = await getRemainingMessages();
    return remaining > 0;
  }

  Future<void> incrementCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetDaily();
    
    final currentCount = prefs.getInt(_keyDailyCount) ?? 0;
    await prefs.setInt(_keyDailyCount, currentCount + 1);
  }

  Future<int> getRemainingMessages() async {
    await _checkAndResetDaily();
    final prefs = await SharedPreferences.getInstance();
    final usedCount = prefs.getInt(_keyDailyCount) ?? 0;
    return (_dailyLimit - usedCount).clamp(0, _dailyLimit);
  }

  Future<int> getUsedMessages() async {
    await _checkAndResetDaily();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDailyCount) ?? 0;
  }

  Future<void> resetCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyCount, 0);
    await prefs.setString(_keyLastResetDate, DateTime.now().toIso8601String());
  }

  Future<String?> getWarningMessage() async {
    final remaining = await getRemainingMessages();
    
    if (remaining == 0) {
      return 'Has alcanzado el límite diario de mensajes';
    } else if (remaining <= 3) {
      return 'Te quedan $remaining mensajes hoy';
    }
    
    return null;
  }

  Future<void> _checkAndResetDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString(_keyLastResetDate);
    
    if (lastResetStr != null) {
      final lastReset = DateTime.parse(lastResetStr);
      final now = DateTime.now();
      
      // Check if it's a new day
      if (now.difference(lastReset).inDays >= 1) {
        await resetCounter();
      }
    } else {
      // First time, set reset date
      await prefs.setString(_keyLastResetDate, DateTime.now().toIso8601String());
    }
  }
}