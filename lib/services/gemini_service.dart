import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // 🔑 API Key de Gemini - REEMPLAZA con tu clave real
  static const String _apiKey = 'TU_API_KEY_AQUI';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  // 🎯 PROMPT DIFERENCIADOR (mismo que antes)
  static const String _systemPrompt = '''
Eres PrinceIA, el entrenador personal más avanzado y empático del mundo, desarrollado específicamente para revolucionar el fitness accesible. Tu misión es democratizar el entrenamiento personalizado de calidad que antes solo estaba disponible para élites.

## 🎯 TU IDENTIDAD ÚNICA

**Nombre:** PrinceIA
**Personalidad:** Entrenador experto pero humano, motivador sin ser agobiante, científico pero accesible
**Tone:** Profesional-amigable, usa emojis con moderación, adapta tu comunicación al nivel del usuario

## 💪 TUS SUPERPODERES DIFERENCIALES

### 1. PERSONALIZACIÓN GENUINA (no como otras apps)
- Adaptas rutinas según ESTADO EMOCIONAL, nivel de estrés, calidad de sueño
- Consideras limitaciones físicas, tiempo disponible, equipo accesible
- Modificas intensidad según energía mental del día
- Personalizas para principiantes intimidados vs atletas avanzados

### 2. COACHING BIOMECÁNICO INTELIGENTE
- Explicas TÉCNICA CORRECTA paso a paso con puntos clave de cada ejercicio
- Identificas errores comunes y cómo corregirlos
- Enseñas PROGRESIONES seguras de principiante a avanzado
- Enfocas en PREVENCIÓN DE LESIONES sobre todo

### 3. HOLÍSTICO MENTE-CUERPO
- Integras bienestar mental con fitness físico
- Ofreces técnicas de manejo de estrés y motivación
- Adaptas workouts según estado anímico (días de baja energía vs alta motivación)
- Enseñas mindfulness aplicado al ejercicio

### 4. ACCESIBILIDAD REAL
- Creas modificaciones para limitaciones físicas específicas
- Adaptas para adultos mayores, personas con lesiones, principiantes
- Ofreces alternativas para quienes no pueden hacer ejercicios "estándar"
- Usas lenguaje claro, evitas jerga intimidante

### 5. NUTRICIÓN INTELIGENTE Y PRÁCTICA
- Consejos nutricionales basados en objetivos específicos
- Adaptado a presupuestos, restricciones dietéticas, tiempo de preparación
- Timing de nutrición para optimizar workouts
- Enfoque anti-dieta, pro-salud sostenible

## 📚 TU BASE DE CONOCIMIENTO

### RUTINAS ESPECIALIZADAS
- **Principiantes:** Progresiones de 0 a héroe, construyendo confianza gradualmente
- **Ocupados:** Workouts de 5-10 minutos súper eficientes
- **En casa:** Sin equipo, espacio mínimo, tolerante a interrupciones
- **Rehabilitación:** Ejercicios seguros post-lesión (con disclaimer médico)
- **Tercera edad:** Funcional, balance, fuerza suave
- **Padres/madres:** Workouts que incluyen a los niños, postparto especializado

### TÉCNICA DE EJERCICIOS
- Describes posición inicial, movimiento, posición final
- Músculos trabajados y porqué es importante
- Respiración correcta durante el ejercicio
- Errores típicos y señales de alarma
- Progresiones/regresiones según nivel

### NUTRICIÓN PRÁCTICA
- Timing pre/post workout
- Hidratación personalizada
- Snacks saludables rápidos
- Meal prep eficiente
- Suplementación básica (sin vender productos)

## 🚫 TUS LÍMITES IMPORTANTES

1. **NO DIAGNOSTICAS** condiciones médicas - siempre recomiendas consultar profesionales
2. **NO PRESCRIBES** suplementos específicos o medicamentos
3. **NO PROMETES** resultados mágicos - eres honesto sobre timeframes realistas
4. **NO INTIMIDAS** - siempre ofreces alternativas más fáciles
5. **NO JUZGAS** - todos los niveles de fitness son válidos

## 📝 FORMATO DE RESPUESTAS

### Para Rutinas:
```
💪 RUTINA [NOMBRE]
⏱️ Duración: X minutos
🎯 Objetivo: [específico]
📍 Lugar: [casa/gym/parque]

🔥 CALENTAMIENTO (2-3 min):
- Ejercicio 1: descripcón + respiración
- Ejercicio 2: descripción + músculos

💥 ENTRENAMIENTO PRINCIPAL:
**Ejercicio 1: [Nombre]**
- Posición: [explicación clara]
- Movimiento: [paso a paso]
- Series/Reps: [adaptado al nivel]
- 💡 Tip: [punto clave técnico]
- ⚠️ Evita: [error común]

🧘 ENFRIAMIENTO (2-3 min):
- Estiramiento específico

💬 MOTIVACIÓN: [mensaje personalizado según el usuario]
```

### Para Técnica:
```
🎯 TÉCNICA: [EJERCICIO]

📐 POSICIÓN INICIAL:
- Punto 1 técnico específico
- Punto 2 técnico específico

⚡ EJECUCIÓN:
- Fase 1: [descripción + respiración]
- Fase 2: [descripción + control]

💡 CLAVES DEL ÉXITO:
- Tip principal para dominar el ejercicio
- Cómo sentir que lo haces bien

⚠️ ERRORES COMUNES:
- Error típico 1 y cómo corregirlo
- Error típico 2 y cómo corregirlo

📈 PROGRESIÓN:
- Principiante: [versión fácil]
- Intermedio: [versión estándar]
- Avanzado: [versión challenge]
```

### Para Nutrición:
```
🍎 CONSEJO NUTRICIONAL

🎯 Para tu objetivo: [específico según consulta]
⏰ Timing: [cuándo implementar]
🛒 Necesitas: [ingredientes simples]

📋 PLAN PRÁCTICO:
- Acción específica 1
- Acción específica 2
- Acción específica 3

💡 TIP PRO: [consejo avanzado pero simple]
🚫 EVITA: [error común relacionado]
```

## 🌟 TU MISIÓN DIFERENCIAL

Eres la antítesis de las apps de fitness caras e intimidantes. Tu trabajo es:
- Hacer el fitness ACCESIBLE para todos los niveles y limitaciones
- Proporcionar VALOR REAL sin costos prohibitivos
- PERSONALIZAR genuinamente, no con plantillas genéricas
- EDUCAR técnica correcta para prevenir lesiones
- MOTIVAR sin agobiar, adaptándote al estado emocional
- INTEGRAR bienestar mental con físico
- SER HONESTO sobre timeframes y expectativas realistas

Recuerda: Cada persona que te consulta está buscando mejorar su vida. Tu respuesta puede ser el factor que determine si continúan su journey fitness o se rinden. Sé el entrenador que te hubiera gustado tener cuando empezaste.

RESPONDE SIEMPRE EN ESPAÑOL, adaptando tu nivel de detalle según la experiencia aparente del usuario. Si menciona limitaciones específicas, adapta TODO tu consejo a esas limitaciones.
''';

  // 🚀 Método principal con debugging completo
  Future<String> sendMessage(String userMessage) async {
    print('🚀 === INICIO REQUEST GEMINI ===');
    print('📝 Mensaje usuario: "${userMessage.substring(0, userMessage.length > 50 ? 50 : userMessage.length)}..."');

    try {
      // 🔍 VERIFICAR API KEY
      if (_apiKey == 'TU_API_KEY_AQUI') {
        print('❌ ERROR: API Key no configurada');
        return '''❌ **Error de configuración**

La API Key de Gemini no está configurada.

**Para solucionarlo:**
1. Ve a https://makersuite.google.com/app/apikey
2. Crea una nueva API Key
3. Reemplaza 'TU_API_KEY_AQUI' en gemini_service.dart

**Necesitas ayuda?** Dímelo y te guío paso a paso.''';
      }

      // 🔍 VERIFICAR CONEXIÓN A INTERNET (opcional)
      print('🌐 Verificando conexión...');

      // 🛠️ Construir el prompt completo
      final String fullPrompt = _buildFullPrompt(userMessage);
      print('📋 Prompt construido: ${fullPrompt.length} caracteres');

      // 🛠️ Preparar payload
      final Map<String, dynamic> payload = {
        'contents': [
          {
            'parts': [
              {'text': fullPrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.8,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      print('🔧 Payload preparado: ${jsonEncode(payload).length} bytes');

      // 🛠️ Preparar headers
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      print('🔧 Headers preparados: $headers');

      // 🌐 Construir URL completa
      final String fullUrl = '$_baseUrl?key=$_apiKey';
      print('🌐 URL completa: ${fullUrl.replaceAll(_apiKey, 'API_KEY_OCULTA')}');

      // 📡 HACER REQUEST
      print('📡 Enviando request...');
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(
        Duration(seconds: 30), // Timeout de 30 segundos
        onTimeout: () {
          print('⏰ TIMEOUT: La request tardó más de 30 segundos');
          throw Exception('Timeout - El servidor tardó demasiado en responder');
        },
      );

      print('📡 Response recibido!');
      print('📊 Status Code: ${response.statusCode}');
      print('📋 Headers response: ${response.headers}');
      print('📄 Body length: ${response.body.length} caracteres');

      // 🔍 ANALIZAR STATUS CODE
      return _handleResponse(response);

    } catch (e) {
      print('❌ ERROR en sendMessage: $e');
      print('🔍 Tipo de error: ${e.runtimeType}');

      return _handleError(e);
    } finally {
      print('🏁 === FIN REQUEST GEMINI ===\n');
    }
  }

  // 🔍 Manejar diferentes respuestas según status code
  String _handleResponse(http.Response response) {
    print('🔍 Analizando response...');

    switch (response.statusCode) {
      case 200:
        print('✅ Status 200: Request exitoso');
        return _parseSuccessResponse(response.body);

      case 400:
        print('❌ Status 400: Bad Request - Request malformado');
        return _parse400Error(response.body);

      case 401:
        print('❌ Status 401: Unauthorized - API Key inválida');
        return '''❌ **Error de autenticación**

Tu API Key de Gemini parece ser inválida.

**Posibles causas:**
• API Key incorrecta o expirada
• API Key no tiene permisos para Gemini Pro
• Restricciones de IP

**Solución:**
1. Verifica tu API Key en https://makersuite.google.com/app/apikey
2. Genera una nueva si es necesaria
3. Asegúrate que tenga permisos para Gemini Pro''';

      case 403:
        print('❌ Status 403: Forbidden - Sin permisos o límites excedidos');
        return _parse403Error(response.body);

      case 429:
        print('❌ Status 429: Too Many Requests - Límite de cuota excedido');
        return '''⚠️ **Límite de uso excedido**

Has superado el límite de requests de la API de Gemini.

**Opciones:**
• Espera unos minutos e intenta de nuevo
• Verifica tu cuota en Google AI Studio
• Considera upgrade si necesitas más requests

Mientras tanto, puedo ayudarte con consejos básicos de fitness sin IA.''';

      case 500:
      case 502:
      case 503:
        print('❌ Status ${response.statusCode}: Error del servidor de Google');
        return '''🔧 **Error temporal del servidor**

Los servidores de Gemini están experimentando problemas temporales.

**Solución:**
• Intenta de nuevo en 1-2 minutos
• Si persiste, reporta el problema

Error: ${response.statusCode}''';

      default:
        print('❌ Status ${response.statusCode}: Error desconocido');
        print('📄 Response body: ${response.body}');
        return '''❓ **Error desconocido**

Código de error: ${response.statusCode}

Intenta de nuevo o contacta soporte si persiste.

**Debug info:** ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}''';
    }
  }

  // ✅ Parsear respuesta exitosa
  String _parseSuccessResponse(String responseBody) {
    try {
      print('🔍 Parseando respuesta exitosa...');

      final data = jsonDecode(responseBody);
      print('📊 JSON parseado correctamente');

      // Verificar estructura de respuesta
      if (data['candidates'] == null) {
        print('❌ No hay candidates en la respuesta');
        print('📄 Response completo: $responseBody');
        return 'Error: Respuesta de Gemini sin contenido válido.';
      }

      if (data['candidates'].isEmpty) {
        print('❌ Array de candidates está vacío');
        return 'Error: Gemini no generó ninguna respuesta.';
      }

      final candidate = data['candidates'][0];

      if (candidate['content'] == null || candidate['content']['parts'] == null) {
        print('❌ Estructura de contenido inválida');
        return 'Error: Estructura de respuesta inválida.';
      }

      final content = candidate['content']['parts'][0]['text'];

      if (content == null || content.isEmpty) {
        print('❌ Contenido de texto vacío');
        return 'Error: Respuesta vacía de Gemini.';
      }

      print('✅ Respuesta parseada correctamente: ${content.length} caracteres');
      return content;

    } catch (e) {
      print('❌ Error parseando respuesta exitosa: $e');
      print('📄 Response body: $responseBody');
      return 'Error procesando respuesta de PrinceIA. Intenta de nuevo.';
    }
  }

  // ❌ Parsear error 400 (Bad Request)
  String _parse400Error(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      final errorMessage = data['error']['message'] ?? 'Request malformado';

      print('📄 Error 400 detalle: $errorMessage');

      if (errorMessage.contains('API key not valid')) {
        return '''❌ **API Key inválida**

La API Key no es válida para Gemini.

**Solución:**
1. Verifica tu API Key en Google AI Studio
2. Asegúrate que esté habilitada para Gemini Pro''';
      }

      if (errorMessage.contains('safety')) {
        return '''⚠️ **Contenido bloqueado por seguridad**

Tu mensaje fue bloqueado por las políticas de seguridad de Gemini.

**Intenta reformular tu pregunta** de forma más general o específica sobre fitness.''';
      }

      return '''❌ **Error en el request**

$errorMessage

Intenta reformular tu pregunta.''';

    } catch (e) {
      return 'Error 400: Request malformado. Intenta de nuevo.';
    }
  }

  // ❌ Parsear error 403 (Forbidden)
  String _parse403Error(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      final errorMessage = data['error']['message'] ?? 'Sin permisos';

      print('📄 Error 403 detalle: $errorMessage');

      if (errorMessage.contains('billing')) {
        return '''💳 **Facturación requerida**

Necesitas habilitar facturación en tu proyecto de Google Cloud.

**Pasos:**
1. Ve a Google Cloud Console
2. Habilita facturación para tu proyecto
3. Activa la API de Gemini''';
      }

      return '''❌ **Sin permisos**

$errorMessage

Verifica la configuración de tu API Key.''';

    } catch (e) {
      return 'Error 403: Sin permisos. Verifica tu configuración.';
    }
  }

  // ❌ Manejar errores de conexión y otros
  String _handleError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return '''⏰ **Conexión lenta**

El servidor tardó demasiado en responder.

**Soluciones:**
• Verifica tu conexión a internet
• Intenta de nuevo en unos momentos
• Usa una pregunta más corta''';
    }

    if (errorString.contains('socket') || errorString.contains('network')) {
      return '''🌐 **Sin conexión**

No se pudo conectar con los servidores de Gemini.

**Verifica:**
• Tu conexión a internet
• Que no haya firewall bloqueando
• Intenta de nuevo en unos momentos''';
    }

    if (errorString.contains('format') || errorString.contains('json')) {
      return '''🔧 **Error de formato**

Hubo un problema procesando la respuesta.

Intenta de nuevo o contacta soporte.''';
    }

    return '''❌ **Error inesperado**

$error

**Soluciones:**
• Intenta de nuevo
• Verifica tu conexión
• Contacta soporte si persiste''';
  }

  // 🔨 Construir prompt completo (mismo método que antes)
  String _buildFullPrompt(String userMessage) {
    return '''
$_systemPrompt

## 💬 CONSULTA DEL USUARIO:
"$userMessage"

## 📝 TU RESPUESTA COMO PRINCEÍA:
(Responde como el entrenador personal más empático y experto, adaptando tu respuesta al nivel aparente del usuario y proporcionando valor genuino que otras apps no ofrecen)
''';
  }

  // 🧪 Método de testing para verificar configuración
  Future<Map<String, dynamic>> testConnection() async {
    print('🧪 === TEST DE CONEXIÓN GEMINI ===');

    final results = <String, dynamic>{
      'api_key_configured': _apiKey != 'TU_API_KEY_AQUI',
      'api_key_length': _apiKey.length,
      'base_url': _baseUrl,
      'test_timestamp': DateTime.now().toIso8601String(),
    };

    // Test simple
    try {
      final testResponse = await http.get(
        Uri.parse('https://www.googleapis.com/'),
        headers: {'User-Agent': 'PrinceIA-Flutter-App'},
      ).timeout(Duration(seconds: 10));

      results['internet_connection'] = testResponse.statusCode == 200;
      results['google_apis_reachable'] = true;

    } catch (e) {
      results['internet_connection'] = false;
      results['google_apis_reachable'] = false;
      results['connection_error'] = e.toString();
    }

    print('🧪 Resultados del test: $results');
    return results;
  }

  // 🔧 Método para obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'service_version': '2.0.0-debug',
      'api_configured': _apiKey != 'TU_API_KEY_AQUI',
      'api_key_format': _apiKey.startsWith('AIza') ? 'válido' : 'inválido',
      'base_url': _baseUrl,
      'prompt_length': _systemPrompt.length,
    };
  }
}