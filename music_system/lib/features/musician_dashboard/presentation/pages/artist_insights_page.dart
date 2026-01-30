import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_system/config/theme/app_theme.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:music_system/features/auth/domain/entities/user_profile.dart';

class ArtistInsightsPage extends StatelessWidget {
  const ArtistInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        UserProfile? profile;
        if (state is ProfileLoaded) {
          profile = state.profile;
        }

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
                _buildMetricsGrid(isDesktop, profile),
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
      },
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

  Widget _buildMetricsGrid(bool isDesktop, UserProfile? profile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Seguidores',
          profile?.followersCount.toString() ?? '0',
          'Tempo Real',
          profile != null && profile.followersCount > 0
              ? Colors.greenAccent
              : Colors.white24,
        ),
        _buildStatCard(
          'Visualizações',
          profile?.profileViewsCount.toString() ?? '0',
          'Total Histórico',
          profile != null && profile.profileViewsCount > 0
              ? Colors.blueAccent
              : Colors.white24,
        ),
        _buildStatCard(
          'Taxa Aceite',
          'N/D',
          'Próxima Live',
          Colors.orangeAccent,
        ),
        _buildStatCard(
          'Nível IA',
          'Beta',
          'MixArt Engine',
          Colors.purpleAccent,
        ),
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
              _buildMusicRankItem('Dados Sugeridos pelo App', 0, 0.1),
              _buildMusicRankItem('Interaja mais para gerar métricas', 0, 0.05),
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
            if (requests > 0)
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
          'Sua Rede de Artistas está ativa! Continue postando stories para aumentar as visualizações e o nível de engajamento da IA.',
          Icons.tips_and_updates,
          Colors.orangeAccent,
        ),
        _buildSuggestionCard(
          'Melhoria de Repertório',
          'Em breve, a IA analisará os pedidos realizados no seu Painel de Músico para sugerir novas faixas que bombam na sua região.',
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
            'Este painel agora está conectado ao seu perfil dinâmico. As métricas de Seguidores e Visualizações são reais e sincronizadas automaticamente.',
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
              'Agente de IA Ativo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().shimmer(delay: 1.seconds, duration: 1500.ms);
  }
}
