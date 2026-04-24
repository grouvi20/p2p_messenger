import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p2p_messenger/core/theme/app_theme.dart';
import 'package:p2p_messenger/models/message.dart';
import 'package:p2p_messenger/widgets/voice_message_player.dart';
import 'package:p2p_messenger/widgets/video_circle_player.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool showTail;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showTail = true,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.video) {
      return _buildVideoCircleBubble(context);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isMine
        ? (isDark ? AppTheme.darkSentBubbleColor : AppTheme.sentBubbleColor)
        : (isDark
            ? AppTheme.darkReceivedBubbleColor
            : AppTheme.receivedBubbleColor);
    final textColor = isMine
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        margin: EdgeInsets.only(
          left: isMine ? 64 : 12,
          right: isMine ? 12 : 64,
          top: showTail ? 8 : 2,
          bottom: 2,
        ),
        padding: message.type == MessageType.image
            ? const EdgeInsets.all(3)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine || !showTail ? 18 : 4),
            bottomRight: Radius.circular(!isMine || !showTail ? 18 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildContent(context, textColor),
            if (message.type != MessageType.image)
              const SizedBox(height: 4),
            _buildTimestamp(context, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageContent(context);
      case MessageType.voice:
        return VoiceMessagePlayer(
          url: message.content,
          duration: message.duration ?? 0,
          isMine: isMine,
        );
      case MessageType.file:
        return _buildFileContent(textColor);
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            height: 1.3,
          ),
        );
    }
  }

  Widget _buildVideoCircleBubble(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isMine ? 64 : 12,
          right: isMine ? 12 : 64,
          top: showTail ? 8 : 2,
          bottom: 2,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            VideoCirclePlayer(
              url: message.content,
              duration: message.duration ?? 0,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withAlpha(128),
                      fontSize: 11,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(
                      Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 280,
          maxHeight: 300,
        ),
        child: Image.network(
          message.content,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 200,
              height: 150,
              color: Colors.grey.withAlpha(30),
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stack) {
            return Container(
              width: 200,
              height: 100,
              color: Colors.grey.withAlpha(30),
              child: const Center(
                child: Icon(Icons.broken_image_rounded, size: 32),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context, Color textColor) {
    if (message.type == MessageType.image) {
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: textColor.withAlpha(178),
                fontSize: 11,
              ),
            ),
            if (isMine) ...[
              const SizedBox(width: 4),
              _buildStatusIcon(textColor),
            ],
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(message.timestamp),
          style: TextStyle(
            color: textColor.withAlpha(178),
            fontSize: 11,
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: 4),
          _buildStatusIcon(textColor),
        ],
      ],
    );
  }

  Widget _buildStatusIcon(Color baseColor) {
    IconData icon;
    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
      case MessageStatus.sent:
        icon = Icons.check;
      case MessageStatus.delivered:
        icon = Icons.done_all;
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent);
      case MessageStatus.failed:
        icon = Icons.error_outline;
    }
    return Icon(icon, size: 14, color: baseColor.withAlpha(178));
  }

  Widget _buildFileContent(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: textColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.insert_drive_file_rounded, color: textColor, size: 24),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.fileName ?? 'File',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (message.fileSize != null)
                Text(
                  _formatFileSize(message.fileSize!),
                  style: TextStyle(
                    color: textColor.withAlpha(178),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
