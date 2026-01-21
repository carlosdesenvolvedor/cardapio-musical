import 'package:equatable/equatable.dart';
import '../../domain/entities/calendar_event_entity.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

class LoadArtistCalendar extends CalendarEvent {
  final String bandId;
  const LoadArtistCalendar(this.bandId);

  @override
  List<Object?> get props => [bandId];
}

class SaveEventRequested extends CalendarEvent {
  final CalendarEventEntity event;
  const SaveEventRequested(this.event);

  @override
  List<Object?> get props => [event];
}

class DeleteEventRequested extends CalendarEvent {
  final String bandId;
  final String eventId;
  const DeleteEventRequested(this.bandId, this.eventId);

  @override
  List<Object?> get props => [bandId, eventId];
}
