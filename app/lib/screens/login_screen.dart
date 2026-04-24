import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../core/services/auth_service.dart';
import '../core/services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handleGoogleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final session = await AuthService.instance.signInWithGoogle();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(session: session)),
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Blobs decorativos
                Positioned(
                  top: -40, left: -40,
                  child: Container(
                    width: 200, height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0x0D2563FF),
                    ),
                  ),
                ),
                Positioned(
                  top: 80, right: -30,
                  child: Container(
                    width: 130, height: 130,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0x072563FF),
                    ),
                  ),
                ),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícono app
                        Container(
                          width: 84, height: 84,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.blue, AppColors.blueMid],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blue.withOpacity(0.30),
                                blurRadius: 36, offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.cake_rounded, size: 42, color: Colors.white),
                        ),
                        const SizedBox(height: 22),

                        // Título
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2),
                            children: const [
                              TextSpan(text: 'Cumpleaños\n', style: TextStyle(color: AppColors.fg)),
                              TextSpan(text: 'App 🎂', style: TextStyle(color: AppColors.blue)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          'Registra y recuerda los cumpleaños\nde quienes más quieres',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.fg2, height: 1.7),
                        ),
                        const SizedBox(height: 36),

                        // Error
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFDC2626)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Botón Google
                        _GoogleSignInButton(loading: _loading, onPressed: _handleGoogleSignIn),
                        const SizedBox(height: 16),

                        Text(
                          'Al continuar aceptas nuestros términos de uso\ny política de privacidad',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.fg3, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer azul
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.blueDark, AppColors.blue],
              ),
            ),
            padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['🎂 Registra', '📅 Recuerda', '🎁 Celebra']
                  .map((t) => Text(t,
                      style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: loading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.09), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.blue))
              else
                const _GoogleLogo(size: 22),
              const SizedBox(width: 12),
              Text(
                loading ? 'Iniciando sesión…' : 'Continuar con Google',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _GoogleLogoPainter()));
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width * 0.22;
    final r = (size.width - sw) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: r);

    void arc(Color color, double startDeg, double sweepDeg) {
      canvas.drawArc(rect, startDeg * pi / 180, sweepDeg * pi / 180, false,
          Paint()..color = color..strokeWidth = sw..style = PaintingStyle.stroke..strokeCap = StrokeCap.butt);
    }

    arc(const Color(0xFF4285F4), -90, 90);
    arc(const Color(0xFF34A853), 0, 90);
    arc(const Color(0xFFFBBC05), 90, 90);
    arc(const Color(0xFFEA4335), 180, 90);

    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, size.height / 2 - sw / 2, size.width / 2, sw),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
