import 'package:dio/dio.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/lyrics_model.dart';

abstract class LyricsRemoteDataSource {
  Future<LyricsModel> fetchLyrics(String songName, String artist);
  Future<List<CifraClubSuggestion>> searchSuggestions(String query);
}

class LyricsRemoteDataSourceImpl implements LyricsRemoteDataSource {
  final Dio dio;

  LyricsRemoteDataSourceImpl({required this.dio});

  @override
  Future<LyricsModel> fetchLyrics(String songName, String artist) async {
    try {
      // 1. Construct Cifra Club URL
      // Format: cifraclub.com.br/artista/musica
      final formattedArtist = _formatForUrl(artist);
      final formattedSong = _formatForUrl(songName);
      final targetUrl =
          'https://www.cifraclub.com.br/$formattedArtist/$formattedSong/';

      // 2. Use CORS Proxy (Necessary for Flutter Web Client-Side Scraping)
      // Note: In a production app, this should be done via a Cloud Function to avoid reliance on public proxies.
      final proxyUrl =
          'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';

      final response = await dio.get(
        proxyUrl,
        options: Options(
          headers: {
            // Emulate a browser to avoid some basic blocking
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          },
        ),
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.data);

        // Cifra Club usually puts the cipher in a container with class 'cifra_content' or similar pre tags
        // Trying to find the main container. Structure often changes, but usually inside <pre>
        // Try multiple selectors as Cifra Club structure might vary (desktop vs mobile, new vs old layout)
        final potentialSelectors = [
          '.cifra_cnt pre', // Classic Desktop
          '.cifra-column pre', // Two column layout
          '.cifra-column--left pre',
          'div.cifra pre', // Alternative container
          '.cifra_content pre',
          'div[id*="cifra"] pre',
        ];

        Element? cipherContainer;

        // 1. Try specific selectors
        for (final selector in potentialSelectors) {
          cipherContainer = document.querySelector(selector);
          if (cipherContainer != null &&
              cipherContainer.text.trim().length > 50) {
            break;
          }
        }

        // 2. Fallback: Search ALL <pre> tags for meaningful content
        if (cipherContainer == null) {
          final allPres = document.querySelectorAll('pre');
          for (final pre in allPres) {
            if (pre.text.trim().length > 100) {
              // Higher threshold for generic pre
              cipherContainer = pre;
              break;
            }
          }
        }

        if (cipherContainer != null) {
          // Clean up the text
          // Cifra Club puts chords inside <b> tags. The .text property extracts them but we might want to ensure spacing.
          // For now, raw text is often readable enough, but let's trim excessive empty lines.
          String content = cipherContainer.text;

          return LyricsModel(
            songName: songName,
            artist: artist,
            content: content,
            isVip: false,
          );
        } else {
          // Debug info
          print('Scraping Failed for URL: $targetUrl');
          print('HTML Body Length: ${response.data.toString().length}');
          throw Exception(
            'Cifra structure not found (Selectors tested: $potentialSelectors)',
          );
        }
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock/error for MVP if scraping fails
      print('Scraping failed: $e');
      return LyricsModel(
        songName: songName,
        artist: artist,
        content:
            "Não conseguimos encontrar a cifra automaticamente para '$songName' de '$artist'.\n\nErro: $e",
        isVip: false,
      );
    }
  }

  Future<List<CifraClubSuggestion>> searchSuggestions(String query) async {
    try {
      if (query.length < 3) return [];

      // Use DuckDuckGo HTML version to search specifically in Cifra Club
      final searchUrl =
          'https://html.duckduckgo.com/html/?q=site:cifraclub.com.br ${Uri.encodeComponent(query)}';

      // Use CORS Proxy
      final proxyUrl =
          'https://corsproxy.io/?${Uri.encodeComponent(searchUrl)}';

      final response = await dio.get(
        proxyUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          },
        ),
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.data);
        final results = <CifraClubSuggestion>[];

        // DuckDuckGo HTML results are usually in .result__a (links)
        final links = document.querySelectorAll('.result__a');

        for (var link in links) {
          final titleText = link.text.trim();
          final url = link.attributes['href'] ?? '';

          // Filter only Cifra Club song URLs (usually cifraclub.com.br/artist/song/)
          // Exclude tabs with 'letra', 'traducao', or generic pages
          if (url.contains('cifraclub.com.br') &&
              !url.contains('/letra') &&
              !url.contains('/traducao')) {
            // Title usually comes as "Song - Artist - Cifra Club" or similar
            // We try to clean it
            String cleanTitle = titleText
                .replaceAll(' - Cifra Club', '')
                .replaceAll(' | Cifra Club', '');

            // Split Song - Artist
            // Usually Cifra Club titles on DDG are "Song Name - Artist Name"
            // But sometimes "Artist - Song". We rely on user to pick the right one.

            results.add(
              CifraClubSuggestion(displayText: cleanTitle, fullUrl: url),
            );
          }
        }
        return results.take(5).toList();
      }
    } catch (e) {
      print('Search suggestion error: $e');
    }
    return [];
  }

  String _formatForUrl(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(
          RegExp(r'[^a-z0-9]'),
          '-',
        ) // Replace non-alphanumeric with hyphen
        .replaceAll(RegExp(r'-+'), '-') // Merge multiple hyphens
        .replaceAll(RegExp(r'^-|-$'), ''); // Trim hyphens
  }
}

class CifraClubSuggestion {
  final String displayText;
  final String fullUrl;

  CifraClubSuggestion({required this.displayText, required this.fullUrl});
}
