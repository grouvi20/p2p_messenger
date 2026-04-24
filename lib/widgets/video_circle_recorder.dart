import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class VideoCircleRecorder extends StatefulWidget {
  final void Function(String path, int durationSeconds) onRecorded;
  final VoidCallback onCancel;

  const VideoCircleRecorder({
    super.key,
    required this.onRecorded,
    required this.onCancel,
  });

  @override
  State<VideoCircleRecorder> createState() => _VideoCircleRecorderState();
}

class _VideoCircleRecorderState extends State<VideoCircleRecorder> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _initialized = false;
  int _seconds = 0;
  Timer? _timer;
  static const _maxDuration = 60;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        widget.onCancel();
        return;
      }

      // Prefer front camera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      widget.onCancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_controller == null || _isRecording) return;
    await _controller!.startVideoRecording();
    setState(() => _isRecording = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
      if (_seconds >= _maxDuration) {
        _stopAndSend();
      }
    });
  }

  Future<void> _stopAndSend() async {
    if (_controller == null || !_isRecording) return;
    _timer?.cancel();
    final file = await _controller!.stopVideoRecording();
    widget.onRecorded(file.path, _seconds);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      _timer?.cancel();
                      if (_isRecording) {
                        _controller?.stopVideoRecording();
                      }
                      widget.onCancel();
                    },
                  ),
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(_seconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: _initialized && _controller != null
                    ? Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isRecording
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                        ),
                        child: ClipOval(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _controller!.value.previewSize?.height ?? 1,
                                height: _controller!.value.previewSize?.width ?? 1,
                                child: CameraPreview(_controller!),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: _isRecording
                  ? GestureDetector(
                      onTap: _stopAndSend,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: _startRecording,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 4),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.videocam_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
