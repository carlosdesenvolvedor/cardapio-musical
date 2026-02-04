import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/event_repository.dart';
import 'event_event.dart';
import 'event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventRepository repository;

  EventBloc({required this.repository}) : super(const EventState()) {
    on<LoadEventsRequested>(_onLoadEventsRequested);
    on<CreateEventRequested>(_onCreateEventRequested);
    on<UpdateEventRequested>(_onUpdateEventRequested);
    on<DeleteEventRequested>(_onDeleteEventRequested);
    on<HireProviderRequested>(_onHireProviderRequested);
  }

  Future<void> _onLoadEventsRequested(
      LoadEventsRequested event, Emitter<EventState> emit) async {
    emit(state.copyWith(status: EventStatus.loading));
    final result = await repository.getEvents(event.userId);
    result.fold(
      (failure) {
        print('ERRO AO CARREGAR EVENTOS: ${failure.message}');
        emit(state.copyWith(
            status: EventStatus.failure, errorMessage: failure.message));
      },
      (events) {
        print('EVENTOS CARREGADOS COM SUCESSO: ${events.length} encontrados');
        emit(state.copyWith(status: EventStatus.success, events: events));
      },
    );
  }

  Future<void> _onCreateEventRequested(
      CreateEventRequested event, Emitter<EventState> emit) async {
    final result = await repository.createEvent(event.event);
    result.fold(
      (failure) {
        print('ERRO AO CRIAR EVENTO: ${failure.message}');
        emit(state.copyWith(status: EventStatus.failure));
      },
      (_) {
        print(
            'EVENTO CRIADO COM SUCESSO. Recarregando lista para ownerId: ${event.event.ownerId}');
        add(LoadEventsRequested(event.event.ownerId));
      },
    );
  }

  Future<void> _onUpdateEventRequested(
      UpdateEventRequested event, Emitter<EventState> emit) async {
    final result = await repository.updateEvent(event.event);
    result.fold(
      (failure) => emit(state.copyWith(
          status: EventStatus.failure, errorMessage: failure.message)),
      (_) => add(LoadEventsRequested(event.event.ownerId)),
    );
  }

  Future<void> _onDeleteEventRequested(
      DeleteEventRequested event, Emitter<EventState> emit) async {
    // Busca o evento para calcular multa se necessário
    final targetEvent = state.events.firstWhere((e) => e.id == event.eventId);
    final daysToEvent = targetEvent.eventDate.difference(DateTime.now()).inDays;

    if (daysToEvent < 7 && targetEvent.hiredProviderIds.isNotEmpty) {
      // TODO: Emitir um estado especial ou showDialog antes de prosseguir
      // Por enquanto, apenas logamos a penalidade potencial
      print('Aviso: Cancelamento com menos de 7 dias pode gerar multas.');
    }

    final result = await repository.deleteEvent(event.eventId, event.userId);
    result.fold(
      (failure) => emit(state.copyWith(
          status: EventStatus.failure, errorMessage: failure.message)),
      (_) => add(LoadEventsRequested(event.userId)),
    );
  }

  Future<void> _onHireProviderRequested(
      HireProviderRequested event, Emitter<EventState> emit) async {
    final result = await repository.hireProvider(
        event.eventId, event.providerId, event.cost);
    result.fold(
      (failure) => emit(state.copyWith(
          status: EventStatus.failure, errorMessage: failure.message)),
      (_) {
        // Encontra o evento localmente para saber quem é o owner e recarregar
        final currentEvent =
            state.events.firstWhere((e) => e.id == event.eventId);
        add(LoadEventsRequested(currentEvent.ownerId));
      },
    );
  }
}
