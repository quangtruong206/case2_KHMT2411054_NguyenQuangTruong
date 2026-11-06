
import '../models/task.dart';
import 'api_client.dart';

class TaskService {
  final ApiClient api = ApiClient();

  // Lấy danh sách công việc
  Future<List<Task>> getTasks() async {
    final result = await api.get('/tasks');

    // Backend trong tài liệu Buổi 1
    // trả trực tiếp một danh sách JSON.
    final List data = result is List
        ? result
        : (result is Map && result['tasks'] is List)
        ? result['tasks'] as List
        : throw Exception(
      'API không trả về danh sách công việc',
    );

    return data.map((item) {
      return Task.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  // Tạo công việc
  Future<dynamic> createTask(
      Map<String, dynamic> data,
      ) async {
    return await api.post(
      '/tasks',
      body: data,
    );
  }

  // Cập nhật công việc
  Future<dynamic> updateTask(
      String id,
      Map<String, dynamic> data,
      ) async {
    return await api.put(
      '/tasks/$id',
      body: data,
    );
  }

  // Xóa công việc
  Future<dynamic> deleteTask(String id) async {
    return await api.delete('/tasks/$id');
  }

  // Cập nhật trạng thái
  Future<dynamic> updateStatus(
      String id,
      String status,
      ) async {
    return await api.patch(
      '/tasks/$id/status',
      body: {
        'status': status,
      },
    );
  }
}
