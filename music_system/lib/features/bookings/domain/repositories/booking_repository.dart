import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';

abstract class BookingRepository {
  Future<Either<Failure, String>> createBooking(BookingEntity booking);
  Future<Either<Failure, void>> updateBookingStatus(
      String bookingId, String status);
  Future<Either<Failure, List<BookingEntity>>> getTargetBookings(
      String targetId, String targetType);
  Future<Either<Failure, List<BookingEntity>>> getContractorBookings(
      String contractorId);
}
