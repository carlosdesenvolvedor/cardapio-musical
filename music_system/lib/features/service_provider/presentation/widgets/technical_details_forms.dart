import 'package:flutter/material.dart';
import '../../domain/entities/service_entity.dart';
import 'file_upload_widget.dart';

abstract class TechnicalFormWidget extends StatelessWidget {
  final Function(TechnicalDetails) onSaved;
  const TechnicalFormWidget({super.key, required this.onSaved});
}

class InfrastructureForm extends StatefulWidget {
  final Function(InfrastructureDetails) onSaved;
  final InfrastructureDetails? initialDetails;
  const InfrastructureForm({
    super.key,
    required this.onSaved,
    this.initialDetails,
  });

  @override
  State<InfrastructureForm> createState() => _InfrastructureFormState();
}

class _InfrastructureFormState extends State<InfrastructureForm> {
  late final TextEditingController _kvaController;
  late final TextEditingController _heightController;
  late final TextEditingController _loadTimeController;
  late final Map<String, bool> _voltages;
  String? _implementationMapUrl;

  @override
  void initState() {
    super.initState();
    _kvaController = TextEditingController(
        text: widget.initialDetails?.kva.toString() ?? '');
    _heightController = TextEditingController(
        text: widget.initialDetails?.vehicleHeight.toString() ?? '');
    _loadTimeController =
        TextEditingController(text: widget.initialDetails?.loadInTime ?? '');
    _voltages = Map<String, bool>.from(
        widget.initialDetails?.powerRequirements ??
            {'110v': false, '220v': true, '380v': false});
    _implementationMapUrl = widget.initialDetails?.implementationMapUrl;
  }

  @override
  void dispose() {
    _kvaController.dispose();
    _heightController.dispose();
    _loadTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title:
              const Text('Requer 110v', style: TextStyle(color: Colors.white)),
          value: _voltages['110v']!,
          activeColor: const Color(0xFFFFC107),
          onChanged: (v) => setState(() => _voltages['110v'] = v),
        ),
        SwitchListTile(
          title:
              const Text('Requer 220v', style: TextStyle(color: Colors.white)),
          value: _voltages['220v']!,
          activeColor: const Color(0xFFFFC107),
          onChanged: (v) => setState(() => _voltages['220v'] = v),
        ),
        SwitchListTile(
          title: const Text('Requer 380v (Trifásico)',
              style: TextStyle(color: Colors.white)),
          value: _voltages['380v']!,
          activeColor: const Color(0xFFFFC107),
          onChanged: (v) => setState(() => _voltages['380v'] = v),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _kvaController,
          decoration: const InputDecoration(
              labelText: 'Potência Total (KVA)',
              filled: true,
              fillColor: Colors.white10),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _heightController,
          decoration: const InputDecoration(
              labelText: 'Altura do Veículo (m)',
              filled: true,
              fillColor: Colors.white10),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _loadTimeController,
          decoration: const InputDecoration(
              labelText: 'Tempo de Montagem (h)',
              filled: true,
              fillColor: Colors.white10),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 24),
        FileUploadWidget(
            label: 'Mapa de Implementação (PDF/CAD)',
            allowedExtensions: const ['pdf', 'dwg', 'png', 'jpg'],
            onFileUploaded: (url) {
              _implementationMapUrl = url;
            }),
        const SizedBox(height: 32),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: () {
              widget.onSaved(InfrastructureDetails(
                  powerRequirements: _voltages,
                  kva: double.tryParse(_kvaController.text) ?? 0,
                  vehicleHeight: double.tryParse(_heightController.text) ?? 0,
                  loadInTime: _loadTimeController.text,
                  implementationMapUrl: _implementationMapUrl));
            },
            child: const Text('CONFIRMAR DETALHES TÉCNICOS',
                style: TextStyle(fontWeight: FontWeight.bold)))
      ],
    );
  }
}

class CateringForm extends StatefulWidget {
  final Function(CateringDetails) onSaved;
  final CateringDetails? initialDetails;
  const CateringForm({
    super.key,
    required this.onSaved,
    this.initialDetails,
  });

  @override
  State<CateringForm> createState() => _CateringFormState();
}

