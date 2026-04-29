import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/colors.dart';
import '../data/models/message_model.dart';

class VoiceMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  final ValueNotifier<String?>? activeAudioIdNotifier;
  final VoidCallback? onComplete;

  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.activeAudioIdNotifier,
    this.onComplete,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble>
    with AutomaticKeepAliveClientMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackRate = 1.0;
  String? _localPath;
  bool _isDownloading = false;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAudio();

    // 🛡️ Listen for global audio sync
    widget.activeAudioIdNotifier?.addListener(_handleActiveAudioChange);
  }

  void _handleActiveAudioChange() {
    final isActive = widget.activeAudioIdNotifier?.value == widget.message.id;
    if (!isActive) {
      if (_playerState == PlayerState.playing) {
        _audioPlayer.pause();
      }
    } else {
      // 🎵 AUTO-START: If this becomes active and isn't playing yet, start it!
      // We check for stopped/completed state to avoid fighting manual pauses.
      if (_playerState == PlayerState.stopped ||
          _playerState == PlayerState.completed) {
        _playPause();
      }
    }
  }

  Future<void> _initAudio() async {
    final url = widget.message.mediaUrls.isNotEmpty
        ? widget.message.mediaUrls[0]
        : widget.message.text;
    if (url.isEmpty || !url.startsWith('http')) return;

    // ⚡ PRE-FETCH BYTES for zero-latency
    _preFetchAudio(url);

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.stopped;
          _position = Duration.zero;
        });
        _audioPlayer.seek(Duration.zero);

        // 🔄 Trigger sequential playback
        widget.onComplete?.call();
      }
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      if (mounted) setState(() => _playerState = state);
    });

    // ⚡ ONLY listen to events, DO NOT set source here to avoid AVPlayer saturation
    // Source will be set lazily when play is pressed.
  }

  Future<void> _preFetchAudio(String url) async {
    if (_isDownloading || _localPath != null) return;
    try {
      _isDownloading = true;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = "${tempDir.path}/audio_${widget.message.id}.m4a";
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          setState(() {
            _localPath = filePath;
            _isDownloading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isDownloading = false);
      }
    } catch (e) {
      debugPrint("Pre-fetch failed: $e");
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  void dispose() {
    widget.activeAudioIdNotifier?.removeListener(_handleActiveAudioChange);
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playPause() async {
    final url = widget.message.mediaUrls.isNotEmpty
        ? widget.message.mediaUrls[0]
        : widget.message.text;
    if (url.isEmpty || !url.startsWith('http')) return;

    try {
      if (_playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        // 🎵 Set this as the active audio globally
        widget.activeAudioIdNotifier?.value = widget.message.id;

        // ⚡ LAZY INITIALIZATION: Set source only when about to play
        if (_audioPlayer.source == null) {
          if (_localPath != null) {
            await _audioPlayer.setSource(DeviceFileSource(_localPath!));
          } else {
            await _audioPlayer.setSource(UrlSource(url));
          }
        }

        // If we are at the end, or in a stopped state, seek to start
        if (_position >= _duration ||
            _playerState == PlayerState.stopped ||
            _playerState == PlayerState.completed) {
          await _audioPlayer.seek(Duration.zero);
        }

        // ⚡ RE-USE SOURCE: Use resume() if possible, or play() if it's the first time
        // audioplayers resume() is faster after setting source.
        await _audioPlayer.resume();
        await _audioPlayer.setPlaybackRate(_playbackRate);
      }
    } catch (e) {
      // Emergency fallback
      debugPrint("Audio play/resume failed, falling back to play URL: $e");
      await _audioPlayer.play(UrlSource(url));
      await _audioPlayer.setPlaybackRate(_playbackRate);
    }
  }

  void _toggleSpeed() async {
    setState(() {
      if (_playbackRate == 1.0) {
        _playbackRate = 1.5;
      } else if (_playbackRate == 1.5) {
        _playbackRate = 2.0;
      } else {
        _playbackRate = 1.0;
      }
    });
    await _audioPlayer.setPlaybackRate(_playbackRate);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _playPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playerState == PlayerState.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: widget.isMe ? Colors.white : AppColors.teal,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: widget.isMe
                        ? Colors.white
                        : AppColors.teal,
                    inactiveTrackColor: widget.isMe
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.grey.shade300,
                    thumbColor: widget.isMe ? Colors.white : AppColors.teal,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble(),
                    max: _duration.inMilliseconds.toDouble() > 0
                        ? _duration.inMilliseconds.toDouble()
                        : 1.0,
                    onChanged: (value) async {
                      await _audioPlayer.seek(
                        Duration(milliseconds: value.toInt()),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: widget.isMe
                              ? Colors.white70
                              : Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: widget.isMe
                              ? Colors.white70
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.teal.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${_playbackRate}x",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: widget.isMe ? Colors.white : AppColors.teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
