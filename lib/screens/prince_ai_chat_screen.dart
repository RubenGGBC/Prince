// lib/screens/prince_ai_chat_screen.dart - MEJORADO CON CONTEXTO
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../utils/app_colors.dart';
import '../services/gemini_service.dart';
import '../services/contador_mensajes_service.dart';
import 'dart:async';
import '../models/chat_message.dart';
import '../domain/user.dart';
import '../models/form_feedback.dart';

class PrinceAIChatScreen extends StatefulWidget {
  final User? user;
  final String? initialContext; // 🆕 Contexto inicial
  final FormFeedback? workoutContext; // 🆕 Contexto de entrenamiento
  final List<PostWorkoutAnalysis>? analysisHistory; // 🆕 Historial de análisis

  const PrinceAIChatScreen({
    Key? key,
    this.user,
    this.initialContext,
    this.workoutContext,
    this.analysisHistory,
  }) : super(key: key);

  @override
  _PrinceAIChatScreenState createState() => _PrinceAIChatScreenState();
}

class _PrinceAIChatScreenState extends State<PrinceAIChatScreen>
    with TickerProviderStateMixin {

  final GeminiService _geminiService = GeminiService();
  final ContadorMensajesService _counterService = ContadorMensajesService();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int _remainingMessages = 0;

  // 🆕 Estado contextual
  bool _hasWorkoutContext = false;
  bool _hasAnalysisContext = false;

  // 🆕 Animaciones para contexto
  late AnimationController _contextBannerController;
  late Animation<double> _contextBannerAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeChat();
  }

  void _setupAnimations() {
    _contextBannerController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _contextBannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contextBannerController, curve: Curves.easeOutBack),
    );
  }

  Future<void> _initializeChat() async {
    try {
      // Cargar contador de mensajes
      _remainingMessages = await _counterService.getRemainingMessages();

      // 🆕 Detectar contextos disponibles
      _hasWorkoutContext = widget.workoutContext != null;
      _hasAnalysisContext = widget.analysisHistory != null && widget.analysisHistory!.isNotEmpty;

      setState(() => _isLoading = false);

      // Mensaje de bienvenida contextual
      await _sendWelcomeMessage();

      // 🆕 Enviar contexto inicial si existe
      if (widget.initialContext != null) {
        Timer(Duration(milliseconds: 500), () {
          _messageController.text = widget.initialContext!;
          _sendMessage();
        });
      }

      // Animar banner de contexto si hay información
      if (_hasWorkoutContext || _hasAnalysisContext) {
        _contextBannerController.forward();
      }

    } catch (e) {
      print('❌ Error inicializando chat: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendWelcomeMessage() async {
    // 🆕 Mensaje de bienvenida contextual
    String welcomeText = '''¡Hola! **Soy PrinceIA** 🤖

¡Tu entrenador personal virtual! 💪

**¿En qué puedo ayudarte hoy?**
• Rutinas de ejercicios
• Consejos de nutrición  
• Técnicas correctas
• Motivación y mindset''';

    // 🆕 Agregar contexto si está disponible
    if (_hasWorkoutContext) {
      final score = widget.workoutContext!.averageScore;
      welcomeText += '''

🎯 **Veo que acabas de entrenar:**
• Puntuación de técnica: ${score.toStringAsFixed(1)}/10
• ${widget.workoutContext!.shortComment}

¡Podemos analizar tu sesión juntos!''';
    }

    if (_hasAnalysisContext) {
      welcomeText += '''

📊 **Tengo tu historial de análisis:**
• ${widget.analysisHistory!.length} sesiones analizadas
• Puedo darte insights personalizados

¡Pregúntame sobre tu progreso!''';
    }

    welcomeText += '''

**Límite diario:** $_remainingMessages mensajes restantes 

¡Pregúntame lo que quieras sobre fitness! 🔥''';

    final welcomeMessage = ChatMessage.ai(welcomeText);
    setState(() {
      _messages.add(welcomeMessage);
    });

    _scrollToBottom();
  }

  // 🆕 ENVIAR MENSAJE CON CONTEXTO MEJORADO
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty) return;
    if (_isSending) return;

    // Verificar límite de mensajes
    if (!await _counterService.canSendMessage()) {
      _showLimitReachedDialog();
      return;
    }

    setState(() => _isSending = true);

    try {
      _messageController.clear();

      // Agregar mensaje del usuario
      final userMessage = ChatMessage.user(messageText);
      setState(() {
        _messages.add(userMessage);
      });
      _scrollToBottom();

      // Mostrar indicador de "escribiendo"
      final typingMessage = ChatMessage.typing();
      setState(() {
        _messages.add(typingMessage);
      });
      _scrollToBottom();

      // 🆕 CONSTRUIR PROMPT CON CONTEXTO
      final contextualPrompt = _buildContextualPrompt(messageText);

      // Enviar a Gemini API con contexto
      final aiResponse = await _geminiService.sendMessage(contextualPrompt);

      // Remover indicador de "escribiendo"
      setState(() {
        _messages.removeWhere((msg) => msg.status == MessageStatus.typing);
      });

      // Agregar respuesta de la IA
      final aiMessage = ChatMessage.ai(aiResponse);
      setState(() {
        _messages.add(aiMessage);
      });

      // Incrementar contador y mostrar advertencias
      await _counterService.incrementCounter();
      _remainingMessages = await _counterService.getRemainingMessages();

      final warning = await _counterService.getWarningMessage();
      if (warning != null) {
        _showWarningSnackBar(warning);
      }

      _scrollToBottom();

    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg.status == MessageStatus.typing);
      });
      _showErrorSnackBar('Error al enviar mensaje: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  // 🆕 CONSTRUIR PROMPT CON CONTEXTO
  String _buildContextualPrompt(String userMessage) {
    final contextParts = <String>[];

    // Contexto base del usuario
    if (widget.user != null) {
      contextParts.add('''
INFORMACIÓN DEL USUARIO:
- Nombre: ${widget.user!.nombre}
- Nivel: ${widget.user!.experienceLevel ?? 'No especificado'}
- Objetivos: ${widget.user!.goals?.join(', ') ?? 'Fitness general'}
''');
    }

    // 🆕 Contexto de entrenamiento reciente
    if (_hasWorkoutContext) {
      final workout = widget.workoutContext!;
      contextParts.add('''
SESIÓN DE ENTRENAMIENTO RECIENTE:
- Puntuación de técnica: ${workout.averageScore.toStringAsFixed(1)}/10
- Repeticiones detectadas: ${workout.totalReps}
- Comentario: ${workout.mainComment}
- Consejos dados: ${workout.tips.join(', ')}
- Estado: ${workout.level}
''');
    }

    // 🆕 Contexto de análisis histórico
    if (_hasAnalysisContext && widget.analysisHistory!.isNotEmpty) {
      final recent = widget.analysisHistory!.take(3).toList();
      final avgScore = recent
          .map((a) => a.strengthsIdentified.length - a.weaknessesIdentified.length)
          .reduce((a, b) => a + b) / recent.length;

      contextParts.add('''
HISTORIAL DE ANÁLISIS RECIENTE:
- Sesiones analizadas: ${widget.analysisHistory!.length}
- Tendencia general: ${avgScore > 0 ? 'Mejorando' : 'Necesita trabajo'}
- Fortalezas comunes: ${_getCommonStrengths()}
- Debilidades recurrentes: ${_getCommonWeaknesses()}
- Enfoque sugerido: ${recent.isNotEmpty ? recent.first.nextSessionFocus : 'Consistencia'}
''');
    }

    // Construir prompt final
    String finalPrompt = userMessage;

    if (contextParts.isNotEmpty) {
      finalPrompt = '''
${contextParts.join('\n\n')}

PREGUNTA DEL USUARIO: $userMessage

INSTRUCCIONES ESPECIALES:
- Usa la información contextual para dar respuestas más personalizadas
- Si la pregunta se relaciona con la sesión reciente, referénciala específicamente
- Si detectas patrones en el historial, menciónalo
- Mantén el tono motivador pero específico según su progreso
- Si no tienes suficiente contexto para algo específico, di que necesitas más información
''';
    }

    return finalPrompt;
  }

  // 🆕 OBTENER FORTALEZAS COMUNES
  String _getCommonStrengths() {
    if (!_hasAnalysisContext) return 'Ninguna registrada';

    final allStrengths = widget.analysisHistory!
        .expand((a) => a.strengthsIdentified)
        .toList();

    if (allStrengths.isEmpty) return 'En desarrollo';

    // Contar frecuencias
    final strengthCounts = <String, int>{};
    for (final strength in allStrengths) {
      strengthCounts[strength] = (strengthCounts[strength] ?? 0) + 1;
    }

    // Obtener las más comunes
    final sortedStrengths = strengthCounts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .take(3)
        .join(', ');

    return sortedStrengths.isNotEmpty ? sortedStrengths : 'Consistencia en el entrenamiento';
  }

  // 🆕 OBTENER DEBILIDADES COMUNES
  String _getCommonWeaknesses() {
    if (!_hasAnalysisContext) return 'Ninguna identificada';

    final allWeaknesses = widget.analysisHistory!
        .expand((a) => a.weaknessesIdentified)
        .toList();

    if (allWeaknesses.isEmpty) return 'Ninguna detectada';

    // Contar frecuencias
    final weaknessCounts = <String, int>{};
    for (final weakness in allWeaknesses) {
      weaknessCounts[weakness] = (weaknessCounts[weakness] ?? 0) + 1;
    }

    // Obtener las más comunes
    final sortedWeaknesses = weaknessCounts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .take(2)
        .join(', ');

    return sortedWeaknesses.isNotEmpty ? sortedWeaknesses : 'Técnica en desarrollo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingScreen()
          : Column(
        children: [
          // 🆕 Banner de contexto
          if (_hasWorkoutContext || _hasAnalysisContext)
            _buildContextBanner(),

          // Lista de mensajes
          Expanded(child: _buildMessagesList()),

          // Input de mensaje
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryBlack,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.pastelBlue, AppColors.pastelGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy, color: AppColors.white, size: 20),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PrinceIA',
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                // 🆕 Estado contextual en subtítulo
                _hasWorkoutContext || _hasAnalysisContext
                    ? 'Modo análisis personalizado 🎯'
                    : 'Tu entrenador personal',
                style: GoogleFonts.poppins(
                  color: AppColors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // 🆕 Indicador de contexto
        if (_hasWorkoutContext || _hasAnalysisContext)
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.pastelGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.analytics, color: AppColors.pastelGreen, size: 16),
                SizedBox(width: 4),
                Text(
                  'Con contexto',
                  style: GoogleFonts.poppins(
                    color: AppColors.pastelGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Menú de opciones
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.white),
          color: AppColors.cardBlack,
          onSelected: (value) {
            switch (value) {
              case 'clear':
                _clearChat();
                break;
              case 'context':
                _showContextDialog();
                break;
              case 'progress':
                _requestProgressAnalysis();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'progress',
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: AppColors.pastelGreen),
                  SizedBox(width: 8),
                  Text('Analizar progreso', style: TextStyle(color: AppColors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'context',
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.pastelBlue),
                  SizedBox(width: 8),
                  Text('Ver contexto', style: TextStyle(color: AppColors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.pastelOrange),
                  SizedBox(width: 8),
                  Text('Limpiar chat', style: TextStyle(color: AppColors.white)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🆕 BANNER DE CONTEXTO
  Widget _buildContextBanner() {
    return AnimatedBuilder(
      animation: _contextBannerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _contextBannerAnimation.value)),
          child: Opacity(
            opacity: _contextBannerAnimation.value,
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.pastelBlue.withOpacity(0.1),
                    AppColors.pastelGreen.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.pastelBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: AppColors.pastelBlue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎯 Modo Análisis Personalizado',
                          style: GoogleFonts.poppins(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _buildContextSummary(),
                          style: GoogleFonts.poppins(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildContextSummary() {
    final parts = <String>[];

    if (_hasWorkoutContext) {
      parts.add('Sesión reciente analizada');
    }

    if (_hasAnalysisContext) {
      parts.add('${widget.analysisHistory!.length} análisis previos');
    }

    return parts.join(' • ');
  }

  // 🆕 SOLICITAR ANÁLISIS DE PROGRESO
  void _requestProgressAnalysis() {
    if (_hasAnalysisContext) {
      _messageController.text = "Analiza mi progreso basándote en mi historial de entrenamientos";
      _sendMessage();
    } else {
      _showErrorSnackBar('Necesitas más datos de entrenamiento para el análisis');
    }
  }

  // 🆕 MOSTRAR DIÁLOGO DE CONTEXTO
  void _showContextDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Información Contextual',
          style: GoogleFonts.poppins(color: AppColors.white),
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hasWorkoutContext) ...[
                Text(
                  '🏋️ Última sesión:',
                  style: GoogleFonts.poppins(color: AppColors.pastelGreen, fontWeight: FontWeight.bold),
                ),
                Text(
                  '• Puntuación: ${widget.workoutContext!.averageScore.toStringAsFixed(1)}/10',
                  style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12),
                ),
                Text(
                  '• Estado: ${widget.workoutContext!.level}',
                  style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12),
                ),
                SizedBox(height: 12),
              ],

              if (_hasAnalysisContext) ...[
                Text(
                  '📊 Historial de análisis:',
                  style: GoogleFonts.poppins(color: AppColors.pastelBlue, fontWeight: FontWeight.bold),
                ),
                Text(
                  '• ${widget.analysisHistory!.length} sesiones analizadas',
                  style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12),
                ),
                Text(
                  '• Fortalezas: ${_getCommonStrengths()}',
                  style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12),
                ),
                Text(
                  '• A mejorar: ${_getCommonWeaknesses()}',
                  style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12),
                ),
              ],

              if (!_hasWorkoutContext && !_hasAnalysisContext) ...[
                Text(
                  'No hay contexto adicional disponible.',
                  style: GoogleFonts.poppins(color: AppColors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Entrena con análisis ML Kit para obtener insights personalizados.',
                  style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: AppColors.pastelBlue)),
          ),
        ],
      ),
    );
  }

  // MÉTODOS EXISTENTES (reutilizar los del chat original)

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.pastelBlue),
          SizedBox(height: 16),
          Text(
            '🤖 Preparando PrinceIA...',
            style: GoogleFonts.poppins(color: AppColors.white),
          ),
          if (_hasWorkoutContext || _hasAnalysisContext) ...[
            SizedBox(height: 8),
            Text(
              'Cargando contexto personalizado',
              style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isTyping = message.status == MessageStatus.typing;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.pastelBlue, AppColors.pastelGreen],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: AppColors.white, size: 16),
            ),
            SizedBox(width: 12),
          ],

          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? AppColors.pastelBlue : AppColors.cardBlack,
                borderRadius: BorderRadius.circular(16),
                border: isUser ? null : Border.all(color: AppColors.surfaceBlack),
              ),
              child: isTyping
                  ? _buildTypingIndicator()
                  : isUser
                  ? Text(
                message.content,
                style: GoogleFonts.poppins(color: AppColors.white),
              )
                  : MarkdownWidget(
                data: message.content,
                shrinkWrap: true,
                selectable: true,
                config: MarkdownConfig.darkConfig,
              ),
            ),
          ),

          if (isUser) ...[
            SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.pastelBlue,
              child: Icon(Icons.person, color: AppColors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'PrinceIA está escribiendo',
          style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 14),
        ),
        SizedBox(width: 8),
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.pastelBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        border: Border(top: BorderSide(color: AppColors.surfaceBlack)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: GoogleFonts.poppins(color: AppColors.white),
              maxLines: null,
              decoration: InputDecoration(
                hintText: _hasWorkoutContext || _hasAnalysisContext
                    ? 'Pregunta sobre tu progreso o técnica...'
                    : 'Escribe tu mensaje...',
                hintStyle: GoogleFonts.poppins(color: AppColors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.surfaceBlack),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.surfaceBlack),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.pastelBlue),
                ),
                filled: true,
                fillColor: AppColors.surfaceBlack,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.pastelBlue, AppColors.pastelGreen],
                ),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
                  : Icon(Icons.send, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    _sendWelcomeMessage();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text('Límite alcanzado', style: GoogleFonts.poppins(color: AppColors.white)),
        content: Text(
          'Has alcanzado el límite diario de mensajes. Intenta mañana.',
          style: GoogleFonts.poppins(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido', style: TextStyle(color: AppColors.pastelBlue)),
          ),
        ],
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.pastelOrange,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _contextBannerController.dispose();
    super.dispose();
  }
}