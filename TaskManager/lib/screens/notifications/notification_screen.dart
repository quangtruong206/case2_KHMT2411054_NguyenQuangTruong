
import 'package:flutter/material.dart';

import '../../models/notification.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();

  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      await _service.markAsRead(notification.id);
      if (!mounted) return;

      setState(() {
        final index = _notifications.indexWhere(
              (item) => item.id == notification.id,
        );

        if (index != -1) {
          final old = _notifications[index];
          _notifications[index] = AppNotification(
            id: old.id,
            senderName: old.senderName,
            taskId: old.taskId,
            type: old.type,
            title: old.title,
            message: old.message,
            isRead: true,
            createdAt: old.createdAt,
          );
        }
      });
    } catch (error) {
      _showMessage('Không thể cập nhật thông báo: $error');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_notifications.every((item) => item.isRead)) {
      _showMessage('Tất cả thông báo đã được đọc');
      return;
    }

    try {
      await _service.markAllAsRead();
      if (!mounted) return;

      setState(() {
        _notifications = _notifications.map((item) {
          return AppNotification(
            id: item.id,
            senderName: item.senderName,
            taskId: item.taskId,
            type: item.type,
            title: item.title,
            message: item.message,
            isRead: true,
            createdAt: item.createdAt,
          );
        }).toList();
      });

      _showMessage('Đã đánh dấu tất cả là đã đọc');
    } catch (error) {
      _showMessage('Không thể cập nhật thông báo: $error');
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      await _service.deleteNotification(notification.id);
      if (!mounted) return;

      setState(() {
        _notifications.removeWhere((item) => item.id == notification.id);
      });

      _showMessage('Đã xóa thông báo');
    } catch (error) {
      _showMessage('Không thể xóa thông báo: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment_ind_outlined;
      case 'task_shared':
        return Icons.share_outlined;
      case 'task_updated':
        return Icons.edit_note_rounded;
      case 'task_status_changed':
        return Icons.sync_rounded;
      case 'share_permission_changed':
        return Icons.security_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _notificationColor(String type) {
    switch (type) {
      case 'task_assigned':
        return const Color(0xFF35B8F6);
      case 'task_shared':
        return const Color(0xFF7567F8);
      case 'task_updated':
        return const Color(0xFFFFB547);
      case 'task_status_changed':
        return const Color(0xFF22C58B);
      case 'share_permission_changed':
        return const Color(0xFFFF647C);
      default:
        return const Color(0xFF7567F8);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1 && !difference.isNegative) {
      return 'Vừa xong';
    }
    if (difference.inMinutes < 60 && !difference.isNegative) {
      return '${difference.inMinutes} phút trước';
    }
    if (difference.inHours < 24 && !difference.isNegative) {
      return '${difference.inHours} giờ trước';
    }
    if (difference.inDays < 7 && !difference.isNegative) {
      return '${difference.inDays} ngày trước';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _buildNotificationItem(AppNotification item) {
    final theme = Theme.of(context);
    final color = _notificationColor(item.type);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(item),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: item.isRead
                ? theme.dividerColor.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.55),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _markAsRead(item),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_notificationIcon(item.type), color: color),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7567F8),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatDate(item.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (!item.isRead)
                            Text(
                              'Chưa đọc',
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteNotification(item);
                    } else if (value == 'read') {
                      _markAsRead(item);
                    }
                  },
                  itemBuilder: (_) => [
                    if (!item.isRead)
                      const PopupMenuItem(
                        value: 'read',
                        child: Text('Đánh dấu đã đọc'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Xóa thông báo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((item) => !item.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _isProcessing ? null : _markAllAsRead,
              child: const Text('Đọc tất cả'),
            ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 52,
              ),
              const SizedBox(height: 12),
              Text(
                'Không thể tải thông báo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _notifications.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Icon(
              Icons.notifications_none_rounded,
              size: 76,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Bạn chưa có thông báo nào',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 7),
            Center(
              child: Text(
                'Thông báo mới sẽ xuất hiện tại đây.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        )
            : ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '$unreadCount thông báo chưa đọc',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            ..._notifications.map(_buildNotificationItem),
          ],
        ),
      ),
    );
  }
}
