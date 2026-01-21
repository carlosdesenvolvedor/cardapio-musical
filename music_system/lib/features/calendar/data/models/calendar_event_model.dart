import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/calendar_event_entity.dart';

class CalendarEventModel extends CalendarEventEntity {
  const CalendarEventModel({
    required super.id,
    required super.bandId,
    required super.title,
    super.description,
    required super.startTime,
    required super.endTime,
    required super.type,
    super.isPrivate,
    super.bookingId,
  });

  factory CalendarEventModel.fromEntity(CalendarEventEntity entity) {
    return CalendarEventModel(
      id: entity.id,
      bandId: entity.bandId,
      title: entity.title,
      description: entity.description,
      startTime: entity.startTime,
      endTime: entity.endTime,
      type: entity.type,
      isPrivate: entity.isPrivate,
      bookingId: entity.bookingId,
    );
  }

  factory CalendarEventModel.fromJson(Map<String, dynamic> json, String id) {
    return CalendarEventModel(
      id: id,
      bandId: json['bandId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: (json['endTime'] as Timestamp).toDate(),
      type: CalendarEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CalendarEventType.show,
      ),
      isPrivate: json['isPrivate'] ?? false,
      bookingId: json['bookingId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bandId': bandId,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'type': type.name,
      'isPrivate': isPrivate,
      'bookingId': bookingId,
    };
  }
}
