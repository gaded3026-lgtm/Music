import 'dart:math';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../data/model/song.dart';
import 'audio_player_manager.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

class NowPlaying extends StatefulWidget {
  final List<Song> songs;
  final Song playingSong;

  const NowPlaying({
    super.key,
    required this.songs,
    required this.playingSong,
  });

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  AudioPlayerManager? _audioManager;
  YoutubePlayerController? _ytController;
  bool isYoutube = false;
  bool isShuffle = false;
  bool isRepeat = false;
  bool isMuted = false;
  double globalVolume = 1.0;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.songs.indexWhere((s) => s.id == widget.playingSong.id);
    _setupPlayer();
  }

  Future<void> _setupPlayer() async {
    final song = widget.songs[currentIndex];
    final url = song.source;
    final newIsYoutube = url.contains("youtube.com") || url.contains("youtu.be");

    // 🧹 Dừng mọi thứ trước khi phát bài mới
    await _audioManager?.player.stop();
    await _audioManager?.dispose();
    _audioManager = null;

    if (_ytController != null) {
      try {
        await _ytController!.stopVideo();
      } catch (_) {}
    }

    if (newIsYoutube) {
      // 🎬 YouTube video
      final videoId = YoutubePlayerController.convertUrlToId(url);
      if (videoId == null) return;

      if (_ytController == null) {
        _ytController = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: true,
          params: const YoutubePlayerParams(
            mute: false,
            showControls: true,
            showFullscreenButton: false,
          ),
        );
      } else {
        await _ytController!.loadVideoById(videoId: videoId);
      }

      _ytController!.listen((event) {
        if (event.playerState == PlayerState.ended) _onSongEnd();
      });

      setState(() {
        isYoutube = true;
      });
    } else {
      // 🎵 MP3 hoặc URL âm thanh
      _audioManager = AudioPlayerManager(songUrl: url);
      await _audioManager!.init();
      await _audioManager!.player.setVolume(isMuted ? 0 : globalVolume);
      await _audioManager!.player.play();

      _audioManager!.player.playerStateStream.listen((state) {
        if (state.processingState == just_audio.ProcessingState.completed) {
          _onSongEnd();
        }
      });

      setState(() {
        isYoutube = false;
      });
    }
  }

  void _onSongEnd() {
    if (isRepeat) {
      _setupPlayer();
    } else {
      _nextSong();
    }
  }

  void _nextSong() async {
    // 🛑 Dừng bài hiện tại
    if (isYoutube && _ytController != null) {
      try {
        await _ytController!.stopVideo();
      } catch (_) {}
    } else {
      await _audioManager?.player.stop();
    }

    setState(() {
      if (isShuffle) {
        currentIndex = Random().nextInt(widget.songs.length);
      } else {
        currentIndex = (currentIndex + 1) % widget.songs.length;
      }
    });
    _setupPlayer();
  }

  void _previousSong() async {
    // 🛑 Dừng bài hiện tại
    if (isYoutube && _ytController != null) {
      try {
        await _ytController!.stopVideo();
      } catch (_) {}
    } else {
      await _audioManager?.player.stop();
    }

    setState(() {
      if (isShuffle) {
        currentIndex = Random().nextInt(widget.songs.length);
      } else {
        currentIndex = (currentIndex - 1 + widget.songs.length) % widget.songs.length;
      }
    });
    _setupPlayer();
  }

  @override
  void dispose() {
    _audioManager?.dispose();
    _ytController?.close();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.songs[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1224),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Now Playing",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ===== YouTube video (40%) hoặc ảnh =====
              if (isYoutube && _ytController != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final videoWidth = screenWidth * 0.4; // chỉ 40%
                      final videoHeight = videoWidth * 9 / 16;
                      return Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: videoWidth,
                            height: videoHeight,
                            child: YoutubePlayer(controller: _ytController!),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    song.image,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/itunes_256.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // ===== Tên bài hát =====
              Text(
                song.title,
                style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                song.artist,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 20),

              // ===== Thanh tiến trình (chỉ cho MP3) =====
              if (!isYoutube && _audioManager != null)
                StreamBuilder<DurationState>(
                  stream: _audioManager!.durationState,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    final progress = state?.progress ?? Duration.zero;
                    final total = state?.total ?? Duration.zero;

                    return Column(
                      children: [
                        SliderTheme(
                          data: const SliderThemeData(
                              thumbShape:
                                  RoundSliderThumbShape(enabledThumbRadius: 5),
                              trackHeight: 2),
                          child: Slider(
                            activeColor: Colors.white,
                            inactiveColor: Colors.white24,
                            min: 0,
                            max: total.inMilliseconds.toDouble(),
                            value: progress.inMilliseconds
                                .clamp(0, total.inMilliseconds)
                                .toDouble(),
                            onChanged: (value) {
                              _audioManager!.player
                                  .seek(Duration(milliseconds: value.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(progress),
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                              Text(_formatDuration(total),
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

              const SizedBox(height: 20),

              // ===== Điều khiển + âm lượng =====
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔊 Thanh âm lượng dọc bên trái
                    Column(
                      children: [
                        RotatedBox(
                          quarterTurns: -1,
                          child: SizedBox(
                            height: 120,
                            width: 28,
                            child: SliderTheme(
                              data: const SliderThemeData(
                                trackHeight: 2,
                                thumbShape:
                                    RoundSliderThumbShape(enabledThumbRadius: 5),
                              ),
                              child: Slider(
                                activeColor: Colors.purpleAccent,
                                inactiveColor: Colors.white24,
                                min: 0,
                                max: 1,
                                value: globalVolume,
                                onChanged: (value) {
                                  setState(() {
                                    globalVolume = value;
                                    isMuted = value == 0;
                                  });
                                  _audioManager?.player.setVolume(globalVolume);
                                  _ytController
                                      ?.setVolume((value * 100).toInt());
                                },
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isMuted ? Icons.volume_off : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              isMuted = !isMuted;
                              if (isMuted) {
                                _audioManager?.player.setVolume(0);
                                _ytController?.mute();
                              } else {
                                _audioManager?.player.setVolume(globalVolume);
                                _ytController?.unMute();
                              }
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(width: 20),

                    // 🎛 Nút điều khiển
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.shuffle,
                              color:
                                  isShuffle ? Colors.purpleAccent : Colors.white54),
                          onPressed: () => setState(() => isShuffle = !isShuffle),
                        ),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.skip_previous, color: Colors.white),
                          onPressed: _previousSong,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: IconButton(
                            iconSize: 44,
                            icon: Icon(
                              (_audioManager?.player.playing ?? false)
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: const Color(0xFF0D1224),
                            ),
                            onPressed: () {
                              if (_audioManager?.player.playing ?? false) {
                                _audioManager?.player.pause();
                              } else {
                                _audioManager?.player.play();
                              }
                            },
                          ),
                        ),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.skip_next, color: Colors.white),
                          onPressed: _nextSong,
                        ),
                        IconButton(
                          icon: Icon(Icons.repeat,
                              color: isRepeat
                                  ? Colors.purpleAccent
                                  : Colors.white54),
                          onPressed: () => setState(() => isRepeat = !isRepeat),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
