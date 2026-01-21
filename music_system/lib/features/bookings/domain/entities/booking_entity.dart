import 'package:equatable/equatable.dart';

class BookingEntity extends Equatable {
  final String id;
  final String targetId; // bandId or musicianId
  final String targetType; // band, musician
  final String contractorId;
  final DateTime date;
  final String status; // pending_approval, confirmed, completed, cancelled
  final double price;
  final String? notes;

  const BookingEntity({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.contractorId,
    required this.date,
    required this.status,
    required this.price,
    this.notes,
  });

  @override
  List<Object?> get props =>
      [id, targetId, targetType, contractorId, date, status, price, notes];
}
