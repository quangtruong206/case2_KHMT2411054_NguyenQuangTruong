
class TaskUser {
  final String id;
  final String fullName;
  final String email;

  TaskUser({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory TaskUser.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return TaskUser(id: json?.toString() ?? '', fullName: '', email: '');
    }

    return TaskUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}

class TaskShare {
  final String userId;
  final TaskUser user;
  final String permission;

  TaskShare({
    required this.userId,
    required this.user,
    required this.permission,
  });

  factory TaskShare.fromJson(Map<String, dynamic> json) {
    final userJson = json['userId'];

    return TaskShare(
      userId: userJson is Map
          ? (userJson['_id'] ?? '').toString()
          : (userJson ?? '').toString(),
      user: TaskUser.fromJson(userJson),
      permission: (json['permission'] ?? 'viewer').toString(),
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final DateTime? startDate;
  final DateTime? dueDate;

  final TaskUser? creator;
  final List<TaskUser> assignees;
  final TaskUser? primaryAssignee;
  final List<TaskShare> shares;
  final String role;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.startDate,
    this.dueDate,
    this.creator,
    this.assignees = const [],
    this.primaryAssignee,
    this.shares = const [],
    this.role = '',
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // API chi tiết trả về { task, role, shares }
    final isDetail = json['task'] is Map;
    final data = isDetail
        ? Map<String, dynamic>.from(json['task'])
        : json;

    final assigneeData = data['assigneeIds'] as List? ?? [];
    final shareData = isDetail ? json['shares'] as List? ?? [] : [];

    return Task(
      id: (data['_id'] ?? data['id'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? 'Other').toString(),
      priority: (data['priority'] ?? 'medium').toString(),
      status: (data['status'] ?? 'todo').toString(),
      startDate: data['startDate'] == null
          ? null
          : DateTime.tryParse(data['startDate'].toString()),
      dueDate: data['dueDate'] == null
          ? null
          : DateTime.tryParse(data['dueDate'].toString()),
      creator: data['createdBy'] == null
          ? null
          : TaskUser.fromJson(data['createdBy']),
      assignees: assigneeData
          .map((e) => TaskUser.fromJson(e))
          .toList(),
      primaryAssignee: data['primaryAssigneeId'] == null
          ? null
          : TaskUser.fromJson(data['primaryAssigneeId']),
      shares: shareData
          .map((e) => TaskShare.fromJson(
        Map<String, dynamic>.from(e),
      ))
          .toList(),
      role: (isDetail ? json['role'] : '')?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority.toLowerCase(),
      'status': status.toLowerCase(),
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  bool get isCompleted => status.toLowerCase() == 'completed';

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

  String get roleLabel {
    switch (role) {
      case 'owner':
        return 'Người tạo';
      case 'assignee':
        return 'Người được giao';
      case 'editor':
        return 'Người chỉnh sửa';
      case 'viewer':
        return 'Người xem';
      default:
        return 'Công việc';
    }
  }
}
