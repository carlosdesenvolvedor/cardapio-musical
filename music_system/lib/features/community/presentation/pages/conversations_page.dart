import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../bloc/conversations_bloc.dart';
import '../bloc/conversations_event.dart';
import '../bloc/conversations_state.dart';
import 'chat_page.dart';

class ConversationsPage extends StatelessWidget {
  final String userId;

  const ConversationsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ConversationsBloc>()..add(ConversationsStarted(userId)),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Mensagens',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note, size: 28),
              onPressed: () {
                // TODO: New conversation
              },
            ),
          ],
        ),
        body: BlocBuilder<ConversationsBloc, ConversationsState>(
          builder: (context, state) {
            if (state.status == ConversationsStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE5B80B)),
              );
            }

            if (state.conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma conversa ainda',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: state.conversations.length,
              itemBuilder: (context, index) {
                final conversation = state.conversations[index];
                final otherUserId = conversation.participants.firstWhere(
                  (id) => id != userId,
                );

                return ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        conversation.otherUserPhotoUrl != null &&
                            conversation.otherUserPhotoUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(
                            conversation.otherUserPhotoUrl!,
                          )
                        : null,
                    child:
                        (conversation.otherUserPhotoUrl == null ||
                            conversation.otherUserPhotoUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 28)
                        : null,
                  ),
                  title: Text(
                    conversation.otherUserName ?? 'Artista',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(conversation.lastMessageAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          currentUserId: userId,
                          targetUserId: otherUserId,
                          targetUserName:
                              conversation.otherUserName ?? 'Artista',
                          targetUserPhoto: conversation.otherUserPhotoUrl,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays < 7) {
      return DateFormat('E').format(date);
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }
}
