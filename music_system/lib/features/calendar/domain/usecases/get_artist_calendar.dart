import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/calendar_event_entity.dart';
import '../repositories/calendar_repository.dart';

class GetArtistCalendar {
  final CalendarRepository repository;

  GetArtistCalendar(this.repository);

  Future<Either<Failure, List<CalendarEventEntity>>> call(String bandId) async {
    return await repository.getArtistCalendar(bandId);
  }
}
