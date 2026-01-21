import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../datasources/calendar_remote_data_source.dart';
import '../../domain/entities/calendar_event_entity.dart';
import '../models/calendar_event_model.dart';
import '../../domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource remoteDataSource;

  CalendarRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CalendarEventEntity>>> getArtistCalendar(
      String bandId) async {
    try {
      final events = await remoteDataSource.getArtistCalendar(bandId);
      return Right(events);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveCalendarEvent(
      CalendarEventEntity event) async {
    try {
      final model = CalendarEventModel.fromEntity(event);
      await remoteDataSource.saveCalendarEvent(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCalendarEvent(
      String bandId, String eventId) async {
    try {
      await remoteDataSource.deleteCalendarEvent(bandId, eventId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
