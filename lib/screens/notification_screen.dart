import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_exchange/models/notification_model.dart';
import 'package:skill_exchange/services/notification_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
      case 'session confirmed':
        return Icons.event_available_rounded;
      case 'reminder':
      case 'session reminder':
        return Icons.notifications_active_rounded;
      case 'message':
      case 'new message':
        return Icons.chat_bubble_outline_rounded;
      case 'certificate':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getIconBackgroundColor(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
      case 'session confirmed':
        return Colors.purple.shade50;
      case 'reminder':
      case 'session reminder':
        return Colors.purple.shade100;
      case 'message':
      case 'new message':
        return Colors.purple.shade50;
      default:
        return Colors.purple.shade50;
    }
  }

  Color _getIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
      case 'session confirmed':
        return Colors.deepPurple;
      case 'reminder':
      case 'session reminder':
        return Colors.deepPurple.shade700;
      case 'message':
      case 'new message':
        return Colors.deepPurple;
      default:
        return Colors.deepPurple;
    }
  }

  String _formatTime(dynamic rawTime) {
    if (rawTime is Timestamp) {
      final dateTime = rawTime.toDate();
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final NotificationService notificationService = NotificationService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Notification ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.deepPurple,
              ),
            ),
            Text('🔔', style: TextStyle(fontSize: 18)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.getUserNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading notifications: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          // Pure dynamic check: Shows Empty State if no backend data
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 70,
                    color: Colors.deepPurple.shade200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];

              return GestureDetector(
                onTap: () {
                  if (!item.isRead) {
                    notificationService.markAsRead(item.notificationId);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: item.isRead
                        ? Colors.white
                        : Colors.deepPurple.shade50.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: item.isRead
                          ? Colors.grey.shade100
                          : Colors.deepPurple.shade100,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getIconBackgroundColor(item.type),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _getNotificationIcon(item.type),
                          color: _getIconColor(item.type),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: item.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.body,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatTime(item.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}