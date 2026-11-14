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

  // Hàm xóa token khi hết hạn hoặc không hợp lệ
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // 1. LẤY DANH SÁCH CÔNG VIỆC
  Future<List<Task>> getTasks() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('UNAUTHORIZED');
    }

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Task>.from(
        data.map((item) => Task.fromJson(item as Map<String, dynamic>)),
      );
    } else if (response.statusCode == 401) {
      await logout(); // Xóa token hỏng
      throw Exception('UNAUTHORIZED');
    } else {
      throw Exception('Lỗi API (${response.statusCode}): ${response.body}');
    }
  }

  // 2. TẠO CÔNG VIỆC MỚI
  Future<bool> createTask(String title, String description) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
      }),
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  // 3. XÓA CÔNG VIỆC
  Future<bool> deleteTask(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }
}