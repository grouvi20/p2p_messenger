enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageType { text, image, file, system }

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? fileName;
  final int? fileSize;
  final String? replyToId;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sending,
    required this.timestamp,
    this.fileName,
    this.fileSize,
    this.replyToId,
  });

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? fileName,
    int? fileSize,
    String? replyToId,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      replyToId: replyToId ?? this.replyToId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'type': type.name,
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        'fileName': fileName,
        'fileSize': fileSize,
        'replyToId': replyToId,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        chatId: json['chatId'] as String,
        senderId: json['senderId'] as String,
        receiverId: json['receiverId'] as String,
        content: json['content'] as String,
        type: MessageType.values.byName(json['type'] as String? ?? 'text'),
        status:
            MessageStatus.values.byName(json['status'] as String? ?? 'sent'),
        timestamp: DateTime.parse(json['timestamp'] as String),
        fileName: json['fileName'] as String?,
        fileSize: json['fileSize'] as int?,
        replyToId: json['replyToId'] as String?,
      );

  bool get isTextMessage => type == MessageType.text;
}
