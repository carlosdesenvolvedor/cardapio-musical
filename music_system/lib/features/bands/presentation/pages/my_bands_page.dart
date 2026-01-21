import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/band_bloc.dart';
import 'band_dashboard_page.dart';
import 'create_band_page.dart';

class MyBandsPage extends StatefulWidget {
  const MyBandsPage({super.key});

  @override
  State<MyBandsPage> createState() => _MyBandsPageState();
}

class _MyBandsPageState extends State<MyBandsPage> {
  @override
  void initState() {
    super.initState();
    _loadBands();
  }

  void _loadBands() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<BandBloc>().add(LoadUserBandsEvent(authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Bandas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBands,
          ),
        ],
      ),
      body: BlocBuilder<BandBloc, BandState>(
        builder: (context, state) {
          if (state is BandLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BandLoaded) {
            if (state.bands.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.bands.length,
              itemBuilder: (context, index) {
                final band = state.bands[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.group),
                    ),
                    title: Text(band.name),
                    subtitle: Text(band.profile.genres.join(', ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BandDashboardPage(band: band),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else if (state is BandError) {
            return Center(child: Text('Erro: ${state.message}'));
          }
          return const Center(child: Text('Carregando bandas...'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateBandPage(),
            ),
          );
        },
        label: const Text('Nova Banda'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFFE5B80B),
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_off, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Você ainda não possui bandas.',
            style: TextStyle(fontSize: 18, color: Colors.white54),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateBandPage(),
                ),
              );
            },
            child: const Text('Criar Minha Primeira Banda'),
          ),
        ],
      ),
    );
  }
}
