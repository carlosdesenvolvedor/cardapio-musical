import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import 'event_remote_data_source.dart';

class EventFirestoreDataSourceImpl implements IEventRemoteDataSource {
  final FirebaseFirestore firestore;

  EventFirestoreDataSourceImpl({required this.firestore});

  @override
  Future<List<EventModel>> getEvents(String userId) async {
    final snapshot = await firestore
        .collection('events')
        .where('ownerId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => EventModel.fromSnapshot(doc)).toList();
  }

  @override
  Future<void> createEvent(EventModel event) async {
    await firestore
        .collection('events')
        .doc(event.id.isEmpty ? null : event.id)
        .set(event.toDocument());
  }

  @override
  Future<void> updateEvent(EventModel event) async {
    await firestore
        .collection('events')
        .doc(event.id)
        .update(event.toDocument());
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    await firestore.collection('events').doc(eventId).delete();
  }

  @override
  Future<void> hireProvider(
      String eventId, String providerId, double cost) async {
    await firestore.collection('events').doc(eventId).update({
      'hiredProviderIds': FieldValue.arrayUnion([providerId]),
      'currentExpenses': FieldValue.increment(cost),
    });
  }
}
