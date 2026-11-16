import 'package:flutter/material.dart';

import '../../services/statistics_service.dart';

class TaskActivitySection extends StatefulWidget {
  final String taskId;

  const TaskActivitySection({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskActivitySection> createState() =>
      _TaskActivitySectionState();
}

class _TaskActivitySectionState extends State<TaskActivitySection> {
  final StatisticsService _service = StatisticsService();

  late Future<List<Map<String, dynamic>>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    _activitiesFuture = _service.getTaskActivities(widget.taskId);
  }

  void _retry() {
    setState(() {
      _loadActivities();
    });
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'create':
        return 'Tạo công việc';
      case 'update':
        return 'Cập nhật công việc';
      case 'assign':
        return 'Thay đổi phân công';
      case 'share':
        return 'Chia sẻ công việc';
      case 'permission_change':
        return 'Thay đổi quyền chia sẻ';
      case 'remove_share':
        return 'Thu hồi quyền chia sẻ';
      case 'status_change':
        return 'Thay đổi trạng thái';
      default:
        return 'Hoạt động khác';
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'assign':
        return Icons.people_outline;
      case 'share':
        return Icons.share_outlined;
      case 'permission_change':
        return Icons.admin_panel_settings_outlined;
      case 'remove_share':
        return Icons.person_remove_outlined;
      case 'status_change':
        return Icons.flag_outlined;
      default:
        return Icons.history;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Không rõ thời gian';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return 'Không rõ thời gian';

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year lúc $hour:$minute';
  }

  String _userName(dynamic userData) {
    if (userData is Map) {
      final name = userData['fullName'] ??
          userData['name'] ??
          userData['email'];

      if (name != null && name.toString().isNotEmpty) {
        return name.toString();
      }
    }

    return 'Người dùng';
  }

  String _activityMessage(Map<String, dynamic> activity) {
    final details = activity['details'];

    if (details is Map) {
      final message = details['message'];

      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    }

    return _actionLabel((activity['action'] ?? '').toString());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'LỊCH SỬ HOẠT ĐỘNG',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tải lại lịch sử',
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _activitiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Không thể tải lịch sử hoạt động.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final activities = snapshot.data ?? [];

                if (activities.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 34,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có hoạt động nào.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: activities.map((activity) {
                    final action =
                        (activity['action'] ?? '').toString();
                    final userData = activity['userId'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _actionIcon(action),
                              color: colors.primary,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activityMessage(activity),
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Người thực hiện: ${_userName(userData)}',
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatDate(activity['createdAt']),
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
