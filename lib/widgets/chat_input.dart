import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatInput extends StatefulWidget {
  final void Function(String text) onSend;
  final VoidCallback? onTyping;
  final VoidCallback? onAttachFile;
  final VoidCallback? onAttachImage;
  final VoidCallback? onRecordVoice;
  final VoidCallback? onRecordVideo;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onTyping,
    this.onAttachFile,
    this.onAttachImage,
    this.onRecordVoice,
    this.onRecordVideo,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _keyboardFocusNode = FocusNode();
  bool _hasText = false;
  Timer? _typingTimer;
  bool _typingThrottled = false;
  bool _showAttachMenu = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
      if (hasText) {
        if (!_typingThrottled) {
          widget.onTyping?.call();
          _typingThrottled = true;
        }
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          _typingThrottled = false;
        });
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _toggleAttachMenu() {
    setState(() => _showAttachMenu = !_showAttachMenu);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showAttachMenu) _buildAttachMenu(context),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).appBarTheme.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: AnimatedRotation(
                    turns: _showAttachMenu ? 0.125 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.attach_file_rounded),
                  ),
                  onPressed: _toggleAttachMenu,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: Focus(
                      focusNode: _keyboardFocusNode,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter &&
                            !HardwareKeyboard.instance.isShiftPressed) {
                          _send();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withAlpha(128),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _hasText
                      ? IconButton(
                          key: const ValueKey('send'),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onPressed: _send,
                        )
                      : IconButton(
                          key: const ValueKey('mic'),
                          icon: Icon(
                            Icons.mic_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: widget.onRecordVoice,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withAlpha(30),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _AttachOption(
            icon: Icons.image_rounded,
            label: 'Photo',
            color: Colors.purple,
            onTap: () {
              setState(() => _showAttachMenu = false);
              widget.onAttachImage?.call();
            },
          ),
          _AttachOption(
            icon: Icons.insert_drive_file_rounded,
            label: 'File',
            color: Colors.blue,
            onTap: () {
              setState(() => _showAttachMenu = false);
              widget.onAttachFile?.call();
            },
          ),
          _AttachOption(
            icon: Icons.videocam_rounded,
            label: 'Video',
            color: Colors.red,
            onTap: () {
              setState(() => _showAttachMenu = false);
              widget.onRecordVideo?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(25),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
