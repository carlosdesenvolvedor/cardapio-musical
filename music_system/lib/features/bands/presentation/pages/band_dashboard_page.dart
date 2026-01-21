import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/band_entity.dart';
import '../../domain/entities/band_member_entity.dart';
import '../bloc/band_bloc.dart';
import 'manage_agenda_page.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/domain/entities/user_profile.dart';

class BandDashboardPage extends StatefulWidget {
  final BandEntity band;
  const BandDashboardPage({super.key, required this.band});

  @override
  State<BandDashboardPage> createState() => _BandDashboardPageState();
}

class _BandDashboardPageState extends State<BandDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<BandBloc>().add(LoadBandMembersEvent(widget.band.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.band.name),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE5B80B),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Visão Geral'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Agenda'),
            Tab(icon: Icon(Icons.people), text: 'Membros'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAgendaTab(),
          _buildMembersTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          const Text(
            'Bio / Descriçao',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(widget.band.profile.description),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final isPro = widget.band.subscription.planId == 'pro_monthly';
    return Card(
      color: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status da Assinatura'),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.band.subscription.status.toUpperCase(),
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Plano Atual'),
                Text(
                  isPro ? 'PRO (Ser Vista)' : 'BÁSICO (Existir)',
                  style: TextStyle(
                    color: isPro ? const Color(0xFFE5B80B) : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaTab() {
    return ManageAgendaPage(band: widget.band);
  }

  Widget _buildMembersTab() {
    return BlocBuilder<BandBloc, BandState>(
      builder: (context, state) {
        if (state is BandMembersLoaded) {
          return Column(
            children: [
              _buildInviteHeader(),
              Expanded(
                child: ListView.builder(
                  itemCount: state.members.length,
                  itemBuilder: (context, index) {
                    final member = state.members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: member.userPhotoUrl != null
                            ? NetworkImage(member.userPhotoUrl!)
                            : null,
                        child: member.userPhotoUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(member.userName ?? member.userId),
                      subtitle: Text(member.instrument ?? 'Músico'),
                      trailing: _buildStatusBadge(member.status),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildInviteHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.person_add),
        label: const Text('Convidar Músico'),
        onPressed: _showInviteDialog,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'ATIVO';
        break;
      case 'pending_invite':
        color = Colors.orange;
        label = 'PENDENTE';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showInviteDialog() {
    final instrumentController = TextEditingController();
    final artistNameController = TextEditingController();
    String? selectedUserId;
    String? selectedPhotoUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Convidar Músico'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TypeAheadField<UserProfile>(
                controller: artistNameController,
                builder: (context, controller, focusNode) => TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Buscar Músico (Nome Artístico)',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  if (pattern.length < 2) return [];

                  final query = await FirebaseFirestore.instance
                      .collection('users')
                      .where('artisticName', isGreaterThanOrEqualTo: pattern)
                      .where('artisticName',
                          isLessThanOrEqualTo: pattern + '\uf8ff')
                      .limit(5)
                      .get();

                  return query.docs.map((doc) {
                    final data = doc.data();
                    return UserProfile(
                      id: doc.id,
                      email: data['email'] ?? '',
                      artisticName: data['artisticName'] ?? 'Sem Nome',
                      pixKey: data['pixKey'] ?? '',
                      photoUrl: data['photoUrl'],
                      followersCount: data['followersCount'] ?? 0,
                      followingCount: data['followingCount'] ?? 0,
                      profileViewsCount: data['profileViewsCount'] ?? 0,
                      isLive: data['isLive'] ?? false,
                    );
                  }).toList();
                },
                itemBuilder: (context, profile) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile.photoUrl != null
                          ? CachedNetworkImageProvider(profile.photoUrl!)
                          : null,
                      child: profile.photoUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(profile.artisticName),
                    subtitle: Text(profile.email),
                  );
                },
                onSelected: (profile) {
                  setDialogState(() {
                    artistNameController.text = profile.artisticName;
                    selectedUserId = profile.id;
                    selectedPhotoUrl = profile.photoUrl;
                  });
                },
                emptyBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Nenhum músico encontrado.'),
                ),
              ),
              const SizedBox(height: 16),
              if (selectedUserId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'ID Selecionado: $selectedUserId',
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ),
              TextField(
                controller: instrumentController,
                decoration: const InputDecoration(
                    labelText: 'Instrumento (ex: Guitarra)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (selectedUserId != null) {
                  final member = BandMemberEntity(
                    userId: selectedUserId!,
                    role: 'member',
                    status: 'pending_invite',
                    instrument: instrumentController.text,
                    userName: artistNameController.text,
                    userPhotoUrl: selectedPhotoUrl,
                  );
                  context
                      .read<BandBloc>()
                      .add(InviteMemberEvent(widget.band.id, member));
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Selecione um músico da lista!')),
                  );
                }
              },
              child: const Text('Convidar'),
            ),
          ],
        ),
      ),
    );
  }
}
