import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'core/database/database_helper.dart';
import 'firebase_options.dart';
import 'models/birthday.dart';
import 'core/services/session_service.dart';
import 'models/user_session.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno (.env para dev, .env.production para prod)
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  await dotenv.load(fileName: env == 'production' ? '.env.production' : '.env');

  // Inicializar Firebase (solo para Google Sign-In)
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  // Verificar sesión local — sin llamadas a red
  final session = await SessionService.instance.getSession();

  runApp(CumpleApp(initialSession: session));
}

class CumpleApp extends StatefulWidget {
  final UserSession? initialSession;
  const CumpleApp({super.key, this.initialSession});

  @override
  State<CumpleApp> createState() => _CumpleAppState();
}

class _CumpleAppState extends State<CumpleApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _listenDeepLinks();
  }

  Future<void> _listenDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      await _handleImportLink(initialUri);

      _linkSub = _appLinks.uriLinkStream.listen((uri) {
        _handleImportLink(uri);
      });
    } on MissingPluginException {
      // El plugin puede no estar disponible después de hot-reload.
      // Se habilita en el próximo full restart.
    }
  }

  Future<void> _handleImportLink(Uri? uri) async {
    if (uri == null || uri.scheme != 'cumple' || uri.host != 'birthday-import') return;

    final session = await SessionService.instance.getSession();
    if (session == null) return;

    final name = uri.queryParameters['name']?.trim() ?? '';
    final day = int.tryParse(uri.queryParameters['birth_day'] ?? '');
    final month = int.tryParse(uri.queryParameters['birth_month'] ?? '');
    final yearRaw = uri.queryParameters['birth_year'];
    final year = (yearRaw == null || yearRaw.isEmpty) ? null : int.tryParse(yearRaw);
    final gender = uri.queryParameters['gender'];
    final interests = uri.queryParameters['interests'];
    final notes = uri.queryParameters['notes'];

    if (name.isEmpty || day == null || month == null) return;
    if (day < 1 || day > 31 || month < 1 || month > 12) return;

    final existing = await DatabaseHelper.instance.getAllBirthdays(
      ownerUserId: session.laravelUserId,
    );
    final alreadyImported = existing.any((b) =>
        b.name.toLowerCase() == name.toLowerCase() &&
        b.birthDay == day &&
        b.birthMonth == month &&
        b.birthYear == year);
    if (alreadyImported) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen(session: session)),
        (_) => false,
      );
      return;
    }

    await DatabaseHelper.instance.insertBirthday(
      Birthday(
        name: name,
        birthDay: day,
        birthMonth: month,
        birthYear: year,
        gender: (gender?.isEmpty ?? true) ? null : gender,
        interests: (interests?.isEmpty ?? true) ? null : interests,
        notes: (notes?.isEmpty ?? true) ? null : notes,
        createdAt: DateTime.now().toIso8601String(),
      ),
      ownerUserId: session.laravelUserId,
    );

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(session: session)),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cumpleaños App',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: widget.initialSession == null
          ? const LoginScreen()
          : widget.initialSession!.profileCompleted
              ? HomeScreen(session: widget.initialSession!)
              : ProfileSetupScreen(session: widget.initialSession!),
    );
  }
}

/// Llama esto desde cualquier lugar cuando el backend devuelva 401
void handleUnauthorized() async {
  await SessionService.instance.clearSession();
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}
