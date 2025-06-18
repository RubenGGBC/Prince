// lib/services/voice_coaching_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/form_score.dart';
import '../domain/exercise.dart';

/// 🎙️ SERVICIO DE COACHING DE VOZ INTELIGENTE
class VoiceCoachingService {
  static final VoiceCoachingService _instance = VoiceCoachingService._internal();
  factory VoiceCoachingService() => _instance;
  VoiceCoachingService._internal();

  FlutterTts? _flutterTts;
  bool _isEnabled = true;
  bool _isSpeaking = false;
  String _currentLanguage = 'es-ES';
  double _speechRate = 0.6;
  double _volume = 0.8;
  double _pitch = 1.0;

  // 🎯 Control de frecuencia de coaching
  DateTime _lastSpokenTime = DateTime.now();
  String _lastMessage = '';
  static const Duration _minimumInterval = Duration(seconds: 3);

  // 📊 Configuración de coaching por ejercicio
  final Map<String, VoiceCoachingConfig> _exerciseConfigs = {
    'flexiones': VoiceCoachingConfig(
      encouragementInterval: Duration(seconds: 8),
      correctionPhrases: [
        'Mantén el cuerpo recto',
        'Baja más despacio',
        'Codos cerca del cuerpo',
      ],
      motivationPhrases: [
        '¡Excelente forma!',
        '¡Sigue así!',
        '¡Perfecto control!',
      ],
    ),
    'sentadillas': VoiceCoachingConfig(
      encouragementInterval: Duration(seconds: 6),
      correctionPhrases: [
        'Baja más profundo',
        'Peso en los talones',
        'Rodillas alineadas',
      ],
      motivationPhrases: [
        '¡Perfecta profundidad!',
        '¡Gran técnica!',
        '¡Así se hace!',
      ],
    ),
    'press_pecho': VoiceCoachingConfig(
      encouragementInterval: Duration(seconds: 10),
      correctionPhrases: [
        'Control en el descenso',
        'Rango completo',
        'Hombros estables',
      ],
      motivationPhrases: [
        '¡Excelente control!',
        '¡Muy bien!',
        '¡Técnica perfecta!',
      ],
    ),
  };

  /// 🚀 INICIALIZAR SERVICIO TTS
  Future<bool> initialize() async {
    try {
      _flutterTts = FlutterTts();

      // Configurar idioma
      await _flutterTts!.setLanguage(_currentLanguage);
      await _flutterTts!.setSpeechRate(_speechRate);
      await _flutterTts!.setVolume(_volume);
      await _flutterTts!.setPitch(_pitch);

      // Configurar callbacks
      _flutterTts!.setStartHandler(() {
        _isSpeaking = true;
        print('🎙️ TTS iniciado');
      });

      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
        print('🎙️ TTS completado');
      });

      _flutterTts!.setErrorHandler((msg) {
        _isSpeaking = false;
        print('❌ Error TTS: $msg');
      });

      // Verificar disponibilidad de voces
      final voices = await _flutterTts!.getVoices;
      print('🎙️ Voces disponibles: ${voices?.length ?? 0}');

      // Seleccionar voz española si está disponible
      if (voices != null) {
        final spanishVoice = voices.firstWhere(
              (voice) => voice['locale'].contains('es'),
          orElse: () => voices.first,
        );
        await _flutterTts!.setVoice(spanishVoice);
      }

