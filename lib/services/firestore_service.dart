
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../data/model/song.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<void> addSongByLink({
  required String title,
  required String album,
  required String artist,
  required String audioUrl,
  required String imageUrl,
  required int duration,
}) async {
    final String id = const Uuid().v4();
    await _db.collection('songs').doc(id).set({
      'id': id,
      'title': title,
      'album': album,
      'artist': artist,
      'source': audioUrl,
      'image': imageUrl,
      'duration': duration,
      'createdAt': FieldValue.serverTimestamp(),
    });
}

  Future<List<Song>> getSongs() async {
    final snapshot = await _db.collection('songs').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((d) => Song.fromJson(d.data())).toList();
  }
  Future<void> deleteSong(String id) async {
    final doc = await _db.collection('songs').doc(id).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final audioUrl = data['source'];
    final imageUrl = data['image'];

    await _db.collection('songs').doc(id).delete();
    if (audioUrl != null) await _storage.refFromURL(audioUrl).delete();
    if (imageUrl != null) await _storage.refFromURL(imageUrl).delete();
  }

  Future<Song?> getSong(String id) async {
    final doc = await _db.collection('songs').doc(id).get();
    if (!doc.exists) return null;
    return Song.fromJson(doc.data()!);
  }
}
