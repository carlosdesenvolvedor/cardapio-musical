import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song_request_model.dart';

abstract class SongRequestRemoteDataSource {
  Future<void> createRequest(SongRequestModel request);
  Stream<List<SongRequestModel>> streamRequests(String musicianId);
  Future<void> updateRequestStatus(String requestId, String status);
  Future<void> deleteRequest(String requestId);
}

class SongRequestRemoteDataSourceImpl implements SongRequestRemoteDataSource {
  final FirebaseFirestore firestore;

  SongRequestRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> createRequest(SongRequestModel request) async {
    await firestore.collection('requests').add(request.toJson());
  }

  @override
  Stream<List<SongRequestModel>> streamRequests(String musicianId) {
    // Removed orderBy('createdAt') to avoid needing a composite index immediately.
    // Sorting is done client-side.
    return firestore
        .collection('requests')
        .where('musicianId', isEqualTo: musicianId)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        return SongRequestModel.fromJson(doc.data(), doc.id);
      }).toList();
      
      // Sort in memory: Newest first
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return requests;
    });
  }

  @override
  Future<void> updateRequestStatus(String requestId, String status) async {
    await firestore.collection('requests').doc(requestId).update({'status': status});
  }

  @override
  Future<void> deleteRequest(String requestId) async {
    await firestore.collection('requests').doc(requestId).delete();
  }
}
