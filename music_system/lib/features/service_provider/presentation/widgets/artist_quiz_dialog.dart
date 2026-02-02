import 'package:flutter/material.dart';

class ArtistQuizDialog extends StatefulWidget {
  final Function(
          int score, String level, double suggestedMin, double suggestedMax)
      onApply;

  const ArtistQuizDialog({super.key, required this.onApply});

  @override
  State<ArtistQuizDialog> createState() => _ArtistQuizDialogState();
}

class _ArtistQuizDialogState extends State<ArtistQuizDialog> {
  // 1. Performance (Max 60)
  int _repertoire = 2; // <20, 50, 100, 200+
  int _tuning = 2; // Iniciante, Intermediário, Profissional
  bool _backingVocal = false;
  bool _instrumentIndependence = false;
  bool _varietyStyles = false;
  bool _technologyUsage = false;
  bool _stagePerformance = false;
  bool _freshHits = false;

  // 2. Equipamento (Max 60)
  int _microphone = 3; // Dinâmico, Condensador
  bool _backupInstrument = false;
  bool _monitoringSystem = false;
  bool _soundBoard = false;
  int _paSystem = 5; // 50, 150, 300+
  bool _lighting = false;
  bool _scenery = false;
  bool _cablesEnergy = false;

  // 3. Marketing (Max 40)
  bool _proPhotos = false;
  bool _proVideo = false;
  bool _organizedInstagram = false;
  bool _streamingPresence = false;
  bool _brandingLogo = false;
  bool _marketingMaterial = false;
  bool _pressKit = false;

  // 4. Logística (Max 40)
  bool _ownTransport = false;
  bool _formalContract = false;
  bool _invoiceAbility = false;
  bool _punctualityAtSoundcheck = false;
  bool _hasRoadie = false;
  bool _weekdayAvailability = false;
  bool _academicTraining = false;

  int get _totalScore {
    int score = 0;
    // Performance
    score += _repertoire;
    score += _tuning;
    if (_backingVocal) score += 5;
    if (_instrumentIndependence) score += 10;
    if (_varietyStyles) score += 5;
    if (_technologyUsage) score += 5;
    if (_stagePerformance) score += 5;
    if (_freshHits) score += 5;

    // Equipamento
    score += _microphone;
    if (_backupInstrument) score += 5;
    if (_monitoringSystem) score += 5;
    if (_soundBoard) score += 10;
    score += _paSystem;
    if (_lighting) score += 5;
    if (_scenery) score += 5;
    if (_cablesEnergy) score += 5;

    // Marketing
    if (_proPhotos) score += 6;
    if (_proVideo) score += 6;
    if (_organizedInstagram) score += 6;
    if (_streamingPresence) score += 6;
    if (_brandingLogo) score += 5;
    if (_marketingMaterial) score += 5;
    if (_pressKit) score += 6;

    // Logística
    if (_ownTransport) score += 8;
    if (_formalContract) score += 6;
    if (_invoiceAbility) score += 6;
    if (_punctualityAtSoundcheck) score += 5;
    if (_hasRoadie) score += 5;
    if (_weekdayAvailability) score += 5;
    if (_academicTraining) score += 5;

    return score;
  }

  String get _professionalLevel {
    final s = _totalScore;
    if (s <= 50) return 'Bronze';
    if (s <= 100) return 'Prata';
    if (s <= 150) return 'Ouro';
    return 'Diamante';
  }

