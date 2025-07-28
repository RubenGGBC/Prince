enum MessageStatus {
  sent,
  received,
  typing,
  error,
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
  }) : timestamp = timestamp ?? DateTime.now();

  // Factory constructor for user messages
  factory ChatMessage.user(String content) {
    return ChatMessage(
      content: content,
      isUser: true,
      status: MessageStatus.sent,
    );
  }

  // Factory constructor for AI messages
  factory ChatMessage.ai(String content) {
    return ChatMessage(
      content: content,
      isUser: false,
      status: MessageStatus.received,
    );
  }

  // Factory constructor for typing indicator
  factory ChatMessage.typing() {
    return ChatMessage(
      content: '',
      isUser: false,
      status: MessageStatus.typing,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
    };
  }

  // Create from Map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      content: map['content'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.parse(map['timestamp']),
      status: MessageStatus.values[map['status'] ?? 0],
    );
  }

  @override
  String toString() {
    return 'ChatMessage(content: $content, isUser: $isUser, timestamp: $timestamp)';
  }
}