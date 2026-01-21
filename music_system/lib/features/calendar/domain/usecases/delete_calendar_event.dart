import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/calendar_repository.dart';

class DeleteCalendarEvent {
  final CalendarRepository repository;

  DeleteCalendarEvent(this.repository);

  Future<Either<Failure, void>> call(String bandId, String eventId) async {
    return await repository.deleteCalendarEvent(bandId, eventId);
  }
}
