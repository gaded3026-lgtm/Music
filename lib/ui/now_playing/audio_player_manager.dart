import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DurationState {
  final Duration progress;
  final Duration buffered;
  final Duration total;
  
  DurationState({
    required this.progress,
    required this.buffered,
    required this.total,
  });
}

/// Trình quản lý phát nhạc (hỗ trợ MP3 và YouTube)
class AudioPlayerManager {
  final AudioPlayer player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  String? currentUrl;

  AudioPlayerManager({String? songUrl}) {
    if (songUrl != null) {
      init(songUrl);
    }
  }

  Future<void> init([String? songUrl]) async {
    if (songUrl != null) {
      await play(songUrl);
    }
  }

  /// Phát nhạc (tự động nhận diện link YouTube hoặc MP3)
  Future<void> play(String url) async {
    await player.stop();

    if (url.contains("youtube.com") || url.contains("youtu.be")) {
      final videoId = _extractVideoId(url);
      if (videoId == null) {
        print("❌ Không lấy được videoId từ link YouTube: $url");
        return;
      }

      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      currentUrl = streamInfo.url.toString();

      await player.setUrl(currentUrl!);
    } else {
      currentUrl = url;
      await player.setUrl(currentUrl!);
    }

    await player.play();
  }

  /// Hàm tự tách videoId từ link YouTube
  String? _extractVideoId(String url) {
    final regExp = RegExp(
      r'(?:v=|\/)([0-9A-Za-z_-]{11}).*',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    return match != null ? match.group(1) : null;
  }

  /// Stream trạng thái tiến trình bài hát
  Stream<DurationState> get durationState => Rx.combineLatest3<Duration, Duration, Duration?, DurationState>(
        player.positionStream,
        player.bufferedPositionStream,
        player.durationStream,
        (progress, buffered, total) => DurationState(
          progress: progress,
          buffered: buffered,
          total: total ?? Duration.zero,
        ),
      );

  /// Giải phóng tài nguyên
  Future<void> dispose() async {
    await player.stop();
    await player.dispose();
    _yt.close();
  }
}
