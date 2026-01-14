import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song_model.dart';

abstract class SongRemoteDataSource {
  Future<List<SongModel>> getSongs(String musicianId);
  Future<void> addSong(SongModel song);
  Future<void> updateSong(SongModel song);
  Future<void> deleteSong(String songId);
  Future<void> uploadBatch(List<SongModel> songs);
}

class SongRemoteDataSourceImpl implements SongRemoteDataSource {
  final FirebaseFirestore firestore;

  SongRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<SongModel>> getSongs(String musicianId) async {
    final snapshot = await firestore
        .collection('songs')
        .where('musicianId', isEqualTo: musicianId)
        .get();
    return snapshot.docs.map((doc) => SongModel.fromJson(doc.data(), doc.id)).toList();
  }

  @override
  Future<void> addSong(SongModel song) async {
    await firestore.collection('songs').add(song.toJson());
  }

  @override
  Future<void> updateSong(SongModel song) async {
    await firestore.collection('songs').doc(song.id).update(song.toJson());
  }

  @override
  Future<void> deleteSong(String songId) async {
    await firestore.collection('songs').doc(songId).delete();
  }

  @override
  Future<void> uploadBatch(List<SongModel> songs) async {
    final batch = firestore.batch();
    for (var song in songs) {
      final docRef = firestore.collection('songs').doc();
      batch.set(docRef, song.toJson());
    }
    await batch.commit();
  }
}