class _CateringFormState extends State<CateringForm> {
  late final List<String> _menuImages;
  late final Map<String, bool> _dietary;
  late bool _kitchen;
  late bool _tasting;

  @override
  void initState() {
    super.initState();
    _menuImages = List<String>.from(widget.initialDetails?.menuImageUrls ?? []);
    _dietary = {
      'Vegano': widget.initialDetails?.dietaryTags.contains('Vegano') ?? false,
      'Sem Glúten':
          widget.initialDetails?.dietaryTags.contains('Sem Glúten') ?? false,
      'Kosher': widget.initialDetails?.dietaryTags.contains('Kosher') ?? false,
    };
    _kitchen = widget.initialDetails?.needsKitchenOnSite ?? false;
    _tasting = widget.initialDetails?.tastingAvailable ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          title: const Text('Cozinha no Local Necessária?',
              style: TextStyle(color: Colors.white)),
          value: _kitchen,
          checkColor: Colors.black,
          activeColor: const Color(0xFFFFC107),
          onChanged: (v) => setState(() => _kitchen = v!),
        ),
        CheckboxListTile(
          title: const Text('Degustação Disponível?',
              style: TextStyle(color: Colors.white)),
          value: _tasting,
          checkColor: Colors.black,
          activeColor: const Color(0xFFFFC107),
          onChanged: (v) => setState(() => _tasting = v!),
        ),
        const SizedBox(height: 16),
        const Text("Opções Dietéticas:",
            style: TextStyle(color: Colors.white70)),
        Wrap(
          spacing: 8,
          children: _dietary.keys.map((key) {
            return FilterChip(
              label: Text(key),
              selected: _dietary[key]!,
              selectedColor: const Color(0xFFFFC107),
              labelStyle: TextStyle(
                  color: _dietary[key]! ? Colors.black : Colors.white),
              onSelected: (v) => setState(() => _dietary[key] = v),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        FileUploadWidget(
            label: 'Adicionar Foto ao Cardápio',
            isImage: true,
            onFileUploaded: (url) {
              setState(() => _menuImages.add(url));
            }),
        if (_menuImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _menuImages.length,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _menuImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                          child:
                              Icon(Icons.broken_image, color: Colors.white24));
                    },
                  ),
                ),
              ),
            ),
          ), // Close SizedBox
        ],
        const SizedBox(height: 32),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: () {
              final selectedDietary = _dietary.entries
                  .where((e) => e.value)
                  .map((e) => e.key)
                  .toList();
              widget.onSaved(CateringDetails(
                  menuImageUrls: _menuImages,
                  dietaryTags: selectedDietary,
                  needsKitchenOnSite: _kitchen,
                  tastingAvailable: _tasting));
            },
            child: const Text('CONFIRMAR BUFFET',
                style: TextStyle(fontWeight: FontWeight.bold)))
      ],
    );
  }
}

class SecurityForm extends StatefulWidget {
  final Function(SecurityDetails) onSaved;
  final SecurityDetails? initialDetails;
  const SecurityForm({
    super.key,
    required this.onSaved,
    this.initialDetails,
  });

  @override
  State<SecurityForm> createState() => _SecurityFormState();
}

class _SecurityFormState extends State<SecurityForm> {
  late final TextEditingController _staffController;
  late bool _hasWeapon;
  String? _certUrl;

  @override
  void initState() {
    super.initState();
    _staffController = TextEditingController(
        text: widget.initialDetails?.staffPerShift.toString() ?? '');
    _hasWeapon = widget.initialDetails?.hasWeapon ?? false;
    _certUrl = widget.initialDetails?.certificationUrls.isNotEmpty == true
        ? widget.initialDetails?.certificationUrls.first
        : null;
  }

