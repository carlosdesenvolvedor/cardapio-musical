import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../calendar/domain/entities/calendar_event_entity.dart';
import '../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../../calendar/presentation/bloc/calendar_event.dart';
import '../../../calendar/presentation/bloc/calendar_state.dart';
import '../../domain/entities/band_entity.dart';

class ManageAgendaPage extends StatefulWidget {
  final BandEntity band;
  const ManageAgendaPage({super.key, required this.band});

  @override
  State<ManageAgendaPage> createState() => _ManageAgendaPageState();
}

class _ManageAgendaPageState extends State<ManageAgendaPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEventEntity> _allEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    context.read<CalendarBloc>().add(LoadArtistCalendar(widget.band.id));
  }

  List<CalendarEventEntity> _getEventsForDay(DateTime day) {
    return _allEvents.where((event) {
      return isSameDay(event.startTime, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CalendarBloc, CalendarState>(
      listener: (context, state) {
        if (state is CalendarOperationSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is CalendarError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        if (state is CalendarLoaded) {
          _allEvents = state.events;
        }

        return Scaffold(
          body: Column(
            children: [
              TableCalendar<CalendarEventEntity>(
                locale: 'pt_BR',
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                eventLoader: _getEventsForDay,
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFFE5B80B),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const Divider(),
              Expanded(
                child: _buildEventList(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEventDialog(),
            backgroundColor: const Color(0xFFE5B80B),
            child: const Icon(Icons.add, color: Colors.black),
          ),
        );
      },
    );
  }

  Widget _buildEventList() {
    final dayEvents = _getEventsForDay(_selectedDay ?? _focusedDay);
    if (dayEvents.isEmpty) {
      return const Center(child: Text('Nenhum evento neste dia.'));
    }

    return ListView.builder(
      itemCount: dayEvents.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        return Card(
          color: Colors.white12,
          child: ListTile(
            leading: _getEventIcon(event.type),
            title: Text(event.title),
            subtitle: Text(
              '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => context.read<CalendarBloc>().add(
                    DeleteEventRequested(widget.band.id, event.id),
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _getEventIcon(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.show:
        return const Icon(Icons.music_note, color: Color(0xFFE5B80B));
      case CalendarEventType.rehearsal:
        return const Icon(Icons.mic, color: Colors.blueAccent);
      case CalendarEventType.blocked:
        return const Icon(Icons.block, color: Colors.redAccent);
      default:
        return const Icon(Icons.event, color: Colors.white70);
    }
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 20, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 22, minute: 0);
    CalendarEventType selectedType = CalendarEventType.show;
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adicionar Evento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                DropdownButtonFormField<CalendarEventType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: CalendarEventType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                ListTile(
                  title: const Text('Início'),
                  trailing: Text(startTime.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: startTime);
                    if (picked != null) {
                      setDialogState(() => startTime = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Fim'),
                  trailing: Text(endTime.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: endTime);
                    if (picked != null) {
                      setDialogState(() => endTime = picked);
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Privado?'),
                  subtitle: const Text('Ocultar detalhes do público'),
                  value: isPrivate,
                  onChanged: (val) => setDialogState(() => isPrivate = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final start = DateTime(
                  _selectedDay!.year,
                  _selectedDay!.month,
                  _selectedDay!.day,
                  startTime.hour,
                  startTime.minute,
                );
                final end = DateTime(
                  _selectedDay!.year,
                  _selectedDay!.month,
                  _selectedDay!.day,
                  endTime.hour,
                  endTime.minute,
                );

                if (titleController.text.isNotEmpty) {
                  // Conflict check
                  final hasConflict = _allEvents.any((e) =>
                      isSameDay(e.startTime, start) &&
                      start.isBefore(e.endTime) &&
                      end.isAfter(e.startTime));

                  if (hasConflict) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Conflito de horário detectado!')),
                    );
                    return;
                  }

                  final event = CalendarEventEntity(
                    id: '', // Firestore will generate
                    bandId: widget.band.id,
                    title: titleController.text,
                    startTime: start,
                    endTime: end,
                    type: selectedType,
                    isPrivate: isPrivate,
                  );
                  context.read<CalendarBloc>().add(SaveEventRequested(event));
                  Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
