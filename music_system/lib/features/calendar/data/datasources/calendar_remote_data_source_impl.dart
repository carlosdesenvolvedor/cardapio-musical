import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_event_model.dart';
import 'calendar_remote_data_source.dart';

class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  final FirebaseFirestore firestore;

  CalendarRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<CalendarEventModel>> getArtistCalendar(String bandId) async {
    final query = await firestore
        .collection('bands')
        .doc(bandId)
        .collection('events')
        .orderBy('startTime')
        .get();

    return query.docs
        .map((doc) => CalendarEventModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> saveCalendarEvent(CalendarEventModel event) async {
    final docRef =
        firestore.collection('bands').doc(event.bandId).collection('events');

    if (event.id.isEmpty) {
      await docRef.add(event.toJson());
    } else {
      await docRef.doc(event.id).set(event.toJson());
    }
  }

  @override
  Future<void> deleteCalendarEvent(String bandId, String eventId) async {
    await firestore
        .collection('bands')
        .doc(bandId)
        .collection('events')
        .doc(eventId)
        .delete();
  }
}