      print('✅ VoiceCoachingService inicializado');
      return true;

    } catch (e) {
      print('❌ Error inicializando TTS: $e');
      return false;
    }
  }

  /// 🗣️ COACHING DURANTE ENTRENAMIENTO
  Future<void> speakCoaching(FormScore score, Exercise exercise) async {
    if (!_isEnabled || _isSpeaking) return;

    // Control de frecuencia
    final now = DateTime.now();
    if (now.difference(_lastSpokenTime) < _minimumInterval) return;

    try {
      final message = _generateCoachingMessage(score, exercise);

      // Evitar repetir el mismo mensaje
      if (message == _lastMessage) return;

      await _speak(message);

      _lastSpokenTime = now;
      _lastMessage = message;

    } catch (e) {
      print('❌ Error en coaching de voz: $e');
    }
  }

  /// 🎯 GENERAR MENSAJE DE COACHING
  String _generateCoachingMessage(FormScore score, Exercise exercise) {
    final exerciseKey = _getExerciseKey(exercise.nombre);
    final config = _exerciseConfigs[exerciseKey] ?? _getDefaultConfig();

    if (!score.isReliable) {
      return 'Ajusta tu posición';
    }

    if (score.score >= 8.5) {
      // Excelente técnica
      return _selectRandomPhrase(config.motivationPhrases);
    } else if (score.score >= 7.0) {
      // Buena técnica, pequeños ajustes
      return 'Muy bien, mantén el control';
    } else if (score.score >= 5.0) {
      // Técnica regular, necesita corrección
      return _selectRandomPhrase(config.correctionPhrases);
    } else {
      // Técnica deficiente
      return 'Vamos más despacio';
    }
  }

  /// 🎲 SELECCIONAR FRASE ALEATORIA
  String _selectRandomPhrase(List<String> phrases) {
    if (phrases.isEmpty) return 'Sigue así';
    final index = DateTime.now().millisecond % phrases.length;
    return phrases[index];
  }

  /// 🏋️ OBTENER CLAVE DE EJERCICIO
  String _getExerciseKey(String exerciseName) {
    final name = exerciseName.toLowerCase();

    if (name.contains('flexion') || name.contains('push')) {
      return 'flexiones';
    } else if (name.contains('sentadilla') || name.contains('squat')) {
      return 'sentadillas';
    } else if (name.contains('press') && name.contains('pecho')) {
      return 'press_pecho';
    } else {
      return 'generic';
    }
  }

  /// ⚙️ CONFIGURACIÓN POR DEFECTO
  VoiceCoachingConfig _getDefaultConfig() {
    return VoiceCoachingConfig(
      encouragementInterval: Duration(seconds: 8),
      correctionPhrases: [
        'Concéntrate en la técnica',
        'Control del movimiento',
        'Respira correctamente',
      ],
      motivationPhrases: [
        '¡Muy bien!',
        '¡Sigue así!',
        '¡Excelente!',
      ],
    );
  }

  /// 🗣️ HABLAR MENSAJE ESPECÍFICO
  Future<void> speak(String message) async {
    if (!_isEnabled) return;
    await _speak(message);
  }

  /// 🔇 HABLAR MENSAJE INTERNO
  Future<void> _speak(String message) async {
    if (_flutterTts == null) return;

    try {
      print('🎙️ Hablando: $message');

      // Detener cualquier speech anterior
      await _flutterTts!.stop();

      // Hablar el mensaje
      await _flutterTts!.speak(message);

    } catch (e) {
      print('❌ Error hablando: $e');
      _isSpeaking = false;
    }
  }

  /// 📢 ANUNCIO DE INICIO DE EJERCICIO
  Future<void> announceExerciseStart(Exercise exercise) async {
    if (!_isEnabled) return;

    final message = 'Iniciando ${exercise.nombre}. Concéntrate en la técnica.';
    await speak(message);
  }

  /// 🏁 ANUNCIO DE FIN DE SET
  Future<void> announceSetCompletion(int reps, double averageScore) async {
    if (!_isEnabled) return;

    String message;
    if (averageScore >= 8.0) {
      message = 'Set completado. ¡Excelente técnica!';
    } else if (averageScore >= 6.0) {
      message = 'Set completado. Buen trabajo.';
    } else {
      message = 'Set completado. Sigue practicando la técnica.';
    }

    if (reps > 0) {
      message += ' $reps repeticiones detectadas.';
    }

    await speak(message);
  }

  /// 🎉 MOTIVACIÓN PERSONALIZADA
  Future<void> speakMotivation(String motivationType) async {
    if (!_isEnabled) return;

    final motivationMessages = {
      'start': [
        '¡Vamos a entrenar!',
        '¡Tú puedes hacerlo!',
        '¡A dar lo mejor de ti!',
      ],
      'mid_workout': [
        '¡Sigue así!',
        '¡Vas muy bien!',
        '¡No te rindas!',
      ],
      'finish': [
        '¡Entrenamiento completado!',
        '¡Excelente trabajo!',
        '¡Lo has logrado!',
      ],
      'rest': [
        'Descansa y prepárate para el siguiente set',
        'Hidratate y respira profundo',
        'Te has ganado este descanso',
      ],
    };

    final messages = motivationMessages[motivationType] ?? ['¡Muy bien!'];
    final message = _selectRandomPhrase(messages);
    await speak(message);
  }

  /// 📊 ESTADÍSTICAS DE VOZ
  Future<void> speakWorkoutStats(Map<String, dynamic> stats) async {
    if (!_isEnabled) return;

    final totalReps = stats['totalReps'] ?? 0;
    final averageScore = stats['averageScore'] ?? 0.0;
    final exercisesCompleted = stats['exercisesCompleted'] ?? 0;

    String message = 'Estadísticas del entrenamiento: ';

    if (exercisesCompleted > 0) {
      message += '$exercisesCompleted ejercicios completados. ';
    }

    if (totalReps > 0) {
      message += '$totalReps repeticiones en total. ';
    }

    if (averageScore > 0) {
      message += 'Técnica promedio: ${averageScore.toStringAsFixed(1)} de 10.';
    }

    await speak(message);
  }

  // 🎛️ CONFIGURACIÓN

  /// ✅ HABILITAR/DESHABILITAR
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled && _isSpeaking) {
      _flutterTts?.stop();
    }
  }

  /// 🔊 CONFIGURAR VOLUMEN
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts?.setVolume(_volume);
  }

  /// ⚡ CONFIGURAR VELOCIDAD
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    await _flutterTts?.setSpeechRate(_speechRate);
  }

  /// 🎵 CONFIGURAR TONO
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _flutterTts?.setPitch(_pitch);
  }

  /// 🌍 CONFIGURAR IDIOMA
  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    await _flutterTts?.setLanguage(_currentLanguage);
  }

  /// 🔇 DETENER SPEECH ACTUAL
  Future<void> stop() async {
    await _flutterTts?.stop();
    _isSpeaking = false;
  }

  /// 🧪 PROBAR CONFIGURACIÓN
  Future<void> testVoice() async {
    await speak('Hola, soy tu entrenador personal virtual. ¿Listo para entrenar?');
  }

  // GETTERS

  bool get isEnabled => _isEnabled;
  bool get isSpeaking => _isSpeaking;
  double get volume => _volume;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String get currentLanguage => _currentLanguage;

  /// 🧹 LIMPIAR RECURSOS
  Future<void> dispose() async {
    await _flutterTts?.stop();
    _flutterTts = null;
    print('🧹 VoiceCoachingService disposed');
  }
}

