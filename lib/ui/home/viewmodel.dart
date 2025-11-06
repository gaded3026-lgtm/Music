import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/model/song.dart';

class SongViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Danh sách bài hát yêu thích (cập nhật realtime)
  List<Song> _favorites = [];
  List<Song> get favorites => _favorites;

  /// 🔥 Stream realtime đọc danh sách bài hát
  Stream<List<Song>> get songStream {
    return _db
        .collection('songs')
        .orderBy('id', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Song(
                id: data['id']?.toString() ?? '',
                title: data['title'] ?? '',
                album: data['album'] ?? '',
                artist: data['artist'] ?? '',
                source: data['source'] ?? '',
                image: data['image'] ?? '',
                duration: (data['duration'] is int)
                    ? data['duration']
                    : int.tryParse(data['duration']?.toString() ?? '0') ?? 0,
              );
            }).toList());
  }

  /// 🔄 Lắng nghe danh sách bài hát yêu thích theo tài khoản
  void listenToFavorites() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
      _favorites = snapshot.docs.map((doc) {
        final data = doc.data();
        return Song(
          id: data['id'] ?? '',
          title: data['title'] ?? '',
          album: data['album'] ?? '',
          artist: data['artist'] ?? '',
          source: data['source'] ?? '',
          image: data['image'] ?? '',
          duration: (data['duration'] is int)
              ? data['duration']
              : int.tryParse(data['duration']?.toString() ?? '0') ?? 0,
        );
      }).toList();

      notifyListeners();
    });
  }

  /// ❤️ Kiểm tra xem bài hát có trong danh sách yêu thích hay không
  bool isFavorite(String songId) {
    return _favorites.any((song) => song.id == songId);
  }

  /// ✅ Thêm hoặc xóa bài hát khỏi danh sách yêu thích (toggle)
  Future<void> toggleFavorite(Song song) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final favRef = _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(song.id);

    if (isFavorite(song.id)) {
      await favRef.delete();
      _favorites.removeWhere((s) => s.id == song.id);
      debugPrint("💔 Đã xóa khỏi danh sách yêu thích: ${song.title}");
    } else {
      await favRef.set(song.toJson());
      _favorites.add(song);
      debugPrint("❤️ Đã thêm vào danh sách yêu thích: ${song.title}");
    }

    notifyListeners();
  }

  /// ➕ Thêm bài hát vào danh sách yêu thích
  Future<void> addToFavorites(Song song) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(song.id)
        .set(song.toJson());
  }

  /// ❌ Xóa bài hát khỏi danh sách yêu thích
  Future<void> removeFromFavorites(String songId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(songId)
        .delete();
  }

  /// ➕ Thêm hoặc cập nhật bài hát
  Future<void> addOrUpdateSong({
    String? id,
    required String title,
    required String album,
    required String artist,
    required String source,
    required String image,
    int duration = 0,
  }) async {
    try {
      final songId = id ?? DateTime.now().millisecondsSinceEpoch.toString();

      final songData = {
        "id": songId,
        "title": title,
        "album": album,
        "artist": artist,
        "source": source,
        "image": image.isEmpty
            ? "assets/itunes_256.png"
            : image,
        "duration": duration,
      };

      await _db.collection('songs').doc(songId).set(songData);
      debugPrint("✅ Đã thêm/cập nhật bài hát: $title");
    } catch (e) {
      debugPrint("❌ Lỗi khi thêm/cập nhật bài hát: $e");
    }
  }

  /// 🗑️ Xóa bài hát theo ID
  Future<void> deleteSong(String id) async {
    try {
      await _db.collection('songs').doc(id).delete();
      debugPrint("🗑️ Đã xóa bài hát có id: $id");
    } catch (e) {
      debugPrint("❌ Lỗi khi xóa bài hát: $e");
    }
  }

  void listenToSongs() {
    // Gọi trong initState để kích hoạt stream
  }
}
