import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:music_system/config/theme/app_theme.dart';

class ArtistInsightsPage extends StatelessWidget {
  const ArtistInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'INSIGHTS DO ARTISTA',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Resumo de Performance',
              Icons.analytics_outlined,
            ),
            const SizedBox(height: 20),
            _buildMetricsGrid(isDesktop),
            const SizedBox(height: 40),
            _buildSectionHeader(
              'Músicas mais Pedidas',
              Icons.leaderboard_outlined,
            ),
            const SizedBox(height: 20),
            _buildMusicCharts(isDesktop),
            const SizedBox(height: 40),
            _buildSectionHeader(
              'IA - Feedback & Estratégia',
              Icons.auto_awesome_outlined,
            ),
            const SizedBox(height: 20),
            _buildAISuggestions(isDesktop),
            const SizedBox(height: 40),
            _buildAITerrainReady(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1);
  }

  Widget _buildMetricsGrid(bool isDesktop) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total Gorjetas',
          'R\$ 1.250,00',
          '+12%',
          Colors.greenAccent,
        ),
        _buildStatCard('Pedidos Mes', '48', '+5', Colors.blueAccent),
        _buildStatCard('Taxa Aceite', '92%', '+2%', Colors.orangeAccent),
        _buildStatCard('Sujestões IA', '15', 'Nível: 5', Colors.purpleAccent),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String trend, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trend,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(
      delay: 100.ms,
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildMusicCharts(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _buildMusicRankItem('Bohemian Rhapsody', 25, 0.9),
              _buildMusicRankItem('Evidências', 22, 0.8),
              _buildMusicRankItem('Sweet Child O Mine', 18, 0.6),
              _buildMusicRankItem('Wonderwall', 15, 0.5),
              _buildMusicRankItem('Hotel California', 12, 0.4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMusicRankItem(String name, int requests, double percent) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Text(
              '$requests pedidos',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildAISuggestions(bool isDesktop) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildSuggestionCard(
          'Tática de Engajamento',
          'Tente interagir mais com os donos de mesas que pedem sertanejo, eles tendem a dar mais gorjetas após o 3º pedido.',
          Icons.tips_and_updates,
          Colors.orangeAccent,
        ),
        _buildSuggestionCard(
          'Melhoria de Repertório',
          'O público dessa região está pedindo muito "Pisadinha". Adicione 3 músicas do Barões da Pisadinha para aumentar as chances de gorjetas.',
          Icons.library_add,
          Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildAITerrainReady() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFE5B80B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5B80B).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hub_outlined,
            color: AppTheme.primaryColor,
            size: 40,
          ),
          const SizedBox(height: 20),
          Text(
            'IA ENGINE READY',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Este painel está pronto para receber telemetria em tempo real do seu backend de IA. As táticas e sugestões serão sincronizadas dinamicamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Conectar Agente de IA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().shimmer(delay: 1.seconds, duration: 1500.ms);
  }
}
