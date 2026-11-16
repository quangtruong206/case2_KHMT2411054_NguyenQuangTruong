
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification.dart';

class NotificationService {
  static const String _baseUrl =
      'http://10.0.2.2:3000/api/notifications';

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('UNAUTHORIZED');
    }

    return token;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    }

    throw Exception(
      'Lỗi API (${response.statusCode}): ${response.body}',
    );
  }

  Future<List<AppNotification>> getNotifications() async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: await _headers(),
    );

    final data = _handleResponse(response);
    final items = data['notifications'] as List<dynamic>? ?? [];

    return items
        .map(
          (item) => AppNotification.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/unread-count'),
      headers: await _headers(),
    );

    final data = _handleResponse(response);
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAsRead(String id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$id/read'),
      headers: await _headers(),
    );

    _handleResponse(response);
  }

  Future<void> markAllAsRead() async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/read-all'),
      headers: await _headers(),
    );

    _handleResponse(response);
  }

  Future<void> deleteNotification(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: await _headers(),
    );

    _handleResponse(response);
  }
}
