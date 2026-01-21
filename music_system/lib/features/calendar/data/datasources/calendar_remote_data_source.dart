import '../models/calendar_event_model.dart';

abstract class CalendarRemoteDataSource {
  Future<List<CalendarEventModel>> getArtistCalendar(String bandId);
  Future<void> saveCalendarEvent(CalendarEventModel event);
  Future<void> deleteCalendarEvent(String bandId, String eventId);
}
