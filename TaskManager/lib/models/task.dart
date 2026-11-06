
class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.dueDate,
  });

  factory Task.fromJson(
      Map<String, dynamic> json,
      ) {
    return Task(
      id: (json['_id'] ?? json['id'] ?? '').toString(),

      title: json['title']?.toString() ?? '',

      description:
      json['description']?.toString() ?? '',

      category:
      json['category']?.toString() ?? 'Other',

      priority:
      json['priority']?.toString() ?? 'Medium',

      status:
      json['status']?.toString() ?? 'Pending',

      dueDate: json['dueDate'] == null
          ? null
          : DateTime.tryParse(
        json['dueDate'].toString(),
      ),
    );
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'todo':
        return 'Chưa thực hiện';

      case 'inprogress':
      case 'in_progress':
        return 'Đang thực hiện';

      case 'completed':
        return 'Đã hoàn thành';

      default:
        return status;
    }
  }

  String get priorityLabel {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Thấp';

      case 'medium':
        return 'Trung bình';

      case 'high':
        return 'Cao';

      default:
        return priority;
    }
  }
}
