import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecorder extends StatefulWidget {
  final void Function(String path, int durationSeconds) onRecorded;
  final VoidCallback onCancel;

  const VoiceRecorder({
    super.key,
    required this.onRecorded,
    required this.onCancel,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  int _seconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      widget.onCancel();
      return;
    }

    String path;
    if (kIsWeb) {
      path = 'voice_message.m4a';
    } else {
      final dir = await getTemporaryDirectory();
      path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  Future<void> _stopAndSend() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (path != null && _seconds > 0) {
      widget.onRecorded(path, _seconds);
    } else {
      widget.onCancel();
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          children: [
            IconButton(
              icon: const Icon(Icons.delete_rounded),
              color: Colors.red,
              onPressed: () {
                _timer?.cancel();
                _recorder.stop();
                widget.onCancel();
              },
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withAlpha(
                      (128 + 127 * _pulseController.value).toInt(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatTime(_seconds),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            IconButton(
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
              onPressed: _stopAndSend,
            ),
          ],
        ),
      ),
    );
  }
}
