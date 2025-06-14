import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/chat_models.dart';
import '../services/gemini_service.dart';
import '../services/contador_mensajes_service.dart';

class PrinceAIChatScreen extends StatefulWidget {
  @override
  _PrinceAIChatScreenState createState() => _PrinceAIChatScreenState();
}

class _PrinceAIChatScreenState extends State<PrinceAIChatScreen>
    with TickerProviderStateMixin {

  // 🔧 CONTROLADORES Y SERVICIOS
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final MessageCounterService _counterService = MessageCounterService();

  // 📱 ESTADO DE LA APLICACIÓN
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  int _remainingMessages = 5;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeChat();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
  }

  // 🚀 Inicializar el chat
  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);

    try {
      // Inicializar servicios
      await _counterService.initialize();

      // Obtener mensajes restantes
      _remainingMessages = await _counterService.getRemainingMessages();

      // Agregar mensaje de bienvenida
      _addWelcomeMessage();

      setState(() => _isLoading = false);

    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al inicializar: $e');
    }
  }

  // 👋 Agregar mensaje de bienvenida
  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage.ai(
        '''🤖 **¡Hola! Soy PrinceIA** 

¡Tu entrenador personal virtual! 💪

**¿En qué puedo ayudarte hoy?**
• Rutinas de ejercicios
• Consejos de nutrición  
• Técnicas correctas
• Motivación y mindset

**Límite diario:** $_remainingMessages mensajes restantes 

¡Pregúntame lo que quieras sobre fitness! 🔥'''
    );

    setState(() {
      _messages.add(welcomeMessage);
    });

    _scrollToBottom();
  }

  // 📤 Enviar mensaje
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    // Validaciones
    if (messageText.isEmpty) return;
    if (_isSending) return;

    // Verificar límite de mensajes
    if (!await _counterService.canSendMessage()) {
      _showLimitReachedDialog();
      return;
    }

    setState(() => _isSending = true);

    try {
      // Limpiar campo de texto
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

      // Enviar a Gemini API
      final aiResponse = await _geminiService.sendMessage(messageText);

      // Remover indicador de "escribiendo"
      setState(() {
        _messages.removeWhere((msg) => msg.status == MessageStatus.typing);
      });

      // Agregar respuesta de la IA
      final aiMessage = ChatMessage.ai(aiResponse);
      setState(() {
        _messages.add(aiMessage);
      });

      // Incrementar contador de mensajes
      await _counterService.incrementCounter();
      _remainingMessages = await _counterService.getRemainingMessages();

      // Mostrar advertencia si quedan pocos mensajes
      final warning = await _counterService.getWarningMessage();
      if (warning != null) {
        _showWarningSnackBar(warning);
      }

      _scrollToBottom();

    } catch (e) {
      // Remover mensaje de "escribiendo" en caso de error
      setState(() {
        _messages.removeWhere((msg) => msg.status == MessageStatus.typing);
      });

      _showErrorSnackBar('Error al enviar mensaje: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildChatBody(),
    );
  }

  // 📱 AppBar personalizada
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surfaceBlack,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: AppColors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar de PrinceIA
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              color: AppColors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PrinceIA',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'Tu entrenador personal',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Contador de mensajes
        Container(
          margin: EdgeInsets.only(right: 16),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cardBlack,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.pastelBlue.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline,
                  color: AppColors.pastelBlue, size: 16),
              SizedBox(width: 4),
              Text(
                '$_remainingMessages',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _remainingMessages > 0 ? AppColors.pastelBlue : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔄 Estado de carga
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.pastelBlue),
          ),
          SizedBox(height: 16),
          Text(
            'Inicializando PrinceIA...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // 💬 Cuerpo principal del chat
  Widget _buildChatBody() {
    return Column(
      children: [
        // Lista de mensajes
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : _buildMessagesList(),
        ),

        // Sugerencias rápidas (solo si no hay mensajes del usuario)
        if (_messages.where((m) => m.type == MessageType.user).isEmpty)
          _buildQuickSuggestions(),

        // Campo de entrada
        _buildMessageInput(),
      ],
    );
  }

  // 📝 Lista de mensajes
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

  // 💭 Burbuja de mensaje individual
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.type == MessageType.user;
    final isSystem = message.type == MessageType.system;
    final isTyping = message.status == MessageStatus.typing;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Avatar de la IA
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: isSystem ? null : AppColors.primaryGradient,
                color: isSystem ? AppColors.grey : null,
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.getMessageIcon(),
                color: AppColors.white,
                size: 16,
              ),
            ),
            SizedBox(width: 8),
          ],

          // Contenido del mensaje
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.pastelBlue.withOpacity(0.1)
                    : AppColors.cardBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: message.getMessageColor().withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contenido del mensaje
                  if (isTyping)
                    _buildTypingIndicator()
                  else
                    Text(
                      message.content,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.white,
                        height: 1.4,
                      ),
                    ),

                  // Timestamp
                  if (!isTyping) ...[
                    SizedBox(height: 8),
                    Text(
                      message.getFormattedTime(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (isUser) ...[
            SizedBox(width: 8),
            // Avatar del usuario
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.pastelBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ⌨️ Indicador de "escribiendo"
  Widget _buildTypingIndicator() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.pastelBlue),
          ),
        ),
        SizedBox(width: 8),
        Text(
          'PrinceIA está escribiendo...',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // 💡 Sugerencias rápidas
  Widget _buildQuickSuggestions() {
    final suggestions = ChatSuggestion.getFitnessSuggestions();

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return GestureDetector(
            onTap: () {
              _messageController.text = suggestion.text;
              _sendMessage();
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: suggestion.color.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  suggestion.text,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✏️ Campo de entrada de mensajes
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBlack,
        border: Border(
          top: BorderSide(
            color: AppColors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: GoogleFonts.poppins(color: AppColors.white),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: _remainingMessages > 0
                    ? 'Pregúntame sobre fitness...'
                    : 'Sin mensajes restantes hoy',
                hintStyle: GoogleFonts.poppins(color: AppColors.grey),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.pastelBlue),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabled: _remainingMessages > 0 && !_isSending,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          // Botón enviar
          Container(
            decoration: BoxDecoration(
              gradient: _remainingMessages > 0 && !_isSending
                  ? AppColors.primaryGradient
                  : null,
              color: _remainingMessages == 0 || _isSending
                  ? AppColors.grey.withOpacity(0.3)
                  : null,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _remainingMessages > 0 && !_isSending ? _sendMessage : null,
              icon: _isSending
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
                  : Icon(
                Icons.send_rounded,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🚫 Estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              size: 40,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'PrinceIA está listo',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          Text(
            'Pregúntame cualquier cosa sobre fitness',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 MÉTODOS DE UTILIDAD

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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Límite alcanzado',
              style: GoogleFonts.poppins(color: AppColors.white),
            ),
          ],
        ),
        content: Text(
          'Has usado tus 5 mensajes diarios con PrinceIA.\n\n¡Vuelve mañana para más consejos de entrenamiento! 💪',
          style: GoogleFonts.poppins(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: TextStyle(color: AppColors.pastelBlue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}