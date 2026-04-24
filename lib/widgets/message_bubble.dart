import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p2p_messenger/core/theme/app_theme.dart';
import 'package:p2p_messenger/models/message.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            if (message.type == MessageType.file)
              _buildFileContent(textColor)
            else
              Text(
                message.content,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            const SizedBox(height: 4),
            Row(
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
          ],
        ),
      ),
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
        Icon(Icons.insert_drive_file, color: textColor, size: 20),
        const SizedBox(width: 8),
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
