import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/auth';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 1. ĐĂNG KÝ
  Future<dynamic> register(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fullName': fullName, 'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': data['message'] ?? 'Thành công'
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ'};
    }
  }

  // 2. ĐĂNG NHẬP
  Future<dynamic> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return {'success': true, 'message': 'Đăng nhập thành công!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ'};
    }
  }

  // 3. ĐĂNG XUẤT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // 4. XEM THÔNG TIN CÁ NHÂN
  Future<dynamic> getProfile() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  // 5. CẬP NHẬT THÔNG TIN CÁ NHÂN
  Future<dynamic> updateProfile(String fullName, String email) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'fullName': fullName, 'email': email}),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message'] ?? 'Cập nhật thành công'};
  }

  // 6. ĐỔI MẬT KHẨU
  Future<dynamic> changePassword(String oldPassword, String newPassword) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message'] ?? 'Đổi mật khẩu thành công'};
  }
}