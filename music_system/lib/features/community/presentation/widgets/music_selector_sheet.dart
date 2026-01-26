import 'package:flutter/material.dart';

class MusicSelectorSheet extends StatefulWidget {
  const MusicSelectorSheet({super.key});

  @override
  State<MusicSelectorSheet> createState() => _MusicSelectorSheetState();
}

class _MusicSelectorSheetState extends State<MusicSelectorSheet> {
  // Mock data for now, could be fetched from a repository
  final List<Map<String, dynamic>> _dummyMusics = [
    {
      'id': '1',
      'title': 'Vibe Sertaneja',
      'artist': 'João e Maria',
      'url': 'https://example.com/music1.mp3'
    },
    {
      'id': '2',
      'title': 'Rock na Estrada',
      'artist': 'Banda X',
      'url': 'https://example.com/music2.mp3'
    },
    {
      'id': '3',
      'title': 'Piseiro Animado',
      'artist': 'Rei do Piseiro',
      'url': 'https://example.com/music3.mp3'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selecionar Música',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 10),
          const TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Pesquisar...',
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _dummyMusics.length,
              itemBuilder: (context, index) {
                final music = _dummyMusics[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    color: Colors.white10,
                    child:
                        const Icon(Icons.music_note, color: Color(0xFFE5B80B)),
                  ),
                  title: Text(music['title'],
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(music['artist'],
                      style: const TextStyle(color: Colors.white54)),
                  onTap: () => Navigator.pop(context, music),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
