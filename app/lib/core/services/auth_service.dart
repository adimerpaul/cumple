import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../models/user_session.dart';
import 'api_service.dart';
import 'session_service.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  Future<UserSession> signInWithGoogle() async {
    // 1. Google Sign-In
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Inicio de sesión cancelado');

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;

    // 2. Token Firebase (forzar refresco)
    final firebaseToken = await firebaseUser.getIdToken(true);
    if (firebaseToken == null) throw Exception('No se pudo obtener el token de Firebase');

    // 3. Foto pequeña en base64
    final photoB64 = await _downloadPhotoBase64(firebaseUser.photoURL);

    // 4. Login en Laravel
    final data = await ApiService.instance.firebaseLogin(firebaseToken);

    // 5. Guardar sesión en SQLite
    final session = UserSession(
      firebaseUid: firebaseUser.uid,
      laravelUserId: data['user']['id'] as int,
      name: data['user']['name'] as String,
      email: data['user']['email'] as String,
      photoB64: photoB64,
      laravelToken: data['token'] as String,
      createdAt: DateTime.now().toIso8601String(),
    );

    await SessionService.instance.saveSession(session);
    return session;
  }

  Future<void> signOut(String laravelToken) async {
    await ApiService.instance.logout(laravelToken);
    await SessionService.instance.clearSession();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Descarga foto de perfil de Google en tamaño pequeño y la convierte a base64
  Future<String?> _downloadPhotoBase64(String? photoUrl) async {
    if (photoUrl == null) return null;
    try {
      final small = photoUrl.contains('?')
          ? '$photoUrl&sz=64'
          : '$photoUrl?sz=64';
      final res = await http.get(Uri.parse(small)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) return base64Encode(res.bodyBytes);
    } catch (_) {}
    return null;
  }
}
