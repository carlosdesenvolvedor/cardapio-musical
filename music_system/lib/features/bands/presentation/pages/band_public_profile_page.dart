import 'package:flutter/material.dart';
import '../../domain/entities/band_entity.dart';
import '../../domain/entities/band_member_entity.dart';
import '../bloc/band_bloc.dart';
import '../../../../injection_container.dart';
import '../widgets/public_agenda_view.dart';

class BandPublicProfilePage extends StatefulWidget {
  final String slug;
  const BandPublicProfilePage({super.key, required this.slug});

  @override
  State<BandPublicProfilePage> createState() => _BandPublicProfilePageState();
}

class _BandPublicProfilePageState extends State<BandPublicProfilePage> {
  BandEntity? _band;
  List<BandMemberEntity> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBandData();
  }

  Future<void> _fetchBandData() async {
    final repo = sl<BandBloc>().repository;
    final result = await repo.getBandBySlug(widget.slug);

    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isLoading = false;
      }),
      (band) async {
        setState(() {
          _band = band;
        });

        final membersResult = await repo.getBandMembers(band.id);
        membersResult.fold(
          (_) => null,
          (members) => setState(() {
            _members = members;
          }),
        );

        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _band == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erro: ${_error ?? "Banda não encontrada"}')),
      );
    }

    final band = _band!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(band.name),
              background: Container(
                color: Colors.black54,
                child: const Icon(Icons.group, size: 80, color: Colors.white24),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: band.profile.genres
                        .map((g) => Chip(label: Text(g)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sobre a Banda',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(band.profile.description),
                  if (band.profile.biography != null) ...[
                    const SizedBox(height: 16),
                    Text(band.profile.biography!),
                  ],
                  PublicAgendaView(
                    bandId: band.id,
                    onDateSelected: (date) {
                      // Optional: Update booking date automatically
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Integrantes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._members.map((m) => ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(m.userName ?? 'Músico'),
                        subtitle: Text(m.instrument ?? 'Instrumento'),
                      )),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5B80B),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        // TODO: Implement Booking flow
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Fluxo de reserva em breve!')),
                        );
                      },
                      child: const Text('SOLICITAR ORÇAMENTO / RESERVA'),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
