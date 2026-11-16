
class AppNotification {
  final String id;
  final String? senderName;
  final String? taskId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    this.senderName,
    this.taskId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final task = json['task'];

    String? senderName;
    if (sender is Map<String, dynamic>) {
      senderName = (sender['fullName'] ?? sender['name'] ?? sender['email'])
          ?.toString();
    }

    String? taskId;
    if (task is Map<String, dynamic>) {
      taskId = task['_id']?.toString();
    } else if (task != null) {
      taskId = task.toString();
    }

    return AppNotification(
      id: json['_id']?.toString() ?? '',
      senderName: senderName,
      taskId: taskId,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Thông báo',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString())?.toLocal(),
    );
  }
}
