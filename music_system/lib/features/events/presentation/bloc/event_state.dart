import 'package:equatable/equatable.dart';
import '../../domain/entities/event_entity.dart';

enum EventStatus { initial, loading, success, failure }

class EventState extends Equatable {
  final EventStatus status;
  final List<EventEntity> events;
  final String? errorMessage;

  const EventState({
    this.status = EventStatus.initial,
    this.events = const [],
    this.errorMessage,
  });

  EventState copyWith({
    EventStatus? status,
    List<EventEntity>? events,
    String? errorMessage,
  }) {
    return EventState(
      status: status ?? this.status,
      events: events ?? this.events,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, events, errorMessage];
}
