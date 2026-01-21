import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.targetId,
    required super.targetType,
    required super.contractorId,
    required super.date,
    required super.status,
    required super.price,
    super.notes,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json, String id) {
    return BookingModel(
      id: id,
      targetId: json['targetId'] ?? '',
      targetType: json['targetType'] ?? 'musician',
      contractorId: json['contractorId'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      status: json['status'] ?? 'pending_approval',
      price: (json['price'] ?? 0.0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetId': targetId,
      'targetType': targetType,
      'contractorId': contractorId,
      'date': Timestamp.fromDate(date),
      'status': status,
      'price': price,
      'notes': notes,
    };
  }
}
