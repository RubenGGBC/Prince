
import 'package:flutter/material.dart';

enum MessageType {
  user,     // Mensaje del usuario
  ai,       // Respuesta de la IA
  system,   // Mensajes del sistema (límites, errores, etc.)
}

// 🎭 Enum para estado del mensaje
enum MessageStatus {
  sending,   // Enviando
  sent,      // Enviado correctamente
  failed,    // Error al enviar
  typing,    // IA está escribiendo
}

// 💬 Clase principal para representar un mensaje
class ChatMessage {
  final String id;              // ID único del mensaje
  final String content;         // Contenido del mensaje
  final MessageType type;       // Tipo de mensaje
  final DateTime timestamp;     // Cuando se envió
  final MessageStatus status;   // Estado actual
  final String? error;          // Mensaje de error si falló

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.error,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? error,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, type: $type, status: $status, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}...)';
  }


  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  factory ChatMessage.ai(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.ai,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  factory ChatMessage.system(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.system,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  factory ChatMessage.sending(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
  }

  factory ChatMessage.typing() {
    return ChatMessage(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      content: 'PrinceIA está escribiendo...',
      type: MessageType.ai,
      timestamp: DateTime.now(),
      status: MessageStatus.typing,
    );
  }

  factory ChatMessage.error(String content, String errorMessage) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
      status: MessageStatus.failed,
      error: errorMessage,
    );
  }

  Color getMessageColor() {
    switch (type) {
      case MessageType.user:
        return const Color(0xFF58A6FF);
      case MessageType.ai:
        return const Color(0xFF79C0FF);
      case MessageType.system:
        return const Color(0xFFF0F6FF);
    }
  }

  IconData getMessageIcon() {
    switch (type) {
      case MessageType.user:
        return Icons.person;
      case MessageType.ai:
        return Icons.smart_toy;
      case MessageType.system:
        return Icons.info_outline;
    }
  }

  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  bool get isLongMessage => content.length > 200;

  bool get isFitnessRelated {
    final fitnessKeywords = [
      'ejercicio', 'rutina', 'entrenamiento', 'gym', 'peso', 'músculo',
      'cardio', 'fuerza', 'flexiones', 'sentadillas', 'proteína', 'dieta'
    ];

    final lowerContent = content.toLowerCase();
    return fitnessKeywords.any((keyword) => lowerContent.contains(keyword));
  }
}

class ChatStats {
  final int totalMessages;
  final int userMessages;
  final int aiMessages;
  final int systemMessages;
  final DateTime? firstMessage;
  final DateTime? lastMessage;
  final int messagesRemainingToday;

  ChatStats({
    required this.totalMessages,
    required this.userMessages,
    required this.aiMessages,
    required this.systemMessages,
    this.firstMessage,
    this.lastMessage,
    required this.messagesRemainingToday,
  });

  factory ChatStats.fromMessages(List<ChatMessage> messages, int remainingMessages) {
    if (messages.isEmpty) {
      return ChatStats(
        totalMessages: 0,
        userMessages: 0,
        aiMessages: 0,
        systemMessages: 0,
        messagesRemainingToday: remainingMessages,
      );
    }

    final userMsgs = messages.where((m) => m.type == MessageType.user).length;
    final aiMsgs = messages.where((m) => m.type == MessageType.ai).length;
    final systemMsgs = messages.where((m) => m.type == MessageType.system).length;

    final sortedMessages = List<ChatMessage>.from(messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return ChatStats(
      totalMessages: messages.length,
      userMessages: userMsgs,
      aiMessages: aiMsgs,
      systemMessages: systemMsgs,
      firstMessage: sortedMessages.first.timestamp,
      lastMessage: sortedMessages.last.timestamp,
      messagesRemainingToday: remainingMessages,
    );
  }

  Duration? get conversationDuration {
    if (firstMessage == null || lastMessage == null) return null;
    return lastMessage!.difference(firstMessage!);
  }

  double get userMessagePercentage {
    if (totalMessages == 0) return 0.0;
    return (userMessages / totalMessages) * 100;
  }
}

class ChatSuggestion {
  final String text;
  final String category;
  final IconData icon;
  final Color color;

  ChatSuggestion({
    required this.text,
    required this.category,
    required this.icon,
    required this.color,
  });

  static List<ChatSuggestion> getFitnessSuggestions() {
    return [
      ChatSuggestion(
        text: '¿Cómo hacer flexiones correctamente?',
        category: 'Técnica',
        icon: Icons.fitness_center,
        color: const Color(0xFF58A6FF),
      ),
      ChatSuggestion(
        text: 'Rutina para principiantes en casa',
        category: 'Rutinas',
        icon: Icons.home,
        color: const Color(0xFF79C0FF),
      ),
      ChatSuggestion(
        text: '¿Qué comer antes del entrenamiento?',
        category: 'Nutrición',
        icon: Icons.restaurant,
        color: const Color(0xFFF0F6FF),
      ),
      ChatSuggestion(
        text: 'Cómo aumentar masa muscular',
        category: 'Objetivos',
        icon: Icons.trending_up,
        color: const Color(0xFF79C0FF),
      ),
      ChatSuggestion(
        text: 'Ejercicios para el dolor de espalda',
        category: 'Salud',
        icon: Icons.healing,
        color: const Color(0xFF58A6FF),
      ),
    ];
  }
}