  @override
  void dispose() {
    _staffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: const Text('Segurança Armada?',
              style: TextStyle(color: Colors.white)),
          subtitle: const Text('Requer certificação especial',
              style: TextStyle(color: Colors.white38)),
          value: _hasWeapon,
          activeColor: Colors.redAccent,
          onChanged: (v) => setState(() => _hasWeapon = v),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _staffController,
          decoration: const InputDecoration(
              labelText: 'Qtde. Staff por Turno',
              filled: true,
              fillColor: Colors.white10),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        FileUploadWidget(
            label: 'Certificado de Segurança (PDF)',
            allowedExtensions: const ['pdf'],
            onFileUploaded: (url) {
              _certUrl = url;
            }),
        const SizedBox(height: 32),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: () {
              widget.onSaved(SecurityDetails(
                  certificationUrls: _certUrl != null ? [_certUrl!] : [],
                  hasWeapon: _hasWeapon,
                  uniformType: 'tactical', // Could add a selector for this
                  staffPerShift: int.tryParse(_staffController.text) ?? 1));
            },
            child: const Text('CONFIRMAR SEGURANÇA',
                style: TextStyle(fontWeight: FontWeight.bold)))
      ],
    );
  }
}

class MediaForm extends StatefulWidget {
  final Function(MediaDetails) onSaved;
  final MediaDetails? initialDetails;
  const MediaForm({
    super.key,
    required this.onSaved,
    this.initialDetails,
  });

  @override
  State<MediaForm> createState() => _MediaFormState();
}

class _MediaFormState extends State<MediaForm> {
  late final List<String> _portfolio;
  late final TextEditingController _equipController;

  @override
  void initState() {
    super.initState();
    _portfolio = List<String>.from(widget.initialDetails?.portfolioUrls ?? []);
    _equipController = TextEditingController(
        text: widget.initialDetails?.equipmentList.join(', ') ?? '');
  }

  @override
  void dispose() {
    _equipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _equipController,
          decoration: const InputDecoration(
              labelText: 'Lista de Equipamentos (ex: Sony A7S, Drone)',
              helperText: 'Separe por vírgula',
              helperStyle: TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white10),
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        FileUploadWidget(
            label: 'Adicionar ao Portfólio (Fotos/PDF)',
            onFileUploaded: (url) {
              setState(() => _portfolio.add(url));
            }),
        if (_portfolio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text('${_portfolio.length} itens adicionados',
                style: const TextStyle(color: Colors.green)),
          ),
        const SizedBox(height: 32),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: () {
              final equipment = _equipController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              widget.onSaved(MediaDetails(
                  portfolioUrls: _portfolio,
                  equipmentList: equipment,
                  deliveryTimeDays: 7 // Default or add input
                  ));
            },
            child: const Text('CONFIRMAR MÍDIA',
                style: TextStyle(fontWeight: FontWeight.bold)))
      ],
    );
  }
}

class ArtistForm extends StatefulWidget {
  final Function(ArtistDetails) onSaved;
  final ArtistDetails? initialDetails;
  const ArtistForm({
    super.key,
    required this.onSaved,
    this.initialDetails,
  });

  @override
  State<ArtistForm> createState() => _ArtistFormState();
}

class _ArtistFormState extends State<ArtistForm> {
  late final TextEditingController _genreController;
  String? _stageMap;
  String? _repertoire;

  @override
  void initState() {
    super.initState();
    _genreController =
        TextEditingController(text: widget.initialDetails?.genre ?? '');
    _stageMap = widget.initialDetails?.stageMapUrl;
    _repertoire = widget.initialDetails?.repertoireUrl;
  }

  @override
  void dispose() {
    _genreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _genreController,
          decoration: const InputDecoration(
              labelText: 'Gênero Principal',
              filled: true,
              fillColor: Colors.white10),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 24),
        FileUploadWidget(
            label: 'Mapa de Palco (Rider Técnico)',
            allowedExtensions: const ['pdf', 'png', 'jpg'],
            onFileUploaded: (url) => _stageMap = url),
        const SizedBox(height: 16),
        FileUploadWidget(
            label: 'Repertório (PDF)',
            allowedExtensions: const ['pdf'],
            onFileUploaded: (url) => _repertoire = url),
        const SizedBox(height: 32),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: () {
              widget.onSaved(ArtistDetails(
                  genre: _genreController.text,
                  repertoireUrl: _repertoire,
                  stageMapUrl: _stageMap));
            },
            child: const Text('CONFIRMAR ARTISTA',
                style: TextStyle(fontWeight: FontWeight.bold)))
      ],
    );
  }
}
