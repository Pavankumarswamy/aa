import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SimpleAudioPlayerScreen extends StatefulWidget {
  final String audioUrl;
  final String title;
  final String? coverUrl;
  final DateTime? createdAt; // Added for compatibility with PostModel

  const SimpleAudioPlayerScreen({
    super.key,
    required this.audioUrl,
    required this.title,
    this.coverUrl,
    this.createdAt,
  });

  @override
  State<SimpleAudioPlayerScreen> createState() =>
      _SimpleAudioPlayerScreenState();
}

class _SimpleAudioPlayerScreenState extends State<SimpleAudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      // Set playing state listener
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      // Set duration listener
      _audioPlayer.onDurationChanged.listen((newDuration) {
        if (mounted) {
          setState(() {
            _duration = newDuration;
          });
        }
      });

      // Set position listener
      _audioPlayer.onPositionChanged.listen((newPosition) {
        if (mounted) {
          setState(() {
            _position = newPosition;
          });
        }
      });

      // Set source
      await _audioPlayer.setSourceUrl(widget.audioUrl);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading audio: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading audio: $e')));
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Now Playing', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cover Art
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: widget.coverUrl != null && widget.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                        errorWidget: (context, url, err) => Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.music_note,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),

            // Title
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  // Slider
                  Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble(),
                    value: _position.inSeconds.toDouble().clamp(
                      0,
                      _duration.inSeconds.toDouble(),
                    ),
                    onChanged: (value) async {
                      final position = Duration(seconds: value.toInt());
                      await _audioPlayer.seek(position);
                    },
                    activeColor: Colors.blueAccent,
                    inactiveColor: Colors.grey[800],
                  ),

                  // Timestamps
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.replay_10,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          final newPos =
                              _position - const Duration(seconds: 10);
                          _audioPlayer.seek(
                            newPos < Duration.zero ? Duration.zero : newPos,
                          );
                        },
                      ),
                      const SizedBox(width: 24),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 40,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            if (_isPlaying) {
                              await _audioPlayer.pause();
                            } else {
                              await _audioPlayer.resume();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(
                          Icons.forward_10,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          final newPos =
                              _position + const Duration(seconds: 10);
                          _audioPlayer.seek(
                            newPos > _duration ? _duration : newPos,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
