
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
