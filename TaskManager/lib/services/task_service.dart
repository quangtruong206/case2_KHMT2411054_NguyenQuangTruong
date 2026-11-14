
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class TaskService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/tasks';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }


  // PHẦN C: PHÂN CÔNG VÀ CHIA SẺ

  Future<dynamic> _partCRequest(
      String method,
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final apiRoot = baseUrl.replaceFirst('/tasks', '');
    final request = http.Request(
      method,
      Uri.parse('$apiRoot$endpoint'),
    );

    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    throw Exception(
      'Lỗi API (${response.statusCode}): ${response.body}',
    );
  }

  // Tìm kiếm người dùng
  Future<List<TaskUser>> searchUsers(String keyword) async {
    if (keyword.trim().length < 2) return [];

    final result = await _partCRequest(
      'GET',
      '/users/search?q=${Uri.encodeQueryComponent(keyword.trim())}',
    );

    if (result is! List) return [];

    return result
        .map((e) => TaskUser.fromJson(e))
        .where((user) => user.id.isNotEmpty)
        .toList();
  }

  // Phân công người dùng vào công việc
  Future<bool> assignUsers(
      String taskId,
      List<String> assigneeIds,
      String? primaryAssigneeId,
      ) async {
    await _partCRequest(
      'PUT',
      '/tasks/$taskId/assignees',
      body: {
        'assigneeIds': assigneeIds,
        'primaryAssigneeId': primaryAssigneeId,
      },
    );

    return true;
  }

  // Lấy danh sách người được chia sẻ công việc
  Future<List<TaskShare>> getTaskShares(String taskId) async {
    final result = await _partCRequest(
      'GET',
      '/tasks/$taskId/shares',
    );

    final List<dynamic> items;

    if (result is List) {
      items = result;
    } else if (result is Map && result['shares'] is List) {
      items = result['shares'] as List;
    } else {
      items = [];
    }

    return items
        .map((e) => TaskShare.fromJson(
      Map<String, dynamic>.from(e),
    ))
        .toList();
  }

  // Chia sẻ công việc cho người dùng
  Future<bool> shareTask(
      String taskId,
      String userId,
      String permission,
      ) async {
    await _partCRequest(
      'POST',
      '/tasks/$taskId/shares',
      body: {
        'userId': userId,
        'permission': permission,
      },
    );

    return true;
  }

  // Thay đổi quyền chia sẻ
  Future<bool> updateSharePermission(
      String taskId,
      String userId,
      String permission,
      ) async {
    await _partCRequest(
      'PATCH',
      '/tasks/$taskId/shares/$userId',
      body: {
        'permission': permission,
      },
    );

    return true;
  }

  // Thu hồi quyền chia sẻ
  Future<bool> removeTaskShare(
      String taskId,
      String userId,
      ) async {
    await _partCRequest(
      'DELETE',
      '/tasks/$taskId/shares/$userId',
    );

    return true;
  }


  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // LẤY DANH SÁCH, TÌM KIẾM, LỌC VÀ SẮP XẾP
  Future<List<Task>> getTasks({
    String? status,
    String? priority,
    String? keyword,
    String? sortBy,
    String? order,
  }) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('UNAUTHORIZED');
    }

    final query = <String, String>{};

    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    if (priority != null && priority.isNotEmpty) {
      query['priority'] = priority;
    }

    if (keyword != null && keyword.isNotEmpty) {
      query['q'] = keyword;
    }

    if (sortBy != null && sortBy.isNotEmpty) {
      query['sortBy'] = sortBy;
    }

    if (order != null && order.isNotEmpty) {
      query['order'] = order;
    }

    final uri = Uri.parse(baseUrl).replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (response.statusCode == 401) {
      await logout();
      throw Exception('UNAUTHORIZED');
    }

    throw Exception(
      'Lỗi lấy danh sách (${response.statusCode}): ${response.body}',
    );
  }

  // TẠO CÔNG VIỆC
  Future<bool> createTask(
      String title,
      String description, {
        DateTime? startDate,
        DateTime? dueDate,
        String priority = 'medium',
        String status = 'todo',
      }) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('UNAUTHORIZED');
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'startDate': startDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority,
        'status': status,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    if (response.statusCode == 401) {
      await logout();
      throw Exception('UNAUTHORIZED');
    }

    throw Exception('Tạo công việc thất bại: ${response.body}');
  }

  // XEM CHI TIẾT CÔNG VIỆC
  Future<Task> getTaskById(String id) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('UNAUTHORIZED');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 401) {
      await logout();
      throw Exception('UNAUTHORIZED');
    }

    throw Exception('Lỗi xem chi tiết: ${response.body}');
  }

  // CHỈNH SỬA CÔNG VIỆC
  Future<bool> updateTask(
      String id,
      Map<String, dynamic> data,
      ) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('UNAUTHORIZED');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 401) {
      await logout();
      throw Exception('UNAUTHORIZED');
    }

    throw Exception('Cập nhật thất bại: ${response.body}');
  }

  // CẬP NHẬT TRẠNG THÁI
  Future<bool> updateTaskStatus(String id, String status) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('UNAUTHORIZED');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 401) {
      await logout();
      throw Exception('UNAUTHORIZED');
    }

    throw Exception('Cập nhật trạng thái thất bại: ${response.body}');
  }

  // XÓA CÔNG VIỆC
  Future<bool> deleteTask(String id) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('UNAUTHORIZED');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 401) {
      await logout();
      throw Exception('UNAUTHORIZED');
    }

    throw Exception('Xóa công việc thất bại: ${response.body}');
  }
}
