import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<String> createBooking(BookingModel booking);
  Future<void> updateBookingStatus(String bookingId, String status);
  Future<List<BookingModel>> getTargetBookings(
      String targetId, String targetType);
  Future<List<BookingModel>> getContractorBookings(String contractorId);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final FirebaseFirestore firestore;

  BookingRemoteDataSourceImpl({required this.firestore});

  @override
  Future<String> createBooking(BookingModel booking) async {
    final docRef = await firestore.collection('bookings').add(booking.toJson());
    return docRef.id;
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await firestore
        .collection('bookings')
        .doc(bookingId)
        .update({'status': status});
  }

  @override
  Future<List<BookingModel>> getTargetBookings(
      String targetId, String targetType) async {
    final query = await firestore
        .collection('bookings')
        .where('targetId', isEqualTo: targetId)
        .where('targetType', isEqualTo: targetType)
        .get();
    return query.docs
        .map((doc) => BookingModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<BookingModel>> getContractorBookings(String contractorId) async {
    final query = await firestore
        .collection('bookings')
        .where('contractorId', isEqualTo: contractorId)
        .get();
    return query.docs
        .map((doc) => BookingModel.fromJson(doc.data(), doc.id))
        .toList();
  }
}
