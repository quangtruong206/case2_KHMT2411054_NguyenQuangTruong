
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _service = StatisticsService();

  late Future<Map<String, dynamic>> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    _statisticsFuture = _fetchStatistics();
  }

  Future<Map<String, dynamic>> _fetchStatistics() async {
    final results = await Future.wait([
      _service.getTaskStatistics(),
      _service.getAssignmentStatistics(),
      _service.getDeadlineStatistics(),
    ]);

    return {
      'tasks': results[0],
      'assignments': results[1],
      'deadlines': results[2],
    };
  }

  Future<void> _refresh() async {
    setState(_loadStatistics);
    await _statisticsFuture;
  }

  Map<String, dynamic> _statisticsOf(dynamic data) {
    if (data is Map && data['statistics'] is Map) {
      return Map<String, dynamic>.from(data['statistics']);
    }
    return {};
  }

  int _number(Map<String, dynamic> data, String key) {
    return (data[key] as num?)?.toInt() ?? 0;
  }

  List<Task> _tasksOf(dynamic data, String key) {
    if (data is! Map) return [];
    return _service.parseTasks(data[key]);
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSection({
    required String title,
    required List<Task> tasks,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
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
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${tasks.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Không có công việc nào.'),
              )
            else
              ...tasks.map(
                (task) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.assignment_outlined,
                    color: color,
                  ),
                  title: Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    task.dueDate == null
                        ? 'Chưa có hạn hoàn thành'
                        : 'Hạn: ${_formatDate(task.dueDate!)}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    return '$day/$month/${localDate.year}';
  }

  Widget _buildCompletionCard({
    required int total,
    required int completed,
  }) {
    final theme = Theme.of(context);
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).round();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 9,
                      backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF16A085),
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percentage%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Hoàn thành',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hiệu quả hoàn thành',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '$completed / $total công việc',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Công việc đã hoàn thành',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required String title,
    required int value,
    required int total,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final progress = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$value',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution({
    required int total,
    required int todo,
    required int inProgress,
    required int completed,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phân bổ trạng thái công việc',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            _buildStatusRow(
              title: 'Cần làm',
              value: todo,
              total: total,
              color: Colors.orange,
            ),
            _buildStatusRow(
              title: 'Đang làm',
              value: inProgress,
              total: total,
              color: Colors.blue,
            ),
            _buildStatusRow(
              title: 'Hoàn thành',
              value: completed,
              total: total,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildContent(Map<String, dynamic> data) {
    final taskStats = _statisticsOf(data['tasks']);
    final assignmentStats = _statisticsOf(data['assignments']);
    final deadlineStats = _statisticsOf(data['deadlines']);

    final overdueTasks = _tasksOf(data['deadlines'], 'overdueTasks');
    final upcomingTasks = _tasksOf(data['deadlines'], 'upcomingTasks');

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tổng quan công việc',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildCompletionCard(
            total: _number(taskStats, 'total'),
            completed: _number(taskStats, 'completed'),
          ),
          const SizedBox(height: 16),
          _buildStatusDistribution(
            total: _number(taskStats, 'total'),
            todo: _number(taskStats, 'todo'),
            inProgress: _number(taskStats, 'in_progress'),
            completed: _number(taskStats, 'completed'),
          ),
          const SizedBox(height: 24),
          Text(
            'Thống kê phân công',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Được giao',
                  value: _number(assignmentStats, 'assigned'),
                  icon: Icons.assignment_ind_outlined,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Đang phụ trách',
                  value: _number(assignmentStats, 'responsible'),
                  icon: Icons.person_pin_circle_outlined,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Theo dõi thời hạn',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Đã quá hạn',
                  value: _number(deadlineStats, 'overdue'),
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Sắp đến hạn',
                  value: _number(deadlineStats, 'upcoming'),
                  icon: Icons.event_available_outlined,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTaskSection(
            title: 'Công việc quá hạn',
            tasks: overdueTasks,
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildTaskSection(
            title: 'Công việc sắp đến hạn',
            tasks: upcomingTasks,
            icon: Icons.event_available_outlined,
            color: Colors.deepOrange,
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Kéo xuống để cập nhật số liệu',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê công việc'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statisticsFuture,
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
                          ? Icons.lock_outline
                          : Icons.cloud_off_outlined,
                      size: 52,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isAuthError
                          ? 'Phiên đăng nhập đã hết hạn.'
                          : 'Không thể tải dữ liệu thống kê.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(_loadStatistics);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Không có dữ liệu thống kê.'),
            );
          }

          return _buildContent(snapshot.data!);
        },
      ),
    );
  }
}
