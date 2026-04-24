import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../core/database/database_helper.dart';
import '../core/services/api_service.dart';
import '../core/services/session_service.dart';
import '../models/birthday.dart';
import '../models/user_session.dart';
import 'home_screen.dart';

const _interests = [
  '🎮 Gaming', '🎵 Música', '📚 Lectura', '🏋️ Deporte',
  '🍕 Gastronomía', '🎨 Arte', '✈️ Viajes', '🎬 Cine',
  '🐾 Animales', '🌿 Naturaleza', '💻 Tecnología', '📸 Fotografía',
  '🧩 Puzzles', '🍷 Vinos', '🎲 Juegos', '🛍️ Moda',
];

const _genders = [
  ('hombre', '👨 Hombre'),
  ('mujer', '👩 Mujer'),
  ('otro', '🌈 Otro'),
];

class ProfileSetupScreen extends StatefulWidget {
  final UserSession session;
  const ProfileSetupScreen({super.key, required this.session});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _dayCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _gender;
  final Set<String> _selectedInterests = {};
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final day = int.tryParse(_dayCtrl.text.trim());
    final month = int.tryParse(_monthCtrl.text.trim());
    final year = _yearCtrl.text.trim().isEmpty ? null : int.tryParse(_yearCtrl.text.trim());

    if (day == null || month == null || day < 1 || day > 31 || month < 1 || month > 12) {
      setState(() => _error = 'Ingresa un día y mes válidos');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final interests = _selectedInterests.isEmpty ? null : _selectedInterests.join('||');
      final name = widget.session.name;
      final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

      // 1. Guardar en Laravel
      await ApiService.instance.createBirthday(
        token: widget.session.laravelToken,
        name: name,
        birthDay: day,
        birthMonth: month,
        birthYear: year,
        gender: _gender,
        interests: interests,
        notes: notes,
        isSelf: true,
      );

      // 2. Guardar en SQLite local
      await DatabaseHelper.instance.insertBirthday(Birthday(
        name: name,
        birthDay: day,
        birthMonth: month,
        birthYear: year,
        gender: _gender,
        interests: interests,
        notes: notes,
        isSelf: true,
        createdAt: DateTime.now().toIso8601String(),
      ));

      // 3. Marcar perfil completo en sesión local
      final updated = widget.session.copyWith(profileCompleted: true);
      await SessionService.instance.saveSession(updated);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(session: updated)),
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
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.blueDark, AppColors.blue],
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('¡Hola, ${widget.session.name.split(' ').first}! 👋',
                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              const SizedBox(height: 4),
              Text('Cuéntanos sobre ti',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Este será tu primer cumpleaños registrado',
                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7), fontSize: 13)),
            ]),
          ),

          // Formulario
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                      child: Text(_error!,
                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFDC2626))),
                    ),

                  // Fecha de cumpleaños
                  _SectionLabel('Fecha de cumpleaños *'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _DateField(ctrl: _dayCtrl, hint: 'DD', label: 'Día', max: 31)),
                    const SizedBox(width: 8),
                    Expanded(child: _DateField(ctrl: _monthCtrl, hint: 'MM', label: 'Mes', max: 12)),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: _DateField(ctrl: _yearCtrl, hint: 'AAAA', label: 'Año (opcional)', max: 9999)),
                  ]),
                  const SizedBox(height: 20),

                  // Género
                  _SectionLabel('Género'),
                  const SizedBox(height: 8),
                  Row(
                    children: _genders.map((g) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _gender = _gender == g.$1 ? null : g.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.only(right: g.$1 != 'otro' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _gender == g.$1 ? AppColors.blue : AppColors.border,
                              width: 2),
                            color: _gender == g.$1 ? AppColors.blueLight : AppColors.bg,
                          ),
                          child: Text(g.$2,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: _gender == g.$1 ? AppColors.blue : AppColors.fg2)),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Intereses
                  _SectionLabel('Le gusta…'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _interests.map((interest) {
                      final selected = _selectedInterests.contains(interest);
                      return GestureDetector(
                        onTap: () => setState(() {
                          selected ? _selectedInterests.remove(interest) : _selectedInterests.add(interest);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: selected ? AppColors.blue : AppColors.border, width: 2),
                            color: selected ? AppColors.blue : AppColors.white,
                          ),
                          child: Text(interest,
                              style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w500,
                                color: selected ? Colors.white : AppColors.fg2)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Notas
                  _SectionLabel('Notas'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Algo especial sobre ti…',
                      hintStyle: GoogleFonts.poppins(color: AppColors.fg3, fontSize: 13),
                      filled: true, fillColor: AppColors.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border, width: 2)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border, width: 2)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.blue, width: 2)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Botón guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text('🎂 Guardar mi cumpleaños',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.fg2, letterSpacing: 0.06));
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.ctrl, required this.hint, required this.label, required this.max});
  final TextEditingController ctrl;
  final String hint, label;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      TextField(
        controller: ctrl,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: max >= 1000 ? 4 : 2,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint, counterText: '',
          hintStyle: GoogleFonts.poppins(color: AppColors.fg3),
          filled: true, fillColor: AppColors.bg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 2)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 2)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.blue, width: 2)),
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: GoogleFonts.poppins(fontSize: 10, color: AppColors.fg3, fontWeight: FontWeight.w500)),
    ]);
  }
}
