import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/event_bloc.dart';
import '../bloc/event_event.dart';
import '../bloc/event_state.dart';
import '../../domain/entities/event_entity.dart';
import 'create_event_stepper_page.dart';
import 'event_budget_planning_page.dart';

class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    String? userId;
    if (authState is Authenticated) userId = authState.user.id;
    if (authState is ProfileLoaded) userId = authState.profile.id;
    if (userId != null) {
      context.read<EventBloc>().add(LoadEventsRequested(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'EVENTOS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontFamily: 'Outfit',
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: BlocBuilder<EventBloc, EventState>(
              builder: (context, state) {
                if (state.status == EventStatus.loading) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor));
                }
                if (state.events.isEmpty) {
                  if (state.status == EventStatus.failure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage ?? 'Erro ao carregar eventos',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              final authState = context.read<AuthBloc>().state;
                              String? userId;
                              if (authState is Authenticated)
                                userId = authState.user.id;
                              if (authState is ProfileLoaded)
                                userId = authState.profile.id;
                              if (userId != null) {
                                context
                                    .read<EventBloc>()
                                    .add(LoadEventsRequested(userId));
                              }
                            },
                            child: const Text('TENTAR NOVAMENTE',
                                style: TextStyle(color: AppTheme.primaryColor)),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.events.length,
                  itemBuilder: (context, index) {
                    final event = state.events[index];
                    return _buildEventCard(event);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateEventStepperPage()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('NOVO',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Categoria'),
          _buildFilterChip('Preço'),
          _buildFilterChip('Prazo'),
          _buildFilterChip('Distante'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        backgroundColor: const Color(0xFF1A1A1A),
        side: BorderSide(color: Colors.white.withAlpha(25)),
        label: Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note,
              size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('Nenhum evento criado ainda',
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventEntity event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const EventBudgetPlanningPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(12)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(event.description,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  _buildActionButtons(),
                ],
              ),
            ),
            _buildEventInfoBar(event),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _miniActionButton(Icons.remove_red_eye),
        const SizedBox(height: 4),
        _miniActionButton(Icons.print),
        const SizedBox(height: 4),
        _miniActionButton(Icons.more_horiz),
      ],
    );
  }

  Widget _miniActionButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: AppTheme.primaryColor, size: 16),
    );
  }

  Widget _buildEventInfoBar(EventEntity event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _infoItem('Data', DateFormat('dd/MM').format(event.eventDate)),
          _infoItem('Status', event.status.toUpperCase()),
          _infoItem('Orçamento', 'R\$ ${event.budgetLimit.toInt()}'),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white24, fontSize: 10)),
        Text(value,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
