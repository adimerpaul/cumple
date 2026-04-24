import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'firebase_options.dart';
import 'core/services/session_service.dart';
import 'models/user_session.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

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

class CumpleApp extends StatelessWidget {
  final UserSession? initialSession;
  const CumpleApp({super.key, this.initialSession});

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
      home: initialSession != null
          ? HomeScreen(session: initialSession!)
          : const LoginScreen(),
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
