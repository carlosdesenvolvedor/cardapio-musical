import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/band_model.dart';
import '../models/band_member_model.dart';

abstract class BandRemoteDataSource {
  Future<String> createBand(BandModel band);
  Future<BandModel> getBand(String bandId);
  Future<BandModel> getBandBySlug(String slug);
  Future<List<BandModel>> getUserBands(String userId);
  Future<void> updateBand(BandModel band);

  Future<void> inviteMember(String bandId, BandMemberModel member);
  Future<void> respondToInvite(String bandId, String userId, String status);
  Future<List<BandMemberModel>> getBandMembers(String bandId);
  Future<void> removeMember(String bandId, String userId);
}

class BandRemoteDataSourceImpl implements BandRemoteDataSource {
  final FirebaseFirestore firestore;

  BandRemoteDataSourceImpl({required this.firestore});

  @override
  Future<String> createBand(BandModel band) async {
    final docRef = await firestore.collection('bands').add(band.toJson());

    // Add leader as first member
    await firestore
        .collection('bands')
        .doc(docRef.id)
        .collection('members')
        .doc(band.leaderId)
        .set({
      'userId': band.leaderId,
      'role': 'leader',
      'status': 'active',
    });

    return docRef.id;
  }

  @override
  Future<BandModel> getBand(String bandId) async {
    final doc = await firestore.collection('bands').doc(bandId).get();
    if (!doc.exists) throw Exception('Band not found');
    return BandModel.fromJson(doc.data()!, doc.id);
  }

  @override
  Future<BandModel> getBandBySlug(String slug) async {
    final query = await firestore
        .collection('bands')
        .where('slug', isEqualTo: slug)
        .limit(1)
        .get();
    if (query.docs.isEmpty) throw Exception('Band not found');
    return BandModel.fromJson(query.docs.first.data(), query.docs.first.id);
  }

  @override
  Future<List<BandModel>> getUserBands(String userId) async {
    // This is tricky because members are in a subcollection.
    // Option A: Use a top-level members collection for querying.
    // Option B: Query 'bands' where 'leaderId' == userId.
    // Option C: Query all bands where current user is in members subcollection (Hard without Collection Group Query).

    // For now, let's filter by leaderId to keep it simple, or use a Collection Group query later.
    final query = await firestore
        .collection('bands')
        .where('leaderId', isEqualTo: userId)
        .get();

    return query.docs
        .map((doc) => BandModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> updateBand(BandModel band) async {
    await firestore.collection('bands').doc(band.id).update(band.toJson());
  }

  @override
  Future<void> inviteMember(String bandId, BandMemberModel member) async {
    await firestore
        .collection('bands')
        .doc(bandId)
        .collection('members')
        .doc(member.userId)
        .set(member.toJson());
  }

  @override
  Future<void> respondToInvite(
      String bandId, String userId, String status) async {
    await firestore
        .collection('bands')
        .doc(bandId)
        .collection('members')
        .doc(userId)
        .update({'status': status});
  }

  @override
  Future<List<BandMemberModel>> getBandMembers(String bandId) async {
    final query = await firestore
        .collection('bands')
        .doc(bandId)
        .collection('members')
        .get();
    return query.docs
        .map((doc) => BandMemberModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> removeMember(String bandId, String userId) async {
    await firestore
        .collection('bands')
        .doc(bandId)
        .collection('members')
        .doc(userId)
        .delete();
  }
}
