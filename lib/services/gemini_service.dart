import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyAbcsyqxzJH9cCeykckik9T-sQt0IkqvvQ';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  static const String _systemPrompt = '''
Eres PrinceIA, un entrenador personal virtual especializado en fitness y bienestar.

PERSONALIDAD:
- Motivador y empático
- Experto en ejercicios, nutrición y bienestar
- Respuestas claras y accionables
- Usa emojis ocasionalmente

ESPECIALIDADES:
- Rutinas de ejercicios personalizadas
- Consejos de nutrición deportiva
- Técnicas de ejercicios
- Motivación y mindset
- Prevención de lesiones
- Planes de entrenamiento

INSTRUCCIONES:
- Responde en español siempre
- Mantén respuestas concisas (máximo 200 palabras)
- Si no es relacionado con fitness, redirige amablemente al tema
- Siempre incluye consejos prácticos
- Pregunta por el nivel del usuario si es relevante

EJEMPLO DE RESPUESTA:
Usuario: "¿Cómo hacer flexiones correctamente?"
PrinceIA: "🔥 ¡Perfecto! Las flexiones son fundamentales. Aquí está la técnica:

**Posición inicial:**
- Manos alineadas con los hombros
- Cuerpo recto como tabla
- Core activado

**Movimiento:**
- Baja controlado (2-3 segundos)
- Pecho casi toca el suelo
- Sube explosivo pero controlado

**Tip clave:** Si eres principiante, empieza con flexiones de rodillas.

¿Cuál es tu nivel actual? Así te doy una progresión específica 💪"
''';

  Future<String> sendMessage(String userMessage) async {
    try {
      print('🤖 Enviando mensaje a Gemini: $userMessage');

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '$_systemPrompt\n\nUsuario: $userMessage'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 300,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );


      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {

          final candidate = responseData['candidates'][0];
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {

            final aiResponse = candidate['content']['parts'][0]['text'];
            return aiResponse;
          }
        }

        return _getErrorMessage('La IA no pudo generar una respuesta');

      } else {

        if (response.statusCode == 401) {
          return _getErrorMessage('API Key inválida');
        } else if (response.statusCode == 429) {
          return _getErrorMessage('Límite de peticiones excedido');
        } else {
          return _getErrorMessage('Error del servidor (${response.statusCode})');
        }
      }

    } catch (e) {
      return _getErrorMessage('Error de conexión. Verifica tu internet.');
    }
  }

  String _getErrorMessage(String technicalError) {
    return '''
🤖 **PrinceIA dice:**

Lo siento, tengo problemas técnicos en este momento 😅

**Error:** $technicalError

**Mientras tanto, aquí tienes un consejo:**
💪 Recuerda: La constancia es más importante que la perfección. Incluso 10 minutos de ejercicio diario marcan la diferencia.

¡Inténtalo de nuevo en un momento!
    ''';
  }

  Future<bool> testConnection() async {
    try {
      final response = await sendMessage('Hola, ¿funcionas correctamente?');
      return !response.contains('Error');
    } catch (e) {
      return false;
    }
  }
}