/// 🎛️ CONFIGURACIÓN DE COACHING POR EJERCICIO
class VoiceCoachingConfig {
  final Duration encouragementInterval;
  final List<String> correctionPhrases;
  final List<String> motivationPhrases;

  VoiceCoachingConfig({
    required this.encouragementInterval,
    required this.correctionPhrases,
    required this.motivationPhrases,
  });
}

/// 🎙️ WIDGET DE CONTROL DE VOZ
class VoiceCoachingWidget extends StatefulWidget {
  final VoiceCoachingService voiceService;
  final Function(bool)? onToggle;

  const VoiceCoachingWidget({
    Key? key,
    required this.voiceService,
    this.onToggle,
  }) : super(key: key);

  @override
  _VoiceCoachingWidgetState createState() => _VoiceCoachingWidgetState();
}

class _VoiceCoachingWidgetState extends State<VoiceCoachingWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.voiceService.isEnabled
            ? Colors.blue.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.voiceService.isEnabled
              ? Colors.blue
              : Colors.grey,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                widget.voiceService.isEnabled
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: widget.voiceService.isEnabled
                    ? Colors.blue
                    : Colors.grey,
              ),
              SizedBox(width: 8),
              Text(
                'Coaching de Voz',
                style: TextStyle(
                  color: widget.voiceService.isEnabled
                      ? Colors.blue
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Switch(
                value: widget.voiceService.isEnabled,
                onChanged: (value) {
                  widget.voiceService.setEnabled(value);
                  widget.onToggle?.call(value);
                  setState(() {});
                },
                activeColor: Colors.blue,
              ),
            ],
          ),

          if (widget.voiceService.isEnabled) ...[
            SizedBox(height: 12),

            // Control de volumen
            Row(
              children: [
                Icon(Icons.volume_down, size: 16, color: Colors.grey),
                Expanded(
                  child: Slider(
                    value: widget.voiceService.volume,
                    onChanged: (value) {
                      widget.voiceService.setVolume(value);
                      setState(() {});
                    },
                    activeColor: Colors.blue,
                  ),
                ),
                Icon(Icons.volume_up, size: 16, color: Colors.grey),
              ],
            ),

            // Control de velocidad
            Row(
              children: [
                Icon(Icons.speed, size: 16, color: Colors.grey),
                Expanded(
                  child: Slider(
                    value: widget.voiceService.speechRate,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (value) {
                      widget.voiceService.setSpeechRate(value);
                      setState(() {});
                    },
                    activeColor: Colors.blue,
                  ),
                ),
                Text('${(widget.voiceService.speechRate * 100).round()}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),

            // Botón de prueba
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.voiceService.isSpeaking
                    ? null
                    : () => widget.voiceService.testVoice(),
                icon: Icon(Icons.play_arrow, size: 16),
                label: Text('Probar Voz', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}