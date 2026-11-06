
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class ApiClient {
  static String? token;

  Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',

      if (token != null)
        'Authorization': 'Bearer $token',
    };
  }

  Uri makeUri(String path) {
    return Uri.parse(
      '${AppConstants.baseUrl}$path',
    );
  }

  dynamic handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Lỗi HTTP: ${response.statusCode}',
        );
      }
      return null;
    }

    final data = jsonDecode(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final message = data is Map
          ? data['message']?.toString()
          : null;

      throw Exception(
        message ?? 'Lỗi HTTP: ${response.statusCode}',
      );
    }

    return data;
  }

  // Lấy dữ liệu
  Future<dynamic> get(String path) async {
    final response = await http.get(
      makeUri(path),
      headers: headers,
    );

    return handleResponse(response);
  }

  // Thêm dữ liệu
  Future<dynamic> post(
      String path, {
        Map<String, dynamic>? body,
      }) async {
    final response = await http.post(
      makeUri(path),
      headers: headers,
      body: jsonEncode(body ?? {}),
    );

    return handleResponse(response);
  }

  // Cập nhật dữ liệu
  Future<dynamic> put(
      String path, {
        required Map<String, dynamic> body,
      }) async {
    final response = await http.put(
      makeUri(path),
      headers: headers,
      body: jsonEncode(body),
    );

    return handleResponse(response);
  }

  // Cập nhật một phần dữ liệu
  Future<dynamic> patch(
      String path, {
        Map<String, dynamic>? body,
      }) async {
    final response = await http.patch(
      makeUri(path),
      headers: headers,
      body: jsonEncode(body ?? {}),
    );

    return handleResponse(response);
  }

  // Xóa dữ liệu
  Future<dynamic> delete(String path) async {
    final response = await http.delete(
      makeUri(path),
      headers: headers,
    );

    return handleResponse(response);
  }
}
