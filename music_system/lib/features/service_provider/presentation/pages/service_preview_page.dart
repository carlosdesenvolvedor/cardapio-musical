import 'package:flutter/material.dart';
import '../../domain/entities/service_entity.dart';
import 'package:intl/intl.dart';

class ServicePreviewPage extends StatelessWidget {
  final ServiceEntity service;

  const ServicePreviewPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(currencyFormatter),
                  const SizedBox(height: 32),
                  _buildSectionTitle('DESCRIÇÃO'),
                  const SizedBox(height: 12),
                  Text(
                    service.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('DETALHES TÉCNICOS'),
                  const SizedBox(height: 16),
                  _buildTechnicalDetails(context),
                  const SizedBox(height: 48),
                  _buildActionButtons(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF101010),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFC107).withOpacity(0.2),
                    const Color(0xFF101010),
                  ],
                ),
              ),
            ),
            Center(
              child: Hero(
                tag: 'service_icon_${service.id}',
                child: Icon(
                  _getIconForCategory(service.category),
                  size: 80,
                  color: const Color(0xFFFFC107).withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'MODO PRÉVIA',
                style: TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(NumberFormat f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getCategoryName(service.category),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          service.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              f.format(service.basePrice),
              style: const TextStyle(
                color: Color(0xFFFFC107),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              service.priceDescription,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildTechnicalDetails(BuildContext context) {
    final details = service.technicalDetails;

    if (details is ArtistDetails) {
      return _buildDetailGrid([
        _buildDetailItem(Icons.music_note, 'Gênero', details.genre),
        if (details.repertoireUrl != null)
          _buildDetailItem(Icons.list_alt, 'Repertório', 'Disponível'),
        if (details.stageMapUrl != null)
          _buildDetailItem(Icons.map, 'Mapa de Palco', 'Anexado'),
      ]);
    } else if (details is InfrastructureDetails) {
      return _buildDetailGrid([
        _buildDetailItem(Icons.flash_on, 'Potência', '${details.kva} KVA'),
        _buildDetailItem(Icons.access_time, 'Montagem', details.loadInTime),
        _buildDetailItem(
            Icons.height, 'Altura Veíc.', '${details.vehicleHeight}m'),
        _buildDetailItem(
            Icons.settings,
            'Energia',
            details.powerRequirements.entries
                .where((e) => e.value)
                .map((e) => e.key)
                .join(', ')),
      ]);
    } else if (details is CateringDetails) {
      return _buildDetailGrid([
        _buildDetailItem(Icons.restaurant_menu, 'Menu',
            '${details.menuImageUrls.length} itens'),
        _buildDetailItem(Icons.kitchen, 'Cozinha',
            details.needsKitchenOnSite ? 'No Local' : 'Pronto'),
        _buildDetailItem(Icons.star, 'Degustação',
            details.tastingAvailable ? 'Disponível' : 'N/A'),
        _buildDetailItem(Icons.label, 'Dietas', details.dietaryTags.join(', ')),
      ]);
    } else if (details is SecurityDetails) {
      return _buildDetailGrid([
        _buildDetailItem(
            Icons.groups, 'Equipe', '${details.staffPerShift} pessoas'),
        _buildDetailItem(
            Icons.check_circle, 'Armado', details.hasWeapon ? 'Sim' : 'Não'),
        _buildDetailItem(
            Icons.style, 'Uniforme', details.uniformType.toUpperCase()),
        _buildDetailItem(Icons.description, 'Certificados',
            '${details.certificationUrls.length} docs'),
      ]);
    } else if (details is MediaDetails) {
      return _buildDetailGrid([
        _buildDetailItem(Icons.photo_library, 'Portfólio',
            '${details.portfolioUrls.length} itens'),
        _buildDetailItem(Icons.construction, 'Equip.',
            '${details.equipmentList.length} itens'),
        _buildDetailItem(
            Icons.timer, 'Entrega', '${details.deliveryTimeDays} dias'),
      ]);
    }

    return const SizedBox.shrink();
  }

  Widget _buildDetailGrid(List<Widget> children) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children:
          children.map((item) => SizedBox(width: 160, child: item)).toList(),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFC107), size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFC107).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Este é apenas um modo de prévia.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'SOLICITAR ORÇAMENTO',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Ver Perfil do Prestador',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  String _getCategoryName(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.artist:
        return 'ARTÍSTICO';
      case ServiceCategory.infrastructure:
        return 'TÉCNICA & ESTRUTURA';
      case ServiceCategory.catering:
        return 'ALIMENTAÇÃO';
      case ServiceCategory.security:
        return 'SEGURANÇA';
      case ServiceCategory.media:
        return 'MÍDIA';
    }
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
