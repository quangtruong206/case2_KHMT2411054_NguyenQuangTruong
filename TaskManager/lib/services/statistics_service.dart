
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class StatisticsService {
  static const String _baseUrl = 'http://10.0.2.2:3000/api';

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('UNAUTHORIZED');
    }

    return token;
  }

  Future<Map<String, dynamic>> _getData(String endpoint) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception('Dữ liệu API không hợp lệ');
    }

    if (response.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      throw Exception('UNAUTHORIZED');
    }

    throw Exception(
      'Lỗi API (${response.statusCode}): ${response.body}',
    );
  }

  // 1. Thống kê công việc theo trạng thái
  Future<Map<String, dynamic>> getTaskStatistics() {
    return _getData('/statistics/tasks');
  }

  // 2. Thống kê công việc được giao và đang phụ trách
  Future<Map<String, dynamic>> getAssignmentStatistics() {
    return _getData('/statistics/assignments');
  }

  // 3. Thống kê công việc sắp đến hạn và quá hạn
  Future<Map<String, dynamic>> getDeadlineStatistics() {
    return _getData('/statistics/deadlines');
  }

  // 4. Lấy lịch sử hoạt động của một công việc
  Future<List<Map<String, dynamic>>> getTaskActivities(
    String taskId,
  ) async {
    final data = await _getData('/tasks/$taskId/activities');

    final activities = data['activities'];

    if (activities is! List) {
      return [];
    }

    return activities
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // Chuyển danh sách JSON thành danh sách Task
  List<Task> parseTasks(dynamic data) {
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => Task.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}
