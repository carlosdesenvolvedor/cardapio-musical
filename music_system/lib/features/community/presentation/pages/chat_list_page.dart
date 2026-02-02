import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:music_system/config/theme/app_theme.dart';
import 'package:music_system/core/presentation/widgets/app_network_image.dart';
import 'package:music_system/features/community/domain/entities/conversation_entity.dart';
import 'package:music_system/features/community/domain/repositories/chat_repository.dart';
import 'package:music_system/features/community/presentation/pages/chat_page.dart';
import 'package:music_system/injection_container.dart';
import 'package:intl/intl.dart';

class ChatListPage extends StatelessWidget {
  final String currentUserId;

  const ChatListPage({super.key, required this.currentUserId});

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays < 7) {
      return DateFormat('EEE').format(time); // Day of week
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Minhas Conversas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<ConversationEntity>>(
        stream: sl<ChatRepository>().streamConversations(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }

          if (snapshot.hasError) {
            // Often initial empty state might throw if collection doesn't exist, handle gracefully
            return Center(
              child: Text(
                'Nenhuma conversa encontrada.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 60, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'Você ainda não tem conversas.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherUserId = conversation.participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    final userData =
                        userSnapshot.data?.data() as Map<String, dynamic>?;
                    final otherUserName = userData?['artisticName'] ??
                        userData?['name'] ??
                        conversation.otherUserName ??
                        'Usuário';
                    final otherUserPhoto =
                        userData?['photoUrl'] ?? conversation.otherUserPhotoUrl;

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(conversation.id)
                          .collection('messages')
                          .where('receiverId', isEqualTo: currentUserId)
                          .where('isRead', isEqualTo: false)
                          .limit(1)
                          .snapshots(),
                      builder: (context, unreadSnapshot) {
                        final hasUnread = unreadSnapshot.hasData &&
                            unreadSnapshot.data!.docs.isNotEmpty;

                        return ListTile(
                          onTap: () {
                            if (otherUserId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    currentUserId: currentUserId,
                                    targetUserId: otherUserId,
                                    targetUserName: otherUserName,
                                    targetUserPhoto: otherUserPhoto,
                                  ),
                                ),
                              );
                            }
                          },
                          leading: Container(
                            padding:
                                const EdgeInsets.all(2), // Space for border
                            decoration: hasUnread
                                ? const BoxDecoration(
                                    color: Colors.yellow, // Yellow border color
                                    shape: BoxShape.circle,
                                  )
                                : null,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[900],
                              backgroundImage: otherUserPhoto != null &&
                                      otherUserPhoto.isNotEmpty
                                  ? AppNetworkImage.provider(otherUserPhoto)
                                  : null,
                              child: otherUserPhoto == null ||
                                      otherUserPhoto.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.white54)
                                  : null,
                            ),
                          ),
                          title: Text(
                            otherUserName,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: hasUnread
                                    ? FontWeight.bold
                                    : FontWeight.normal, // Bold text for unread
                                fontSize: 16),
                          ),
                          subtitle: Text(
                            conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: hasUnread
                                    ? Colors.white
                                    : Colors
                                        .white70, // Brighter text for unread
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal),
                          ),
                          trailing: Text(
                            _formatTime(conversation.lastMessageAt),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        );
                      },
                    );
                  });
            },
          );
        },
      ),
    );
  }
}