  Map<String, double> get _suggestion {
    final s = _totalScore;
    if (s <= 50) return {'min': 200, 'max': 350};
    if (s <= 100) return {'min': 350, 'max': 600};
    if (s <= 150) return {'min': 600, 'max': 1200};
    return {'min': 1200, 'max': 2500};
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAppBar(),
              const TabBar(
                isScrollable: true,
                indicatorColor: Color(0xFFFFC107),
                labelColor: Color(0xFFFFC107),
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: 'Performance'),
                  Tab(text: 'Equipamento'),
                  Tab(text: 'Marketing'),
                  Tab(text: 'Logística'),
                ],
              ),
              Flexible(
                child: TabBarView(
                  children: [
                    _buildPerformanceTab(),
                    _buildEquipmentTab(),
                    _buildMarketingTab(),
                    _buildLogisticsTab(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          const Icon(Icons.calculate, color: Color(0xFFFFC107), size: 28),
          const SizedBox(width: 12),
          const Text(
            'Checklist Profissional',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white54),
          )
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildDropdownSection(
          title: 'Qtd de Músicas no Repertório',
          value: _repertoire,
          options: {'< 20': 2, '50+': 5, '100+': 10, '200+': 15},
          onChanged: (v) => setState(() => _repertoire = v!),
        ),
        _buildDropdownSection(
          title: 'Nível de Afinação',
          value: _tuning,
          options: {'Iniciante': 2, 'Intermediário': 5, 'Profissional': 10},
          onChanged: (v) => setState(() => _tuning = v!),
        ),
        _buildSwitchTile('Faz Backing Vocal / Segunda Voz?', _backingVocal,
            (v) => setState(() => _backingVocal = v)),
        _buildSwitchTile(
            'Canta e Toca Simultaneamente?',
            _instrumentIndependence,
            (v) => setState(() => _instrumentIndependence = v)),
        _buildSwitchTile('Toca +3 estilos diferentes?', _varietyStyles,
            (v) => setState(() => _varietyStyles = v)),
        _buildSwitchTile('Usa VS / Playback / Loop Station?', _technologyUsage,
            (v) => setState(() => _technologyUsage = v)),
        _buildSwitchTile('Faz dinâmicas e interage com o público?',
            _stagePerformance, (v) => setState(() => _stagePerformance = v)),
        _buildSwitchTile('Mantém Hits do Mês atualizados?', _freshHits,
            (v) => setState(() => _freshHits = v)),
      ],
    );
  }

  Widget _buildEquipmentTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildDropdownSection(
          title: 'Microfone Próprio',
          value: _microphone,
          options: {'Dinâmico Simples': 3, 'Condensador / Profissional': 10},
          onChanged: (v) => setState(() => _microphone = v!),
        ),
        _buildDropdownSection(
          title: 'Sistema de PA (Som)',
          value: _paSystem,
          options: {
            'Até 50 pessoas': 5,
            'Até 150 pessoas': 10,
            '300+ pessoas': 15
          },
          onChanged: (v) => setState(() => _paSystem = v!),
        ),
        _buildSwitchTile('Instrumento de Reserva / Backup?', _backupInstrument,
            (v) => setState(() => _backupInstrument = v)),
        _buildSwitchTile('Usa Fone (In-ear) ou Monitor de Chão?',
            _monitoringSystem, (v) => setState(() => _monitoringSystem = v)),
        _buildSwitchTile('Mesa de Som com Efeitos Própria?', _soundBoard,
            (v) => setState(() => _soundBoard = v)),
        _buildSwitchTile('Possui Iluminação (LED/Moving)?', _lighting,
            (v) => setState(() => _lighting = v)),
        _buildSwitchTile('Possui Cenário / Banner / Tapete?', _scenery,
            (v) => setState(() => _scenery = v)),
        _buildSwitchTile('Possui Cabos e Réguas Profissionais?', _cablesEnergy,
            (v) => setState(() => _cablesEnergy = v)),
      ],
    );
  }

  Widget _buildMarketingTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSwitchTile('Fotos Profissionais de Alta Qualidade?', _proPhotos,
            (v) => setState(() => _proPhotos = v)),
        _buildSwitchTile('Vídeo de Demonstração (Showreel)?', _proVideo,
            (v) => setState(() => _proVideo = v)),
        _buildSwitchTile(
            'Instagram Organizado (Bio/Feed)?',
            _organizedInstagram,
            (v) => setState(() => _organizedInstagram = v)),
        _buildSwitchTile('Presença no Spotify / YouTube?', _streamingPresence,
            (v) => setState(() => _streamingPresence = v)),
        _buildSwitchTile('Logotipo e Identidade Visual?', _brandingLogo,
            (v) => setState(() => _brandingLogo = v)),
        _buildSwitchTile('QR Code para Contato e Pix?', _marketingMaterial,
            (v) => setState(() => _marketingMaterial = v)),
        _buildSwitchTile('Press Kit Profissional (PDF)?', _pressKit,
            (v) => setState(() => _pressKit = v)),
      ],
    );
  }

  Widget _buildLogisticsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSwitchTile('Transporte de Carga Próprio (Carro/Van)?',
            _ownTransport, (v) => setState(() => _ownTransport = v)),
        _buildSwitchTile('Utiliza Contrato de Prestação de Serviço?',
            _formalContract, (v) => setState(() => _formalContract = v)),
        _buildSwitchTile('Emite Nota Fiscal (MEI / Empresa)?', _invoiceAbility,
            (v) => setState(() => _invoiceAbility = v)),
        _buildSwitchTile(
            'Pontualidade Rigorosa (Sempre Cedo)?',
            _punctualityAtSoundcheck,
            (v) => setState(() => _punctualityAtSoundcheck = v)),
        _buildSwitchTile('Tem Roadie / Ajudante de Equipe?', _hasRoadie,
            (v) => setState(() => _hasRoadie = v)),
        _buildSwitchTile(
            'Disponibilidade para Dias de Semana?',
            _weekdayAvailability,
            (v) => setState(() => _weekdayAvailability = v)),
        _buildSwitchTile('Formação Acadêmica ou Técnica?', _academicTraining,
            (v) => setState(() => _academicTraining = v)),
      ],
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFFFC107),
        dense: true,
      ),
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required int value,
    required Map<String, int> options,
    required Function(int?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          DropdownButton<int>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF2C2C2C),
            items: options.entries
                .map((e) => DropdownMenuItem(
                    value: e.value,
                    child: Text(e.key,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14))))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOTA: $_totalScore pontos',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Nível: $_professionalLevel',
                      style: const TextStyle(
                          color: Color(0xFFFFC107),
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Sugestão Base:',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(
                      'R\$ ${_suggestion['min']?.toInt()} - ${_suggestion['max']?.toInt()}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              widget.onApply(_totalScore, _professionalLevel,
                  _suggestion['min']!, _suggestion['max']!);
              Navigator.pop(context);
            },
            child: const Text('SALVAR E APLICAR RESULTADOS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
