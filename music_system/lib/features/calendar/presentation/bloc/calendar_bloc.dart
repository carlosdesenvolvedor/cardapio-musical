import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_artist_calendar.dart';
import '../../domain/usecases/save_calendar_event.dart';
import '../../domain/usecases/delete_calendar_event.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final GetArtistCalendar getArtistCalendar;
  final SaveCalendarEvent saveCalendarEvent;
  final DeleteCalendarEvent deleteCalendarEvent;

  CalendarBloc({
    required this.getArtistCalendar,
    required this.saveCalendarEvent,
    required this.deleteCalendarEvent,
  }) : super(CalendarInitial()) {
    on<LoadArtistCalendar>((event, emit) async {
      emit(CalendarLoading());
      final result = await getArtistCalendar(event.bandId);
      result.fold(
        (failure) => emit(CalendarError(failure.message)),
        (events) => emit(CalendarLoaded(events)),
      );
    });

    on<SaveEventRequested>((event, emit) async {
      emit(CalendarLoading());
      final result = await saveCalendarEvent(event.event);
      result.fold(
        (failure) => emit(CalendarError(failure.message)),
        (_) {
          emit(const CalendarOperationSuccess('Evento salvo com sucesso!'));
          add(LoadArtistCalendar(event.event.bandId));
        },
      );
    });

    on<DeleteEventRequested>((event, emit) async {
      emit(CalendarLoading());
      final result = await deleteCalendarEvent(event.bandId, event.eventId);
      result.fold(
        (failure) => emit(CalendarError(failure.message)),
        (_) {
          emit(const CalendarOperationSuccess('Evento excluído com sucesso!'));
          add(LoadArtistCalendar(event.bandId));
        },
      );
    });
  }
}
