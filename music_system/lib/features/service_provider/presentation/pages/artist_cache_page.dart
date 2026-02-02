import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import '../widgets/artist_quiz_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ArtistCachePage extends StatefulWidget {
  const ArtistCachePage({super.key});

  @override
  State<ArtistCachePage> createState() => _ArtistCachePageState();
}

class _ArtistCachePageState extends State<ArtistCachePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text('MEU CACHÊ',
            style:
                TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          int? currentScore;
          String? currentLevel;
          double? minCache;
          double? maxCache;
          if (state is ProfileLoaded) {
            currentScore = state.profile.artistScore;
            currentLevel = state.profile.professionalLevel;
            minCache = state.profile.minSuggestedCache;
            maxCache = state.profile.maxSuggestedCache;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(currentScore, currentLevel,
                    minCache: minCache, maxCache: maxCache),
                const SizedBox(height: 32),
                _buildInfoCard(),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ArtistQuizDialog(
                        onApply: (score, level, min, max) {
                          if (state is ProfileLoaded) {
                            final updatedProfile = state.profile.copyWith(
                              artistScore: score,
                              professionalLevel: level,
                              minSuggestedCache: min,
                              maxSuggestedCache: max,
                            );
                            context
                                .read<AuthBloc>()
                                .add(ProfileUpdateRequested(updatedProfile));
                          }
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.calculate, size: 24),
                  label: const Text('CALCULAR / ATUALIZAR NOTA',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _exportToPdf(
                    state is ProfileLoaded
                        ? state.profile.artisticName
                        : 'Artista',
                    currentScore ?? 0,
                    currentLevel ?? 'N/A',
                    minCache ?? 0,
                  ),
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white70),
                  label: const Text('EXPORTAR RESULTADO (PDF)',
                      style: TextStyle(color: Colors.white70)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportToPdf(
      String artistName, int score, String level, double minCache) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Relatório de Valor de Mercado',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text('Artista: $artistName',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Pontuação Total:',
                            style: pw.TextStyle(color: PdfColors.grey700)),
                        pw.Text('$score pontos',
                            style: pw.TextStyle(
                                fontSize: 32, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Nível Profissional:',
                            style: pw.TextStyle(color: PdfColors.grey700)),
                        pw.Text(level.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Sugestão de Cachê Base:',
                          style: pw.TextStyle(
                              fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      pw.Text('R\$ ${minCache.toInt().toString()},00+',
                          style: pw.TextStyle(
                              fontSize: 40,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.amber900)),
                      pw.SizedBox(height: 5),
                      pw.Text('* Valor sugerido por hora de performance.',
                          style: pw.TextStyle(
                              fontSize: 10, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text('Critérios Analisados:',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Bullet(text: 'Repertório e Experiência de Palco'),
                pw.Bullet(text: 'Qualidade Técnica e Equipamentos'),
                pw.Bullet(text: 'Presença Digital e Marketing'),
                pw.Bullet(text: 'Nível de Profissionalismo e Logística'),
                pw.Spacer(),
                pw.Center(
                  child: pw.Text('Gerado por MixArt System Intelligence',
                      style:
                          pw.TextStyle(fontSize: 10, color: PdfColors.grey400)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Widget _buildHeader(int? score, String? level,
      {double? minCache, double? maxCache}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5B80B), Color(0xFFB8860B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC107).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (level != null)
            Positioned(
              right: 0,
              top: 0,
              child: _buildSeal(level, minCache, maxCache),
            ),
          Column(
            children: [
              const Text(
                'SUA PONTUAÇÃO ATUAL',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                score?.toString() ?? '--',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'PONTOS',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (level != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    level.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeal(String level, double? min, double? max) {
    Color color;
    IconData icon = Icons.stars;
    List<Color> gradientColors;

    switch (level) {
      case 'Bronze':
        color = const Color(0xFFCD7F32);
        gradientColors = [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
        break;
      case 'Prata':
        color = const Color(0xFFC0C0C0);
        gradientColors = [const Color(0xFFC0C0C0), const Color(0xFF808080)];
        break;
      case 'Ouro':
        color = const Color(0xFFFFD700);
        gradientColors = [const Color(0xFFFFD700), const Color(0xFFDAA520)];
        break;
      case 'Diamante':
        color = const Color(0xFFB9F2FF);
        icon = Icons.diamond;
        gradientColors = [const Color(0xFFB9F2FF), const Color(0xFF00BFFF)];
        break;
      default:
        color = Colors.grey;
        gradientColors = [Colors.grey, Colors.black45];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 40),
        ),
        if (min != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'R\$ ${min.toInt()}+',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como funciona?',
            style: TextStyle(
              color: Color(0xFFFFC107),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Nossa inteligência analisa seu material, logística e performance para sugerir um valor de cachê que seja justo e competitivo no mercado.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          SizedBox(height: 16),
          _BulletItem(text: 'Repertório e Experiência'),
          _BulletItem(text: 'Equipamento Próprio'),
          _BulletItem(text: 'Marketing Profissional'),
          _BulletItem(text: 'Logística de Transporte'),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFFFFC107), size: 16),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}
