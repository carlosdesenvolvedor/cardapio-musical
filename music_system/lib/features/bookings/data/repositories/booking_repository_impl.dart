import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../datasources/booking_remote_data_source.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> createBooking(BookingEntity booking) async {
    try {
      final model = BookingModel(
        id: booking.id,
        targetId: booking.targetId,
        targetType: booking.targetType,
        contractorId: booking.contractorId,
        date: booking.date,
        status: booking.status,
        price: booking.price,
        notes: booking.notes,
      );
      final id = await remoteDataSource.createBooking(model);
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBookingStatus(
      String bookingId, String status) async {
    try {
      await remoteDataSource.updateBookingStatus(bookingId, status);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getTargetBookings(
      String targetId, String targetType) async {
    try {
      final bookings =
          await remoteDataSource.getTargetBookings(targetId, targetType);
      return Right(bookings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getContractorBookings(
      String contractorId) async {
    try {
      final bookings =
          await remoteDataSource.getContractorBookings(contractorId);
      return Right(bookings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
