import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:music_system/features/community/domain/entities/notification_entity.dart';
import 'package:music_system/features/community/presentation/pages/chat_page.dart';
import 'package:music_system/features/community/presentation/pages/post_detail_page.dart';
import 'package:music_system/features/auth/presentation/pages/profile_page.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../../../../injection_container.dart';
import '../../../bookings/domain/entities/service_contract_entity.dart';
import '../../../bookings/data/datasources/service_contract_remote_data_source.dart';

class ActivityPage extends StatelessWidget {
  final String userId;

  const ActivityPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Atividade',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state.status == NotificationsStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5B80B)),
            );
          }
          if (state.status == NotificationsStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'Erro ao carregar notificações',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<NotificationsBloc>().add(
                            NotificationsStarted(userId),
                          );
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          if (state.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma atividade recente',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.notifications.length,
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return _buildNotificationItem(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationEntity notification,
  ) {
    String message = '';
    IconData icon = Icons.notifications;
    Color iconColor = Colors.grey;

    switch (notification.type) {
      case NotificationType.like:
        message = 'curtiu sua publicação.';
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case NotificationType.follow:
        message = 'agora é seu fã.';
        icon = Icons.person_add;
        iconColor = Colors.blue;
        break;
      case NotificationType.comment:
        message = 'comentou: "${notification.message}"';
        icon = Icons.comment;
        iconColor = Colors.green;
        break;
      case NotificationType.message:
        message = 'enviou uma mensagem.';
        icon = Icons.chat;
        iconColor = const Color(0xFFE5B80B);
        break;
      case NotificationType.system:
        message = notification.message ?? 'Alerta do sistema.';
        icon = Icons.info;
        iconColor = Colors.orange;
        break;
      case NotificationType.band_invite:
        message = 'convidou você para tocar em uma banda!';
        icon = Icons.group_add;
        iconColor = const Color(0xFFE5B80B);
        break;
      case NotificationType.budget_request:
        message =
            'enviou uma nova solicitação de orçamento: "${notification.message}"';
        icon = Icons.assignment_turned_in;
        iconColor = const Color(0xFFE5B80B);
        break;
    }

    return ListTile(
      tileColor: notification.isRead
          ? Colors.transparent
          : const Color(0xFF1E1E1E), // Subtle highlight for unread
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: notification.senderPhotoUrl != null &&
                    notification.senderPhotoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(notification.senderPhotoUrl!)
                : null,
            child: (notification.senderPhotoUrl == null ||
                    notification.senderPhotoUrl!.isEmpty)
                ? const Icon(Icons.person, size: 20)
                : null,
          ),
          if (!notification.isRead)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5B80B), // Primary color indicator
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 10, color: iconColor),
            ),
          ),
        ],
      ),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          children: [
            TextSpan(
              text: notification.senderName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' '),
            TextSpan(text: message),
          ],
        ),
      ),
      subtitle: Text(
        _formatDate(notification.createdAt),
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: notification.type == NotificationType.like &&
              notification.postId != null
          ? const Icon(Icons.image, size: 30, color: Colors.white10)
          : (notification.type == NotificationType.budget_request
              ? _buildBudgetActions(context, notification)
              : null),
      onTap: () {
        context.read<NotificationsBloc>().add(
              MarkNotificationAsRead(userId, notification.id),
            );

        // Create mapped actions
        if (notification.type == NotificationType.message) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                currentUserId: userId,
                targetUserId: notification.senderId,
                targetUserName: notification.senderName,
                targetUserPhoto: notification.senderPhotoUrl,
              ),
            ),
          );
        } else if (notification.type == NotificationType.follow) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(
                userId: notification.senderId,
                email: '', // Not needed for viewing
                showAppBar: true,
              ),
            ),
          );
        } else if ((notification.type == NotificationType.like ||
                notification.type == NotificationType.comment) &&
            notification.postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailPage(
                postId: notification.postId!,
                currentUserId: userId,
              ),
            ),
          );
        } else if (notification.type == NotificationType.band_invite) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(
                userId: notification.senderId,
                email: '',
                showAppBar: true,
              ),
            ),
          );
        }
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }

  Widget _buildBudgetActions(
      BuildContext context, NotificationEntity notification) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          onPressed: () => _updateBudgetStatus(
              context, notification, ContractStatus.accepted),
        ),
        IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red),
          onPressed: () => _updateBudgetStatus(
              context, notification, ContractStatus.declined),
        ),
      ],
    );
  }

  void _updateBudgetStatus(BuildContext context,
      NotificationEntity notification, ContractStatus status) async {
    if (notification.postId == null) return;

    try {
      await sl<ServiceContractRemoteDataSource>()
          .updateContractStatus(notification.postId!, status);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == ContractStatus.accepted
                ? 'Orçamento aceito!'
                : 'Orçamento recusado.'),
            backgroundColor:
                status == ContractStatus.accepted ? Colors.green : Colors.red,
          ),
        );

        // Mark notification as read
        context.read<NotificationsBloc>().add(
              MarkNotificationAsRead(userId, notification.id),
            );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar status: $e')),
        );
      }
    }
  }
}
