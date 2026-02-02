import 'package:flutter/material.dart';

import '../../domain/entities/service_entity.dart';
import 'service_registration_form_page.dart';

class ServiceCategorySelectionPage extends StatefulWidget {
  final String providerId;
  const ServiceCategorySelectionPage({super.key, required this.providerId});

  @override
  State<ServiceCategorySelectionPage> createState() =>
      _ServiceCategorySelectionPageState();
}

class _ServiceCategorySelectionPageState
    extends State<ServiceCategorySelectionPage> {
  ServiceCategory? _hoveredCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text(
          'NOVO SERVIÇO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontFamily: 'Outfit',
            fontSize: 14,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Qual tipo de serviço você oferece?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildCategoryCard(
                    context,
                    category: ServiceCategory.artist,
                    label: 'Artístico & Talento',
                    icon: Icons.mic_external_on,
                    description: 'Bandas, DJs, Músicos Solo',
                  ),
                  _buildCategoryCard(
                    context,
                    category: ServiceCategory.infrastructure,
                    label: 'Técnica & Estrutura',
                    icon: Icons.speaker_group,
                    description: 'Som, Palco, Luz, Gerador',
                  ),
                  _buildCategoryCard(
                    context,
                    category: ServiceCategory.catering,
                    label: 'Alimentação & Bebidas',
                    icon: Icons.restaurant,
                    description: 'Buffet, Bar, Catering',
                  ),
                  _buildCategoryCard(
                    context,
                    category: ServiceCategory.security,
                    label: 'Segurança & Logística',
                    icon: Icons.local_police,
                    description: 'Staff, Segurança, Valet',
                  ),
                  _buildCategoryCard(
                    context,
                    category: ServiceCategory.media,
                    label: 'Mídia & Registro',
                    icon: Icons.camera_alt,
                    description: 'Foto, Vídeo, Drone',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required ServiceCategory category,
    required String label,
    required IconData icon,
    required String description,
  }) {
    final isHovered = _hoveredCategory == category;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCategory = category),
      onExit: (_) => setState(() => _hoveredCategory = null),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceRegistrationFormPage(
                category: category,
                providerId: widget.providerId,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 280,
          height: 200,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? const Color(0xFFFFC107) : Colors.white10,
              width: isHovered ? 2 : 1,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: isHovered ? const Color(0xFFFFC107) : Colors.white70,
              ),
              const SizedBox(height: 24),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
