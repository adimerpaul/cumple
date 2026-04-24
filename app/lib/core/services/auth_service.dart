import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../models/birthday.dart';
import '../../models/user_session.dart';
import '../database/database_helper.dart';
import 'api_service.dart';
import 'session_service.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  Future<UserSession> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Inicio de sesión cancelado');

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;

    final firebaseToken = await firebaseUser.getIdToken(true);
    if (firebaseToken == null) throw Exception('No se pudo obtener el token de Firebase');

    final photoB64 = await _downloadPhotoBase64(firebaseUser.photoURL);
    final data = await ApiService.instance.firebaseLogin(firebaseToken);

    final userData = data['user'] as Map<String, dynamic>;
    final session = UserSession(
      firebaseUid: firebaseUser.uid,
      laravelUserId: userData['id'] as int,
      name: userData['name'] as String,
      email: userData['email'] as String,
      photoB64: photoB64,
      laravelToken: data['token'] as String,
      profileCompleted: userData['profile_completed'] as bool? ?? false,
      createdAt: DateTime.now().toIso8601String(),
    );

    await SessionService.instance.saveSession(session);
    await syncBirthdaysFromBackend(session);
    return session;
  }

  Future<void> signOut(String laravelToken) async {
    await ApiService.instance.logout(laravelToken);
    await SessionService.instance.clearSession();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<String?> _downloadPhotoBase64(String? photoUrl) async {
    if (photoUrl == null) return null;
    try {
      final url = photoUrl.contains('?') ? '$photoUrl&sz=64' : '$photoUrl?sz=64';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) return base64Encode(res.bodyBytes);
    } catch (_) {}
    return null;
  }

  Future<void> syncBirthdaysFromBackend(UserSession session) async {
    final remote = await ApiService.instance.getBirthdays(session.laravelToken);
    final parsed = remote
        .whereType<Map<String, dynamic>>()
        .map(_birthdayFromApi)
        .toList();

    await DatabaseHelper.instance.replaceBirthdaysForOwner(
      ownerUserId: session.laravelUserId,
      birthdays: parsed,
    );
  }

  Birthday _birthdayFromApi(Map<String, dynamic> map) {
    final birthDay = (map['birth_day'] as num?)?.toInt() ?? 1;
    final birthMonth = (map['birth_month'] as num?)?.toInt() ?? 1;
    final birthYear = (map['birth_year'] as num?)?.toInt();
    final isSelfRaw = map['is_self'];
    final isSelf = isSelfRaw == true || isSelfRaw == 1;
    final backendId = (map['id'] as num?)?.toInt();

    return Birthday(
      backendBirthdayId: backendId,
      name: (map['name'] as String? ?? '').trim(),
      birthDay: birthDay,
      birthMonth: birthMonth,
      birthYear: birthYear,
      gender: map['gender'] as String?,
      interests: map['interests'] as String?,
      notes: map['notes'] as String?,
      isSelf: isSelf,
      createdAt: (map['created_at'] as String?) ?? DateTime.now().toIso8601String(),
    );
  }
}
