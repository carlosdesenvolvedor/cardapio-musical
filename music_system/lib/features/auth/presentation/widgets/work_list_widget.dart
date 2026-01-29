import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_system/features/auth/domain/entities/work.dart';
import 'package:music_system/features/auth/presentation/bloc/works/works_bloc.dart';
import 'package:music_system/features/auth/presentation/bloc/works/works_event.dart';
import 'package:music_system/features/auth/presentation/bloc/works/works_state.dart';
import 'package:music_system/features/auth/presentation/pages/add_work_page.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkListWidget extends StatefulWidget {
  final String userId;
  final bool isOwner;

  const WorkListWidget(
      {super.key, required this.userId, required this.isOwner});

  @override
  State<WorkListWidget> createState() => _WorkListWidgetState();
}

class _WorkListWidgetState extends State<WorkListWidget> {
  // Map to store audio players for each playing item
  final Map<String, AudioPlayer> _audioPlayers = {};
  String? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    context.read<WorksBloc>().add(LoadWorks(widget.userId));
  }

  @override
  void dispose() {
    _audioPlayers.forEach((_, player) => player.dispose());
    super.dispose();
  }

  Future<void> _toggleAudio(String workId, String url) async {
    if (_currentlyPlayingId != null && _currentlyPlayingId != workId) {
      await _audioPlayers[_currentlyPlayingId]?.stop();
      setState(() => _currentlyPlayingId = null);
    }

    if (!_audioPlayers.containsKey(workId)) {
      _audioPlayers[workId] = AudioPlayer();
    }

    final player = _audioPlayers[workId]!;

    if (player.state == PlayerState.playing) {
      await player.pause();
      setState(() => _currentlyPlayingId = null);
    } else {
      await player.play(UrlSource(url));
      setState(() => _currentlyPlayingId = workId);

      player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _currentlyPlayingId = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorksBloc, WorksState>(
      builder: (context, state) {
        if (state is WorksLoading && state is! WorksLoaded) {
          // Show loading only if not already loaded (to avoid flicker on reload)
          // But checking runtime type logic: WorksLoaded extends WorksState.
          // If 'WorksLoading' is a separate class, this check is fine.
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5B80B)));
        }

        if (state is WorksError) {
          return Center(
              child: Text('Erro: ${state.message}',
                  style: const TextStyle(color: Colors.white)));
        }

        List<Work> works = [];
        if (state is WorksLoaded) {
          works = state.works;
        }

        return Column(
          children: [
            if (widget.isOwner)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<WorksBloc>(),
                          child: AddWorkPage(userId: widget.userId),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text('ADICIONAR NOVO TRABALHO',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5B80B),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (works.isEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.work_outline,
                              size: 48, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            widget.isOwner
                                ? 'Adicione seus melhores trabalhos!'
                                : 'Nenhum trabalho publicado ainda.',
                            style:
                                TextStyle(color: Colors.white.withOpacity(0.5)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: works.length,
                  itemBuilder: (context, index) {
                    final work = works[index];
                    return _buildWorkItem(work);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWorkItem(Work work) {
    bool isPlaying = _currentlyPlayingId == work.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ExpansionTile(
        title: Text(
          work.title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          work.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        iconColor: const Color(0xFFE5B80B),
        collapsedIconColor: Colors.white54,
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // Full Description
          if (work.description.length > 50)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(work.description,
                    style: const TextStyle(color: Colors.white70)),
              ),
            ),

          // Audio Player
          if (work.fileType == 'mp3' && work.fileUrl != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5B80B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFE5B80B).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _toggleAudio(work.id, work.fileUrl!),
                    icon: Icon(isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled),
                    color: const Color(0xFFE5B80B),
                    iconSize: 48,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Demo de Áudio',
                            style: TextStyle(
                                color: Color(0xFFE5B80B),
                                fontWeight: FontWeight.bold)),
                        Text(isPlaying ? 'Tocando...' : 'Toque para ouvir',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // PDF Viewer / Download
          if (work.fileType == 'pdf' && work.fileUrl != null)
            ListTile(
              leading: const Icon(Icons.picture_as_pdf,
                  color: Colors.redAccent, size: 32),
              title: const Text('Arquivo PDF',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Clique para visualizar',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () => launchUrl(Uri.parse(work.fileUrl!),
                  mode: LaunchMode.externalApplication),
            ),

          // Links
          if (work.links.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Links Relacionados:',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ...work.links.map((link) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.link, color: Color(0xFFE5B80B)),
                  title: Text(link.title,
                      style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.open_in_new,
                      color: Colors.white30, size: 16),
                  onTap: () async {
                    final uri = Uri.parse(link.url.startsWith('http')
                        ? link.url
                        : 'https://${link.url}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                )),
          ],

          if (widget.isOwner) ...[
            const Divider(color: Colors.white24, height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<WorksBloc>(),
                          child: AddWorkPage(
                              userId: widget.userId, workToEdit: work),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  label: const Text('EDITAR',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Excluir trabalho?'),
                        content: const Text('Essa ação não pode ser desfeita.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCELAR')),
                          TextButton(
                            onPressed: () {
                              context
                                  .read<WorksBloc>()
                                  .add(DeleteWork(work.id, widget.userId));
                              Navigator.pop(context);
                            },
                            child: const Text('EXCLUIR',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  label: const Text('EXCLUIR',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}
