import '../models/event_model.dart';

abstract class IEventRemoteDataSource {
  Future<List<EventModel>> getEvents(String userId);
  Future<void> createEvent(EventModel event);
  Future<void> updateEvent(EventModel event);
  Future<void> deleteEvent(String eventId);
  Future<void> hireProvider(String eventId, String providerId, double cost);
}
