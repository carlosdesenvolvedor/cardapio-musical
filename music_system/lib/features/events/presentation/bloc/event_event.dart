import 'package:equatable/equatable.dart';
import '../../domain/entities/event_entity.dart';

abstract class EventEvent extends Equatable {
  const EventEvent();
  @override
  List<Object?> get props => [];
}

class LoadEventsRequested extends EventEvent {
  final String userId;
  const LoadEventsRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class HireProviderRequested extends EventEvent {
  final String eventId;
  final String providerId;
  final double cost;

  const HireProviderRequested({
    required this.eventId,
    required this.providerId,
    required this.cost,
  });

  @override
  List<Object?> get props => [eventId, providerId, cost];
}

class CreateEventRequested extends EventEvent {
  final EventEntity event;
  const CreateEventRequested(this.event);
  @override
  List<Object?> get props => [event];
}

class UpdateEventRequested extends EventEvent {
  final EventEntity event;
  const UpdateEventRequested(this.event);
  @override
  List<Object?> get props => [event];
}

class DeleteEventRequested extends EventEvent {
  final String eventId;
  final String userId;
  const DeleteEventRequested(this.eventId, this.userId);
  @override
  List<Object?> get props => [eventId, userId];
}
