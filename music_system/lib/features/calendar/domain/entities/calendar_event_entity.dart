import 'package:equatable/equatable.dart';

enum CalendarEventType {
  show,
  rehearsal,
  blocked,
  bookingPending,
  bookingConfirmed,
}

class CalendarEventEntity extends Equatable {
  final String id;
  final String bandId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final CalendarEventType type;
  final bool isPrivate;
  final String? bookingId; // Link to a booking if applicable

  const CalendarEventEntity({
    required this.id,
    required this.bandId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.isPrivate = false,
    this.bookingId,
  });

  @override
  List<Object?> get props => [
        id,
        bandId,
        title,
        description,
        startTime,
        endTime,
        type,
        isPrivate,
        bookingId,
      ];
}
