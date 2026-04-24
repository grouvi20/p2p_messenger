import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String url;
  final int duration;
  final bool isMine;

  const VoiceMessagePlayer({
    super.key,
    required this.url,
    required this.duration,
    required this.isMine,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _totalDuration = Duration(seconds: widget.duration);

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _player.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _player.onDurationChanged.listen((dur) {
      if (mounted && dur.inSeconds > 0) {
        setState(() => _totalDuration = dur);
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.url));
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isMine ? Colors.white : Theme.of(context).colorScheme.primary;
    final trackColor = widget.isMine
        ? Colors.white.withAlpha(80)
        : Theme.of(context).colorScheme.primary.withAlpha(60);

    final progress = _totalDuration.inMilliseconds > 0
        ? _position.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return SizedBox(
      width: 200,
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withAlpha(30),
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: accentColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: trackColor,
                    valueColor: AlwaysStoppedAnimation(accentColor),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying
                      ? _formatDuration(_position)
                      : _formatDuration(_totalDuration),
                  style: TextStyle(
                    fontSize: 11,
                    color: accentColor.withAlpha(178),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
