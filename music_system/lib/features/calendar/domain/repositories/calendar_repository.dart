import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/calendar_event_entity.dart';

abstract class CalendarRepository {
  Future<Either<Failure, List<CalendarEventEntity>>> getArtistCalendar(
      String bandId);
  Future<Either<Failure, void>> saveCalendarEvent(CalendarEventEntity event);
  Future<Either<Failure, void>> deleteCalendarEvent(
      String bandId, String eventId);
}
