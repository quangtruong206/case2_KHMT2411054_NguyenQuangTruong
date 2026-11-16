
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../notifications/notification_screen.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../profile/profile_screen.dart';
import 'task_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();

  late Future<List<Task>> _tasksFuture;
  int _unreadCount = 0;
  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        _unreadCount = count;
      });
    } catch (error) {
      debugPrint('Không thể tải số thông báo chưa đọc: $error');
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationScreen(),
      ),
    );

    if (!mounted) return;
    _loadUnreadCount();
  }

  void _loadTasks() {
    _tasksFuture = _taskService.getTasks(
      sortBy: 'createdAt',
      order: 'desc',
    );
  }

  Future<void> _refresh() async {
    setState(_loadTasks);

    await Future.wait([
      _tasksFuture,
      _loadUnreadCount(),
    ]);
  }

  bool _isInProgress(Task task) {
    final status = task.status.toLowerCase().replaceAll(' ', '_');
    return status == 'in_progress' || status == 'inprogress';
  }

  bool _isOverdue(Task task) {
    if (task.isCompleted || task.dueDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );

    return due.isBefore(today);
  }

  bool _isUpcoming(Task task) {
    if (task.isCompleted || task.dueDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(const Duration(days: 7));
    final due = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );

    return !due.isBefore(today) && !due.isAfter(limit);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa có hạn';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _priorityColor(Task task) {
    switch (task.priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFFF647C);
      case 'low':
        return const Color(0xFF22C58B);
      default:
        return const Color(0xFFFFB547);
    }
  }

  Color _statusColor(Task task) {
    if (task.isCompleted) return const Color(0xFF22C58B);
    if (_isInProgress(task)) return const Color(0xFF35B8F6);
    return const Color(0xFFFFB547);
  }


  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            const Color(0xFF5145CD),
            const Color(0xFF247DBB),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TASK MANAGER',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Xin chào! 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Cùng hoàn thành mục tiêu hôm nay nhé.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Nút thông báo
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(17),
                child: IconButton(
                  tooltip: 'Thông báo',
                  onPressed: _openNotifications,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          right: -7,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(
                              minWidth: 17,
                              minHeight: 17,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF647C),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _unreadCount > 99 ? '99+' : '$_unreadCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 9),

              // Nút tài khoản
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(17),
                child: IconButton(
                  tooltip: 'Tài khoản',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }


  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color),
                ),
                Text(
                  value.toString(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(List<Task> tasks) {
    final theme = Theme.of(context);
    final total = tasks.length;
    final completed = tasks.where((task) => task.isCompleted).length;
    final progress = total == 0 ? 0.0 : completed / total;
    final percentage = (progress * 100).round();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.track_changes_rounded,
                  color: Color(0xFF7567F8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tiến độ hoàn thành',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF7567F8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation(
                  Color(0xFF7567F8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$completed/$total công việc đã hoàn thành',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? action}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(task);
    final priorityColor = _priorityColor(task);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 58,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatDate(task.dueDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    children: [
                      _buildTag(
                        task.statusLabel,
                        statusColor,
                      ),
                      _buildTag(
                        task.priorityLabel,
                        priorityColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDashboardContent(List<Task> tasks) {
    final total = tasks.length;
    final completed = tasks.where((task) => task.isCompleted).length;
    final inProgress = tasks.where(_isInProgress).length;
    final overdue = tasks.where(_isOverdue).length;
    final upcoming = tasks.where(_isUpcoming).length;

    final recentTasks = tasks.take(5).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _buildHeader(context),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Tổng quan công việc'),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCard(
                      title: 'Tổng công việc',
                      value: total,
                      icon: Icons.work_outline_rounded,
                      color: const Color(0xFF7567F8),
                      description: 'Tất cả công việc',
                    ),
                    _buildStatCard(
                      title: 'Đang thực hiện',
                      value: inProgress,
                      icon: Icons.autorenew_rounded,
                      color: const Color(0xFF35B8F6),
                      description: 'Đang được xử lý',
                    ),
                    _buildStatCard(
                      title: 'Đã hoàn thành',
                      value: completed,
                      icon: Icons.task_alt_rounded,
                      color: const Color(0xFF22C58B),
                      description: 'Đã hoàn tất',
                    ),
                    _buildStatCard(
                      title: 'Quá hạn',
                      value: overdue,
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFFF647C),
                      description: 'Cần chú ý ngay',
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _buildProgressCard(tasks),

                const SizedBox(height: 22),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB547).withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: Color(0xFFFFB547),
                      ),
                    ),
                    title: const Text(
                      'Sắp đến hạn',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Trong vòng 7 ngày tới'),
                    trailing: Text(
                      upcoming.toString(),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB547),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle(
                  'Công việc gần đây',
                  action: TextButton(
                    onPressed: _openTaskList,
                    child: const Text('Xem tất cả'),
                  ),
                ),

                if (recentTasks.isEmpty)
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 45,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 10),
                          const Text('Bạn chưa có công việc nào'),
                          const SizedBox(height: 5),
                          Text(
                            'Hãy tạo công việc đầu tiên của bạn.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...recentTasks.map(_buildTaskItem),

                const SizedBox(height: 12),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _openTaskList,
                    icon: const Icon(Icons.list_alt_rounded),
                    label: const Text('ĐI ĐẾN QUẢN LÝ CÔNG VIỆC'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7567F8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openTaskList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TaskListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            final isAuthError =
                snapshot.error.toString().contains('UNAUTHORIZED') ||
                    snapshot.error.toString().contains('401');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAuthError
                          ? Icons.lock_outline_rounded
                          : Icons.cloud_off_rounded,
                      size: 55,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      isAuthError
                          ? 'Phiên đăng nhập đã hết hạn.'
                          : 'Không thể tải dữ liệu công việc.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (isAuthError) {
                          await _taskService.logout();

                          if (!mounted) return;

                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                                (route) => false,
                          );
                        } else {
                          _refresh();
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        isAuthError ? 'Đăng nhập lại' : 'Thử lại',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildDashboardContent(snapshot.data ?? []);
        },
      ),
    );
  }
}
