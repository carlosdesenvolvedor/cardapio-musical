import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../calendar/domain/entities/calendar_event_entity.dart';
import '../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../../calendar/presentation/bloc/calendar_event.dart';
import '../../../calendar/presentation/bloc/calendar_state.dart';

class PublicAgendaView extends StatefulWidget {
  final String bandId;
  final Function(DateTime selectedDate)? onDateSelected;

  const PublicAgendaView({
    super.key,
    required this.bandId,
    this.onDateSelected,
  });

  @override
  State<PublicAgendaView> createState() => _PublicAgendaViewState();
}

class _PublicAgendaViewState extends State<PublicAgendaView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEventEntity> _allEvents = [];

  @override
  void initState() {
    super.initState();
    context.read<CalendarBloc>().add(LoadArtistCalendar(widget.bandId));
  }

  List<CalendarEventEntity> _getEventsForDay(DateTime day) {
    return _allEvents.where((event) {
      return isSameDay(event.startTime, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoaded) {
          _allEvents = state.events;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agenda de Disponibilidade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.white.withOpacity(0.05),
              child: TableCalendar(
                locale: 'pt_BR',
                firstDay: DateTime.now(),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.twoWeeks,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  if (widget.onDateSelected != null) {
                    widget.onDateSelected!(selectedDay);
                  }
                },
                eventLoader: _getEventsForDay,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFFE5B80B),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            if (_selectedDay != null) _buildSelectedDayEvents(),
          ],
        );
      },
    );
  }

  Widget _buildSelectedDayEvents() {
    final dayEvents = _getEventsForDay(_selectedDay!);
    if (dayEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Data livre! Entre em contato para reservar.',
            style: TextStyle(color: Colors.greenAccent)),
      );
    }

    return Column(
      children: dayEvents.map((event) {
        final title = event.isPrivate ? 'OCUPADO' : event.title;
        return ListTile(
          dense: true,
          leading:
              const Icon(Icons.event_busy, color: Colors.redAccent, size: 20),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - '
            '${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
          ),
        );
      }).toList(),
    );
  }
}
