
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() =>
      _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {

  final TaskService service = TaskService();

  List<Task> tasks = [];

  bool isLoading = true;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // Tải dữ liệu từ MongoDB thông qua API
  Future<void> loadTasks() async {

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {

      final result = await service.getTasks();

      if (!mounted) return;

      setState(() {
        tasks = result;
        isLoading = false;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });

    }
  }

  // Hiển thị màu trạng thái
  Color getStatusColor(String status) {

    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;

      case 'inprogress':
      case 'in_progress':
        return Colors.blue;

      default:
        return Colors.orange;
    }
  }

  // Hiển thị thẻ công việc
  Widget buildTaskCard(Task task) {

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [

                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const Icon(
                  Icons.task_alt,
                  color: Colors.blue,
                ),

              ],
            ),

            const SizedBox(height: 8),

            Text(
              task.description.isEmpty
                  ? 'Không có mô tả'
                  : task.description,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                const Icon(
                  Icons.flag,
                  size: 18,
                ),

                const SizedBox(width: 5),

                Text(
                  'Ưu tiên: ${task.priorityLabel}',
                ),

              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [

                const Icon(
                  Icons.circle,
                  size: 12,
                ),

                const SizedBox(width: 8),

                Text(
                  'Trạng thái: ${task.statusLabel}',
                  style: TextStyle(
                    color: getStatusColor(task.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),

              ],
            ),

            if (task.dueDate != null) ...[
              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Hạn: ${DateFormat('dd/MM/yyyy').format(task.dueDate!)}',
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            Text(
              'Danh mục: ${task.category}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          'TASK MANAGER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,

        actions: [

          IconButton(
            onPressed: loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),

        ],
      ),

      body: buildBody(),

    );
  }

  Widget buildBody() {

    // Trạng thái đang tải
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Trạng thái lỗi
    if (errorMessage != null) {

      return Center(

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),

              const SizedBox(height: 15),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: loadTasks,
                child: const Text('Thử lại'),
              ),

            ],
          ),
        ),
      );
    }

    // Không có dữ liệu
    if (tasks.isEmpty) {

      return RefreshIndicator(

        onRefresh: loadTasks,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          children: const [

            SizedBox(height: 200),

            Center(
              child: Text(
                'Chưa có công việc nào',
                style: TextStyle(fontSize: 18),
              ),
            ),

          ],
        ),
      );
    }

    // Có dữ liệu
    return RefreshIndicator(

      onRefresh: loadTasks,

      child: ListView.builder(

        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.all(12),

        itemCount: tasks.length,

        itemBuilder: (context, index) {

          return buildTaskCard(tasks[index]);

        },
      ),
    );
  }
}
