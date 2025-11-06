import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/model/song.dart';

class FavoriteService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  Future<void> toggleFavorite(Song song) async {
    final ref = _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(song.id);

    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete(); // nếu đã có thì xóa
    } else {
      await ref.set({
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'image': song.image,
        'source': song.source,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<Song>> getFavoritesStream() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Song.fromMap(doc.data()))
            .toList());
  }

  Future<bool> isFavorite(String songId) async {
    final doc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(songId)
        .get();
    return doc.exists;
  }
}
