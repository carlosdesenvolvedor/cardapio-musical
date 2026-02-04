import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event_entity.dart';

abstract class EventRepository {
  Future<Either<Failure, List<EventEntity>>> getEvents(String userId);
  Future<Either<Failure, void>> createEvent(EventEntity event);
  Future<Either<Failure, void>> updateEvent(EventEntity event);
  Future<Either<Failure, void>> deleteEvent(String eventId, String userId);
  Future<Either<Failure, void>> hireProvider(
      String eventId, String providerId, double cost);
}
