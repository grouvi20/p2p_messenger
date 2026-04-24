enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageType { text, image, file, voice, video, system }

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
  final int? duration; // seconds, for voice/video
  final String? mimeType;

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
    this.duration,
    this.mimeType,
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
    int? duration,
    String? mimeType,
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
      duration: duration ?? this.duration,
      mimeType: mimeType ?? this.mimeType,
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
        'duration': duration,
        'mimeType': mimeType,
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
        duration: json['duration'] as int?,
        mimeType: json['mimeType'] as String?,
      );

  bool get isTextMessage => type == MessageType.text;
  bool get isMediaMessage =>
      type == MessageType.image ||
      type == MessageType.voice ||
      type == MessageType.video;
}
