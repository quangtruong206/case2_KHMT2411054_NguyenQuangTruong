
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
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
            return AlertDialog(
              title: Text(
                isEditing ? 'Chỉnh sửa công việc' : 'Thêm công việc mới',
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tên công việc *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả công việc',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration: const InputDecoration(
                          labelText: 'Mức độ ưu tiên',
                          border: OutlineInputBorder(),
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
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(),
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
                      const SizedBox(height: 12),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month),
                        title: const Text('Ngày bắt đầu'),
                        subtitle: Text(_formatDate(startDate)),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_calendar),
                          onPressed: () async {
                            final selected = await _chooseDate(startDate);
                            if (selected != null) {
                              setDialogState(() {
                                startDate = selected;
                              });
                            }
                          },
                        ),
                      ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: const Text('Hạn hoàn thành'),
                        subtitle: Text(_formatDate(dueDate)),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_calendar),
                          onPressed: () async {
                            final selected = await _chooseDate(dueDate);
                            if (selected != null) {
                              setDialogState(() {
                                dueDate = selected;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    final title = titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
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
                      ScaffoldMessenger.of(this.context).showSnackBar(
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
                        await _taskService.updateTask(task.id, {
                          'title': title,
                          'description':
                          descriptionController.text.trim(),
                          'startDate':
                          startDate?.toIso8601String(),
                          'dueDate':
                          dueDate?.toIso8601String(),
                          'priority': priority,
                          'status': status,
                        });
                      } else {
                        await _taskService.createTask(
                          title,
                          descriptionController.text.trim(),
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

                      ScaffoldMessenger.of(this.context).showSnackBar(
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

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Có lỗi xảy ra: $error'),
                        ),
                      );
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : Text(isEditing ? 'Lưu thay đổi' : 'Thêm công việc'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
  }

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
                  height: 100,
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

            final item = snapshot.data!;

            return AlertDialog(
              title: const Text('Chi tiết công việc'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    const Divider(),

                    const Text(
                      'Mô tả',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item.description.isEmpty
                          ? 'Không có mô tả'
                          : item.description,
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Trạng thái',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(item.statusLabel),
                    const SizedBox(height: 12),

                    const Text(
                      'Mức độ ưu tiên',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(item.priorityLabel),
                    const SizedBox(height: 12),

                    const Text(
                      'Ngày bắt đầu',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_formatDate(item.startDate)),
                    const SizedBox(height: 12),

                    const Text(
                      'Hạn hoàn thành',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_formatDate(item.dueDate)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showTaskForm(task: item);
                  },
                  child: const Text('Chỉnh sửa'),
                ),
              ],
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên công việc...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _refreshTasks();
                },
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _refreshTasks(),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tất cả'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'todo',
                      child: Text('Chưa thực hiện'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'in_progress',
                      child: Text('Đang thực hiện'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'completed',
                      child: Text('Đã hoàn thành'),
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

              const SizedBox(width: 8),

              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedPriority,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ưu tiên',
                    border: OutlineInputBorder(),
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

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sắp xếp theo',
                    border: OutlineInputBorder(),
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
                      child: Text('Mức độ ưu tiên'),
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

              IconButton(
                tooltip: _sortOrder == 'asc'
                    ? 'Tăng dần'
                    : 'Giảm dần',
                icon: Icon(
                  _sortOrder == 'asc'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                onPressed: () {
                  setState(() {
                    _sortOrder =
                    _sortOrder == 'asc' ? 'desc' : 'asc';
                    _loadTasks();
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

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
              icon: const Icon(Icons.restart_alt),
              label: const Text('Đặt lại bộ lọc'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        onTap: () => _showTaskDetail(task),

        title: Text(
          task.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.description.isEmpty
                    ? 'Không có mô tả'
                    : task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text('Trạng thái: ${task.statusLabel}'),
              Text('Ưu tiên: ${task.priorityLabel}'),
              Text('Hạn hoàn thành: ${_formatDate(task.dueDate)}'),
            ],
          ),
        ),

        trailing: PopupMenuButton<String>(
          tooltip: 'Thao tác',
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
              child: Text('Chỉnh sửa'),
            ),
            PopupMenuItem(
              value: 'todo',
              child: Text('Đặt: Chưa thực hiện'),
            ),
            PopupMenuItem(
              value: 'in_progress',
              child: Text('Đặt: Đang thực hiện'),
            ),
            PopupMenuItem(
              value: 'completed',
              child: Text('Đặt: Đã hoàn thành'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                'Xóa công việc',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),

        leading: CircleAvatar(
          backgroundColor: task.isCompleted
              ? Colors.green
              : const Color(0xFF6C5CE7),
          child: Icon(
            task.isCompleted ? Icons.check : Icons.work_outline,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý công việc'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          _buildSearchAndFilters(),

          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 55,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isAuthError
                                ? 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'
                                : '${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (isAuthError) {
                                await _taskService.logout();

                                if (!mounted) return;

                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              } else {
                                _refreshTasks();
                              }
                            },
                            child: Text(
                              isAuthError ? 'Đăng nhập lại' : 'Thử lại',
                            ),
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
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'Không có công việc phù hợp',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
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
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(tasks[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskForm(),
        backgroundColor: const Color(0xFF6C5CE7),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
