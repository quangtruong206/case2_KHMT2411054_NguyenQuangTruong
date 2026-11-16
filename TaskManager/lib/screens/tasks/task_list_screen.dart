
import 'package:flutter/material.dart';
import 'task_collaboration_screen.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import 'task_activity_section.dart';
import '../profile/profile_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();

  late Future<List<Task>> _tasksFuture;

  final TextEditingController _searchController =
  TextEditingController();

  String? _selectedStatus;
  String? _selectedPriority;
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTasks() {
    _tasksFuture = _taskService.getTasks(
      status: _selectedStatus,
      priority: _selectedPriority,
      keyword: _searchController.text.trim(),
      sortBy: _sortBy,
      order: _sortOrder,
    );
  }

  Future<void> _refreshTasks() async {
    setState(() {
      _loadTasks();
    });

    await _tasksFuture;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa thiết lập';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<DateTime?> _chooseDate(DateTime? currentDate) async {
    final now = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
  }

  // FORM TẠO VÀ CHỈNH SỬA CÔNG VIỆC

  // FORM TẠO VÀ CHỈNH SỬA CÔNG VIỆC
  Future<void> _showTaskForm({Task? task}) async {
    final isEditing = task != null;

    final titleController = TextEditingController(
      text: task?.title ?? '',
    );

    final descriptionController = TextEditingController(
      text: task?.description ?? '',
    );

    String priority = task?.priority.toLowerCase() ?? 'medium';
    String status = task?.status.toLowerCase() ?? 'todo';

    DateTime? startDate = task?.startDate;
    DateTime? dueDate = task?.dueDate;

    if (!['low', 'medium', 'high'].contains(priority)) {
      priority = 'medium';
    }

    if (!['todo', 'in_progress', 'completed'].contains(status)) {
      status = 'todo';
    }

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colorScheme = Theme.of(context).colorScheme;
            final isDark =
                Theme.of(context).brightness == Brightness.dark;

            Widget dateCard({
              required String label,
              required DateTime? date,
              required IconData icon,
              required VoidCallback onPressed,
              required VoidCallback onClear,
            }) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.35 : 0.55,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: colorScheme.primary,
                      size: 23,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Chọn ngày',
                      onPressed: onPressed,
                      icon: Icon(
                        Icons.edit_calendar_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (date != null)
                      IconButton(
                        tooltip: 'Xóa ngày',
                        onPressed: onClear,
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.error,
                        ),
                      ),
                  ],
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HEADER
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF7567F8),
                              Color(0xFF35B8F6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                isEditing
                                    ? Icons.edit_note_rounded
                                    : Icons.add_task_rounded,
                                color: Colors.white,
                                size: 27,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing
                                        ? 'CHỈNH SỬA CÔNG VIỆC'
                                        : 'TẠO CÔNG VIỆC MỚI',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    isEditing
                                        ? 'Cập nhật thông tin công việc'
                                        : 'Điền thông tin để tạo công việc',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // FORM CONTENT
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'THÔNG TIN CÔNG VIỆC',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 14),

                              TextField(
                                controller: titleController,
                                textCapitalization:
                                TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  labelText: 'Tên công việc *',
                                  hintText: 'Nhập tên công việc',
                                  prefixIcon: Icon(Icons.title),
                                ),
                              ),
                              const SizedBox(height: 14),

                              TextField(
                                controller: descriptionController,
                                textCapitalization:
                                TextCapitalization.sentences,
                                maxLines: 4,
                                minLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Mô tả công việc',
                                  hintText: 'Nhập nội dung mô tả...',
                                  alignLabelWithHint: true,
                                  prefixIcon: Icon(Icons.description_outlined),
                                ),
                              ),

                              const SizedBox(height: 22),

                              Text(
                                'PHÂN LOẠI',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 14),

                              DropdownButtonFormField<String>(
                                value: priority,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Mức độ ưu tiên',
                                  prefixIcon: Icon(Icons.flag_outlined),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'low',
                                    child: Text('Thấp'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'medium',
                                    child: Text('Trung bình'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'high',
                                    child: Text('Cao'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      priority = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 14),

                              DropdownButtonFormField<String>(
                                value: status,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Trạng thái',
                                  prefixIcon: Icon(
                                    Icons.track_changes_outlined,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'todo',
                                    child: Text('Chưa thực hiện'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'in_progress',
                                    child: Text('Đang thực hiện'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'completed',
                                    child: Text('Đã hoàn thành'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      status = value;
                                    });
                                  }
                                },
                              ),

                              const SizedBox(height: 22),

                              Text(
                                'THỜI GIAN THỰC HIỆN',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 14),

                              dateCard(
                                label: 'Ngày bắt đầu',
                                date: startDate,
                                icon: Icons.calendar_month_outlined,
                                onPressed: () async {
                                  final selected =
                                  await _chooseDate(startDate);
                                  if (selected != null) {
                                    setDialogState(() {
                                      startDate = selected;
                                    });
                                  }
                                },
                                onClear: () {
                                  setDialogState(() {
                                    startDate = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),

                              dateCard(
                                label: 'Hạn hoàn thành',
                                date: dueDate,
                                icon: Icons.event_available_outlined,
                                onPressed: () async {
                                  final selected =
                                  await _chooseDate(dueDate);
                                  if (selected != null) {
                                    setDialogState(() {
                                      dueDate = selected;
                                    });
                                  }
                                },
                                onClear: () {
                                  setDialogState(() {
                                    dueDate = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // BUTTONS
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: colorScheme.outline.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text('Hủy'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                icon: isSaving
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : Icon(
                                  isEditing
                                      ? Icons.save_outlined
                                      : Icons.add_rounded,
                                ),
                                label: Text(
                                  isSaving
                                      ? 'Đang lưu...'
                                      : isEditing
                                      ? 'Lưu thay đổi'
                                      : 'Tạo công việc',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                  final title =
                                  titleController.text.trim();

                                  if (title.isEmpty) {
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Vui lòng nhập tên công việc',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (startDate != null &&
                                      dueDate != null &&
                                      dueDate!.isBefore(startDate!)) {
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Hạn hoàn thành không được trước ngày bắt đầu',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() {
                                    isSaving = true;
                                  });

                                  try {
                                    if (isEditing) {
                                      await _taskService.updateTask(
                                        task.id,
                                        {
                                          'title': title,
                                          'description':
                                          descriptionController.text
                                              .trim(),
                                          'startDate': startDate
                                              ?.toIso8601String(),
                                          'dueDate': dueDate
                                              ?.toIso8601String(),
                                          'priority': priority,
                                          'status': status,
                                        },
                                      );
                                    } else {
                                      await _taskService.createTask(
                                        title,
                                        descriptionController.text
                                            .trim(),
                                        startDate: startDate,
                                        dueDate: dueDate,
                                        priority: priority,
                                        status: status,
                                      );
                                    }

                                    if (!mounted) return;

                                    Navigator.pop(dialogContext);
                                    await _refreshTasks();

                                    if (!mounted) return;

                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEditing
                                              ? 'Cập nhật công việc thành công'
                                              : 'Tạo công việc thành công',
                                        ),
                                      ),
                                    );
                                  } catch (error) {
                                    setDialogState(() {
                                      isSaving = false;
                                    });

                                    if (!mounted) return;

                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Có lỗi xảy ra: $error',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
  }


  // XEM CHI TIẾT CÔNG VIỆC

  // XEM CHI TIẾT CÔNG VIỆC
  Future<void> _showTaskDetail(Task task) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<Task>(
          future: _taskService.getTaskById(task.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Không tải được chi tiết'),
                content: Text('${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Đóng'),
                  ),
                ],
              );
            }

            if (!snapshot.hasData) {
              return AlertDialog(
                title: const Text('Thông báo'),
                content: const Text('Không tìm thấy công việc.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Đóng'),
                  ),
                ],
              );
            }

            final item = snapshot.data!;
            final colorScheme = Theme.of(context).colorScheme;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            Widget buildInfo(
                String label,
                String value,
                IconData icon,
                ) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.35 : 0.55,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      color: colorScheme.primary,
                      size: 21,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            value,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HEADER
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF7567F8),
                              Color(0xFF35B8F6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.assignment_outlined,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'CHI TIẾT CÔNG VIỆC',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Thông tin và tiến độ công việc',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // NỘI DUNG
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TỔNG QUAN',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 12),

                              buildInfo(
                                'Mô tả công việc',
                                item.description.isEmpty
                                    ? 'Không có mô tả'
                                    : item.description,
                                Icons.description_outlined,
                              ),
                              const SizedBox(height: 10),

                              buildInfo(
                                'Trạng thái',
                                item.statusLabel,
                                Icons.flag_outlined,
                              ),
                              const SizedBox(height: 10),

                              buildInfo(
                                'Mức độ ưu tiên',
                                item.priorityLabel,
                                Icons.priority_high_rounded,
                              ),

                              const SizedBox(height: 22),

                              Text(
                                'THỜI GIAN',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 12),

                              buildInfo(
                                'Ngày bắt đầu',
                                _formatDate(item.startDate),
                                Icons.calendar_today_outlined,
                              ),
                              const SizedBox(height: 10),

                              buildInfo(
                                'Hạn hoàn thành',
                                _formatDate(item.dueDate),
                                Icons.event_available_outlined,
                              ),

                              const SizedBox(height: 22),


                              TaskActivitySection(taskId: item.id),
                            ],
                          ),
                        ),
                      ),

                      // CÁC NÚT CHỨC NĂNG
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: colorScheme.outline.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.people_alt_outlined),
                                label: const Text('Phân công & chia sẻ'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  Navigator.pop(dialogContext);

                                  await Navigator.push(
                                    this.context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TaskCollaborationScreen(task: item),
                                    ),
                                  );

                                  if (!mounted) return;

                                  await _refreshTasks();
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Chỉnh sửa công việc'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  _showTaskForm(task: item);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  // CẬP NHẬT TRẠNG THÁI
  Future<void> _changeStatus(Task task, String status) async {
    try {
      await _taskService.updateTaskStatus(task.id, status);
      await _refreshTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật trạng thái thành công'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật trạng thái: $error')),
      );
    }
  }

  // XÓA CÔNG VIỆC
  Future<void> _deleteTask(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa công việc này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _taskService.deleteTask(id);
      await _refreshTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa công việc thành công')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xóa công việc: $error')),
      );
    }
  }


  // THANH TÌM KIẾM, LỌC VÀ SẮP XẾP
  Widget _buildSearchAndFilters() {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: colors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Tìm kiếm và bộ lọc',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên công việc...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Xóa nội dung tìm kiếm',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _refreshTasks();
                  },
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _refreshTasks(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'todo',
                        child: Text('Chưa làm'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'in_progress',
                        child: Text('Đang làm'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'completed',
                        child: Text('Hoàn thành'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                        _loadTasks();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedPriority,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Ưu tiên',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'low',
                        child: Text('Thấp'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'medium',
                        child: Text('Trung bình'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'high',
                        child: Text('Cao'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value;
                        _loadTasks();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sắp xếp theo',
                      prefixIcon: Icon(Icons.sort_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'createdAt',
                        child: Text('Thời gian tạo'),
                      ),
                      DropdownMenuItem(
                        value: 'dueDate',
                        child: Text('Hạn hoàn thành'),
                      ),
                      DropdownMenuItem(
                        value: 'priority',
                        child: Text('Mức ưu tiên'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _sortBy = value;
                        _loadTasks();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    tooltip: _sortOrder == 'asc'
                        ? 'Đang tăng dần'
                        : 'Đang giảm dần',
                    onPressed: () {
                      setState(() {
                        _sortOrder =
                        _sortOrder == 'asc' ? 'desc' : 'asc';
                        _loadTasks();
                      });
                    },
                    icon: Icon(
                      _sortOrder == 'asc'
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedStatus = null;
                    _selectedPriority = null;
                    _sortBy = 'createdAt';
                    _sortOrder = 'desc';
                    _loadTasks();
                  });
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 19),
                label: const Text('Đặt lại bộ lọc'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTag(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final colors = Theme.of(context).colorScheme;

    Color statusColor;
    IconData statusIcon;

    if (task.isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
    } else if (task.status == 'in_progress' ||
        task.status == 'inprogress') {
      statusColor = Colors.blue;
      statusIcon = Icons.timelapse_rounded;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.radio_button_unchecked;
    }

    Color priorityColor;
    IconData priorityIcon;

    switch (task.priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.redAccent;
        priorityIcon = Icons.keyboard_double_arrow_up;
        break;
      case 'low':
        priorityColor = Colors.green;
        priorityIcon = Icons.keyboard_arrow_down;
        break;
      default:
        priorityColor = Colors.orange;
        priorityIcon = Icons.drag_handle_rounded;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showTaskDetail(task),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: task.isCompleted
                        ? [
                      Colors.green.withValues(alpha: 0.9),
                      Colors.teal,
                    ]
                        : [
                      colors.primary,
                      const Color(0xFF35B8F6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  task.isCompleted
                      ? Icons.check_rounded
                      : Icons.work_outline_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.description.isEmpty
                          ? 'Chưa có mô tả công việc'
                          : task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _buildTaskTag(
                          task.statusLabel,
                          statusColor,
                          statusIcon,
                        ),
                        _buildTaskTag(
                          task.priorityLabel,
                          priorityColor,
                          priorityIcon,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 14,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Hạn: ${_formatDate(task.dueDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Thao tác',
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showTaskForm(task: task);
                  } else if (value == 'delete') {
                    _deleteTask(task.id);
                  } else if (value == 'todo') {
                    _changeStatus(task, 'todo');
                  } else if (value == 'in_progress') {
                    _changeStatus(task, 'in_progress');
                  } else if (value == 'completed') {
                    _changeStatus(task, 'completed');
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 9),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'todo',
                    child: Row(
                      children: [
                        Icon(Icons.radio_button_unchecked, size: 18),
                        SizedBox(width: 9),
                        Text('Chưa thực hiện'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'in_progress',
                    child: Row(
                      children: [
                        Icon(Icons.timelapse_rounded, size: 18),
                        SizedBox(width: 9),
                        Text('Đang thực hiện'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'completed',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 18),
                        SizedBox(width: 9),
                        Text('Đã hoàn thành'),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        SizedBox(width: 9),
                        Text(
                          'Xóa công việc',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý công việc',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Theo dõi và hoàn thành mục tiêu',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tài khoản',
            icon: const Icon(Icons.account_circle_outlined, size: 27),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: FutureBuilder<List<Task>>(
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 56,
                            color: colors.error,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isAuthError
                                ? 'Phiên đăng nhập đã hết hạn'
                                : 'Không thể tải danh sách công việc',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAuthError
                                ? 'Vui lòng đăng nhập lại để tiếp tục.'
                                : '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            icon: Icon(
                              isAuthError
                                  ? Icons.login_rounded
                                  : Icons.refresh_rounded,
                            ),
                            label: Text(
                              isAuthError ? 'Đăng nhập lại' : 'Thử lại',
                            ),
                            onPressed: () async {
                              if (isAuthError) {
                                await _taskService.logout();
                                if (!mounted) return;
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              } else {
                                await _refreshTasks();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshTasks,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 55),
                        Icon(
                          Icons.inbox_outlined,
                          size: 72,
                          color: colors.primary.withValues(alpha: 0.65),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'Chưa có công việc phù hợp',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Center(
                          child: Text(
                            'Thử thay đổi bộ lọc hoặc tạo công việc mới nhé.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshTasks,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 90, top: 4),
                    itemCount: tasks.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Danh sách công việc',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${tasks.length} công việc',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return _buildTaskCard(tasks[index - 1]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm công việc'),
      ),
    );
  }
}
