import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/event_entity.dart';
import '../models/event_model.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_data_source.dart';

class EventRepositoryImpl implements EventRepository {
  final IEventRemoteDataSource remoteDataSource;

  EventRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<EventEntity>>> getEvents(String userId) async {
    try {
      final events = await remoteDataSource.getEvents(userId);
      return Right(events);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createEvent(EventEntity event) async {
    try {
      final model = EventModel(
        id: event.id,
        ownerId: event.ownerId,
        title: event.title,
        description: event.description,
        eventDate: event.eventDate,
        status: event.status,
        questionnaire: event.questionnaire,
        hiredProviderIds: event.hiredProviderIds,
        budgetLimit: event.budgetLimit,
        currentExpenses: event.currentExpenses,
        createdAt: event.createdAt,
      );
      await remoteDataSource.createEvent(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateEvent(EventEntity event) async {
    try {
      final model = EventModel(
        id: event.id,
        ownerId: event.ownerId,
        title: event.title,
        description: event.description,
        eventDate: event.eventDate,
        status: event.status,
        questionnaire: event.questionnaire,
        hiredProviderIds: event.hiredProviderIds,
        budgetLimit: event.budgetLimit,
        currentExpenses: event.currentExpenses,
        createdAt: event.createdAt,
      );
      await remoteDataSource.updateEvent(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvent(
      String eventId, String userId) async {
    try {
      await remoteDataSource.deleteEvent(eventId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> hireProvider(
      String eventId, String providerId, double cost) async {
    try {
      await remoteDataSource.hireProvider(eventId, providerId, cost);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
