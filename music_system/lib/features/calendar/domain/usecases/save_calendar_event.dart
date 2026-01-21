import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/calendar_event_entity.dart';
import '../repositories/calendar_repository.dart';

class SaveCalendarEvent {
  final CalendarRepository repository;

  SaveCalendarEvent(this.repository);

  Future<Either<Failure, void>> call(CalendarEventEntity event) async {
    return await repository.saveCalendarEvent(event);
  }
}
