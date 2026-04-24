import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/env.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  String get _base => '${Env.apiUrl}/api';

  static const _timeout = Duration(seconds: 15);

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  String _errorMessage(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      return (map['message'] ?? map['error'] ?? 'Error desconocido').toString();
    } catch (_) {
      return 'Error del servidor';
    }
  }

  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        message: _errorMessage(res.body),
      );
    }
  }

  // ── Auth ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> firebaseLogin(String firebaseToken) async {
    final res = await http
        .post(
          Uri.parse('$_base/auth/firebase'),
          headers: _headers(),
          body: jsonEncode({'firebase_token': firebaseToken}),
        )
        .timeout(_timeout);
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> logout(String token) async {
    try {
      await http
          .post(Uri.parse('$_base/auth/logout'), headers: _headers(token: token))
          .timeout(_timeout);
    } catch (_) {
      // ignorar — igual limpiamos localmente
    }
  }
}
