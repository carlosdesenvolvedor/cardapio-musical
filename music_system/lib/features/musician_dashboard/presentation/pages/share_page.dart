import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class SharePage extends StatefulWidget {
  final String userId;

  const SharePage({super.key, required this.userId});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final GlobalKey _qrKey = GlobalKey();

  Future<Uint8List?> _capturePng() async {
    try {
      // Small delay to ensure the framework has finished painting the widget
      await Future.delayed(const Duration(milliseconds: 100));

      RenderRepaintBoundary? boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('Boundary is null');
        return null;
      }

      ui.Image image = await boundary.toImage(
        pixelRatio: 2.0,
      ); // Reduced ratio for mobile stability
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing QR Code: $e');
      return null;
    }
  }

  Future<void> _shareQrCode() async {
    try {
      final Uint8List? imageBytes = await _capturePng();
      if (imageBytes != null) {
        if (kIsWeb) {
          // Web implementation: uses XFile.fromData to avoid dart:io
          await Share.shareXFiles([
            XFile.fromData(
              imageBytes,
              name: 'qr_code_${widget.userId}.png',
              mimeType: 'image/png',
            ),
          ], text: 'Confira meu cardápio musical!');
        } else {
          // Mobile/Desktop implementation
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/qr_code_${widget.userId}.png');
          await file.writeAsBytes(imageBytes);

          await Share.shareXFiles([
            XFile(file.path),
          ], text: 'Confira meu cardápio musical!');
        }
      }
    } catch (e) {
      debugPrint('Error sharing QR Code: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao compartilhar: $e')));
      }
    }
  }

  Future<void> _printQrCode() async {
    final Uint8List? imageBytes = await _capturePng();
    if (imageBytes != null) {
      final doc = pw.Document();
      final image = pw.MemoryImage(imageBytes);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'MusicRequest - Cardápio Musical',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Container(width: 400, height: 500, child: pw.Image(image)),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Peça sua música e contribua com o artista!',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the current origin if on web to allow local testing
    final String baseUrl =
        kIsWeb ? Uri.base.origin : 'https://music-system-421ee.web.app';
    final String url = '$baseUrl/menu/${widget.userId}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartilhar Cardápio'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1DB954), // Spotify Green
              Color(0xFF191414), // Spotify Black
            ],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              debugPrint('Generating QR for URL: $url');
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Icon(Icons.qr_code_2, size: 64, color: Colors.white)
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 16),
                    const Text(
                      'Seu QR Code Personalizado',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 12),
                    const Text(
                      'Mostre para seus clientes para que eles possam pedir músicas direto do celular.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 48),

                    // QR Code Card Wrap with RepaintBoundary
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QrImageView(
                              data: url,
                              version: QrVersions.auto,
                              size: 240,
                              gapless: false,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF191414),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF191414),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Escaneie para ver o Menu',
                              style: TextStyle(
                                color: Color(0xFF191414),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                decoration: TextDecoration
                                    .none, // Ensure no underline in capture
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().scale(
                          delay: 600.ms,
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        ),

                    const SizedBox(height: 48),

                    // Link Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Link Direto',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  url,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  color: Color(0xFF1DB954),
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: url));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Link copiado!'),
                                      backgroundColor: Color(0xFF1DB954),
                                    ),
                                  );
                                },
                                tooltip: 'Copiar Link',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: 0.2, delay: 800.ms).fadeIn(),

                    const SizedBox(height: 32),

                    // Interactive Action Rows
                    _buildActionRow(
                      Icons.print,
                      'Imprima e coloque nas mesas do estabelecimento.',
                      onTap: _printQrCode,
                    ).animate().fadeIn(delay: 1000.ms),
                    const SizedBox(height: 16),
                    _buildActionRow(
                      Icons.share,
                      'Compartilhe nos seus stories ou bio do Instagram.',
                      onTap: _shareQrCode,
                    ).animate().fadeIn(delay: 1200.ms),

                    const SizedBox(height: 40),

                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Tudo pronto!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF191414),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1400.ms),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(
    IconData icon,
    String text, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
