import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'manage_repertoire_page.dart';
import 'share_page.dart';
import 'artist_insights_page.dart';
import '../../../bands/presentation/pages/my_bands_page.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:music_system/features/auth/presentation/pages/profile_page.dart';
import 'package:music_system/features/smart_lyrics/presentation/pages/lyrics_view_page.dart';
import 'package:music_system/features/song_requests/domain/entities/song_request.dart';
import 'package:music_system/features/song_requests/presentation/bloc/song_request_bloc.dart';
import 'package:music_system/features/song_requests/presentation/bloc/song_request_event.dart';
import 'package:music_system/features/song_requests/presentation/bloc/song_request_state.dart';

import 'package:music_system/core/services/notification_service.dart';
import 'package:music_system/injection_container.dart';
import 'package:music_system/features/live/presentation/pages/live_page.dart';

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
    if (authState is Authenticated) {
      context.read<SongRequestBloc>().add(FetchSongRequests(authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: Column(
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
              leading: const Icon(Icons.analytics, color: Color(0xFFE5B80B)),
              title: const Text('Insights & Estatísticas'),
              subtitle: const Text(
                'IA Feedback Ready',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ArtistInsightsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFFE5B80B)),
              title: const Text('Meu Perfil'),
              onTap: () {
                Navigator.pop(context);
                final authState = context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        userId: authState.user.id,
                        email: authState.user.email,
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.library_music,
                color: Color(0xFFE5B80B),
              ),
              title: const Text('Gerenciar Repertório'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageRepertoirePage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Color(0xFFE5B80B)),
              title: const Text('Minhas Bandas'),
              subtitle: const Text(
                'Gestão de Equipe & Agenda',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyBandsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.live_tv, color: Colors.redAccent),
              title: const Text('Iniciar Transmissão'),
              subtitle: const Text(
                'Modo Músico (High Quality)',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              onTap: () {
                Navigator.pop(context);
                final authState = context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LivePage(
                        liveId: authState.user.id,
                        isHost: true,
                        userId: authState.user.id,
                        userName: authState.user.displayName,
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications_active,
                color: Color(0xFFE5B80B),
              ),
              title: const Text('Ativar Notificações'),
              onTap: () async {
                Navigator.pop(context);
                await sl<PushNotificationService>().initialize();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tentando ativar notificações... Verifique o pop-up do navegador.',
                      ),
                    ),
                  );
                }
              },
            ),
            const Spacer(),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Sair',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(SignOutRequested());
                Navigator.of(context).popUntil((route) => route.isFirst);
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
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SharePage(userId: authState.user.id),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(SignOutRequested());
              Navigator.of(context).popUntil((route) => route.isFirst);
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
            ScaffoldMessenger.of(context).showSnackBar(
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
