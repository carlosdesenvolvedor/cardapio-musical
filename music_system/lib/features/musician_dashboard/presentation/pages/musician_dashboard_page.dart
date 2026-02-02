import 'package:flutter/material.dart';
import 'package:music_system/main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'share_page.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:music_system/features/auth/domain/entities/user_entity.dart';
import 'package:music_system/features/smart_lyrics/presentation/pages/lyrics_view_page.dart';
import 'package:music_system/features/song_requests/domain/entities/song_request.dart';
import 'package:music_system/features/song_requests/presentation/bloc/song_request_bloc.dart';
import 'package:music_system/features/song_requests/presentation/bloc/song_request_event.dart';
import 'package:music_system/features/song_requests/presentation/bloc/song_request_state.dart';
import 'package:music_system/features/service_provider/presentation/pages/service_provider_dashboard_page.dart';

class MusicianDashboardPage extends StatefulWidget {
  const MusicianDashboardPage({super.key});

  @override
  State<MusicianDashboardPage> createState() => _MusicianDashboardPageState();
}

class _MusicianDashboardPageState extends State<MusicianDashboardPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    String? userId;
    if (authState is Authenticated) {
      userId = authState.user.id;
    } else if (authState is ProfileLoaded) {
      userId = authState.currentUser?.id;
    }

    if (userId != null) {
      context.read<SongRequestBloc>().add(FetchSongRequests(userId));
      context.read<AuthBloc>().add(ProfileRequested(userId));
    }
  }

  UserEntity? _getCurrentUser(AuthState state) {
    if (state is Authenticated) return state.user;
    if (state is ProfileLoaded) return state.currentUser;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFE5B80B)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_graph, size: 40, color: Colors.black),
                    SizedBox(height: 10),
                    Text(
                      'PAINEL ESTRATÉGICO',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calculate, color: Color(0xFFE5B80B)),
              title: const Text('Meu Cachê'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/artist-cache');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.business_center, color: Color(0xFFE5B80B)),
              title: const Text('Meus Serviços'),
              onTap: () {
                Navigator.pop(context);
                final user = _getCurrentUser(context.read<AuthBloc>().state);
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ServiceProviderDashboardPage(providerId: user.id),
                    ),
                  );
                }
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFFE5B80B)),
              title: const Text('Voltar para Rede'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                    context, '/network', (route) => false);
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Sair',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                context.read<AuthBloc>().add(SignOutRequested());
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Painel do Músico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'Link do Cardápio',
            onPressed: () {
              final user = _getCurrentUser(context.read<AuthBloc>().state);
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SharePage(userId: user.id),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Voltar para Rede',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/network', (route) => false);
            },
          ),
        ],
      ),
      body: BlocListener<SongRequestBloc, SongRequestState>(
        listenWhen: (previous, current) {
          if (previous is SongRequestsLoaded && current is SongRequestsLoaded) {
            // Alert only if a NEW request was added (count increased)
            return current.requests.length > previous.requests.length;
          }
          return false;
        },
        listener: (context, state) {
          if (state is SongRequestsLoaded) {
            final newRequest = state.requests.first; // Stream handles ordering
            messengerKey.currentState?.removeCurrentSnackBar();
            messengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Novo Pedido: ${newRequest.songName}!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFE5B80B),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Ver',
                  textColor: Colors.white,
                  onPressed: () {
                    // Page is already listing it at the top
                  },
                ),
              ),
            );
          }
        },
        child: BlocBuilder<SongRequestBloc, SongRequestState>(
          builder: (context, state) {
            if (state is SongRequestLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SongRequestsLoaded) {
              if (state.requests.isEmpty) {
                return const Center(child: Text('Nenhum pedido na fila.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.requests.length,
                itemBuilder: (context, index) {
                  final request = state.requests[index];
                  return _RequestDashboardCard(request: request);
                },
              );
            } else if (state is SongRequestError) {
              return Center(child: Text('Erro: ${state.message}'));
            }
            return const Center(child: Text('Aguardando pedidos...'));
          },
        ),
      ),
    );
  }
}

class _RequestDashboardCard extends StatelessWidget {
  final SongRequest request;

  const _RequestDashboardCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final bool hasTip = request.tipAmount > 0;
    final bool isPending = request.status == 'pending';
    final bool isAccepted = request.status == 'accepted';
    final bool isDeclined = request.status == 'declined';

    Color statusColor;
    if (isAccepted) {
      statusColor = Colors.green;
    } else if (isDeclined) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: isPending
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.songName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.artistName,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (hasTip)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5B80B).withOpacity(0.2), // Yellow
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5B80B)),
                    ),
                    child: Text(
                      'R\$ ${request.tipAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFE5B80B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Delete Button
                if (!isPending) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    tooltip: 'Apagar pedido do histórico',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Apagar Pedido'),
                          content: const Text(
                            'Tem certeza que deseja remover este pedido do histórico?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<SongRequestBloc>().add(
                                      DeleteSongRequestEvent(request.id),
                                    );
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Apagar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  request.clientName ?? 'Anônimo',
                  style: const TextStyle(color: Colors.white54),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPending
                        ? 'Pendente'
                        : (isAccepted ? 'Aceito' : 'Recusado'),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(request.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPending) ...[
                  TextButton(
                    onPressed: () {
                      context.read<SongRequestBloc>().add(
                            UpdateSongRequestStatus(request.id, 'declined'),
                          );
                    },
                    child: const Text(
                      'Recusar',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5B80B),
                      foregroundColor: Colors.black, // Dark text on yellow
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Aceitar'),
                    onPressed: () {
                      context.read<SongRequestBloc>().add(
                            UpdateSongRequestStatus(request.id, 'accepted'),
                          );
                    },
                  ),
                ],
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LyricsViewPage(
                          songName: request.songName,
                          artist: request.artistName,
                        ),
                      ),
                    );
                  },
                  child: const Text('Ver Cifra'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
