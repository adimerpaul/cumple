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
      throw ApiException(statusCode: res.statusCode, message: _errorMessage(res.body));
    }
  }

  // ── Auth ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> firebaseLogin(String firebaseToken) async {
    final res = await http
        .post(Uri.parse('$_base/auth/firebase'),
            headers: _headers(), body: jsonEncode({'firebase_token': firebaseToken}))
        .timeout(_timeout);
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> logout(String token) async {
    try {
      await http
          .post(Uri.parse('$_base/auth/logout'), headers: _headers(token: token))
          .timeout(_timeout);
    } catch (_) {}
  }

  // ── Birthdays ─────────────────────────────────────────────

  Future<Map<String, dynamic>> createBirthday({
    required String token,
    required String name,
    required int birthDay,
    required int birthMonth,
    int? birthYear,
    String? gender,
    String? interests,
    String? notes,
    bool isSelf = false,
  }) async {
    final res = await http
        .post(Uri.parse('$_base/birthdays'),
            headers: _headers(token: token),
            body: jsonEncode({
              'name': name,
              'birth_day': birthDay,
              'birth_month': birthMonth,
              if (birthYear != null) 'birth_year': birthYear,
              if (gender != null) 'gender': gender,
              if (interests != null) 'interests': interests,
              if (notes != null) 'notes': notes,
              'is_self': isSelf,
            }))
        .timeout(_timeout);
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getBirthdays(String token) async {
    final res = await http
        .get(Uri.parse('$_base/birthdays'), headers: _headers(token: token))
        .timeout(_timeout);
    _check(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['birthdays'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getSelfBirthdayShareLink(String token) async {
    final res = await http
        .get(
          Uri.parse('$_base/birthdays/self/share-link'),
          headers: _headers(token: token),
        )
        .timeout(_timeout);
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBirthday({
    required String token,
    required int birthdayId,
    required String name,
    required int birthDay,
    required int birthMonth,
    int? birthYear,
    String? gender,
    String? interests,
    String? notes,
  }) async {
    final res = await http
        .put(Uri.parse('$_base/birthdays/$birthdayId'),
            headers: _headers(token: token),
            body: jsonEncode({
              'name': name,
              'birth_day': birthDay,
              'birth_month': birthMonth,
              'birth_year': birthYear,
              'gender': gender,
              'interests': interests,
              'notes': notes,
            }))
        .timeout(_timeout);
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteBirthday({
    required String token,
    required int birthdayId,
  }) async {
    final res = await http
        .delete(
          Uri.parse('$_base/birthdays/$birthdayId'),
          headers: _headers(token: token),
        )
        .timeout(_timeout);
    _check(res);
  }
}
