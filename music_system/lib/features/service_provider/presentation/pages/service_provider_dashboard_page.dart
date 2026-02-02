import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/service_entity.dart';
import '../bloc/service_dashboard_bloc.dart';
import '../pages/service_category_selection_page.dart';
import '../pages/service_registration_form_page.dart';
import '../pages/service_preview_page.dart';
import 'package:get_it/get_it.dart';

class ServiceProviderDashboardPage extends StatelessWidget {
  final String providerId;

  const ServiceProviderDashboardPage({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<ServiceDashboardBloc>()
        ..add(FetchServices(providerId)),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFF101010),
            appBar: AppBar(
              title: const Text(
                'MEUS SERVIÇOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: 'Outfit',
                  fontSize: 16,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  Expanded(
                    child: BlocBuilder<ServiceDashboardBloc,
                        ServiceDashboardState>(
                      builder: (context, state) {
                        if (state is ServiceDashboardLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFC107),
                            ),
                          );
                        } else if (state is ServiceDashboardLoaded) {
                          if (state.services.isEmpty) {
                            return _buildEmptyState();
                          }
                          return _buildServiceList(context, state.services);
                        } else if (state is ServiceDashboardError) {
                          return Center(
                            child: Text(
                              state.message,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Painel de Controle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gerencie seus serviços e propostas',
                style: TextStyle(color: Colors.white54),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceCategorySelectionPage(
                  providerId: providerId,
                ),
              ),
            ).then((_) {
              // Refresh list when returning
              // ignore: use_build_context_synchronously
              if (context.mounted) {
                context
                    .read<ServiceDashboardBloc>()
                    .add(FetchServices(providerId));
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text(
            'Novo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Nenhum serviço cadastrado ainda.',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList(BuildContext context, List<ServiceEntity> services) {
    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(context, service);
      },
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceEntity service) {
    Color statusColor;
    String statusText;

    switch (service.status) {
      case ServiceStatus.active:
        statusColor = Colors.greenAccent;
        statusText = 'Ativo';
        break;
      case ServiceStatus.pending:
        statusColor = Colors.orangeAccent;
        statusText = 'Pendente';
        break;
      case ServiceStatus.rejected:
        statusColor = Colors.redAccent;
        statusText = 'Rejeitado';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForCategory(service.category),
              color: const Color(0xFFFFC107),
              size: 30,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.category.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Progresso',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: service.status == ServiceStatus.active
                              ? 1.0
                              : 0.4,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              service.status == ServiceStatus.active
                                  ? const Color(0xFFFFC107)
                                  : Colors.white24),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      service.status == ServiceStatus.active ? '100%' : '40%',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (service.status == ServiceStatus.pending)
                TextButton(
                  onPressed: () {
                    context.read<ServiceDashboardBloc>().add(
                          UpdateStatus(
                            providerId: providerId,
                            serviceId: service.id,
                            status: ServiceStatus.active,
                          ),
                        );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107).withOpacity(0.1),
                    foregroundColor: const Color(0xFFFFC107),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Confirmar',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white54),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(context, service);
                    } else if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceRegistrationFormPage(
                            category: service.category,
                            providerId: providerId,
                            initialService: service,
                          ),
                        ),
                      );
                    } else if (value == 'preview') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServicePreviewPage(
                            service: service,
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'preview',
                      child: Row(
                        children: [
                          Icon(Icons.visibility,
                              size: 20, color: Color(0xFFFFC107)),
                          SizedBox(width: 8),
                          Text('Ver Prévia'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ServiceEntity service) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Serviço'),
        content:
            Text('Tem certeza que deseja excluir o serviço "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<ServiceDashboardBloc>().add(
                    DeleteServiceEvent(
                      providerId: providerId,
                      serviceId: service.id,
                    ),
                  );
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.artist:
        return Icons.mic;
      case ServiceCategory.infrastructure:
        return Icons.speaker_group;
      case ServiceCategory.catering:
        return Icons.restaurant;
      case ServiceCategory.security:
        return Icons.verified_user;
      case ServiceCategory.media:
        return Icons.camera_alt;
    }
  }
}
