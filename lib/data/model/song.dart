class Song {
  final String id;
  final String title;
  final String album;
  final String artist;
  final String source;
  final String image;
  final int duration;

  Song({
    required this.id,
    required this.title,
    required this.album,
    required this.artist,
    required this.source,
    required this.image,
    required this.duration,
  });

  factory Song.fromMap(Map<String, dynamic> data) {
    return Song(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? 'Không có tiêu đề',
      album: data['album'] ?? '',
      artist: data['artist'] ?? '',
      source: data['source'] ?? '',
      image: data['image'] ??
          "assets/itunes_256.png",
      duration: (data['duration'] is int)
          ? data['duration']
          : int.tryParse(data['duration']?.toString() ?? '0') ?? 0,
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) => Song.fromMap(json);
  /// ✅ Dành cho việc lưu dữ liệu lên Firestore hoặc chuyển đổi sang JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'album': album,
      'artist': artist,
      'source': source,
      'image': image,
      'duration': duration,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// ✅ So sánh nhanh hai bài hát
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
