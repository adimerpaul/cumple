import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../core/services/auth_service.dart';
import '../core/services/api_service.dart';
import '../core/database/database_helper.dart';
import '../models/birthday.dart';
import '../models/user_session.dart';
import '../main.dart' show handleUnauthorized;

class HomeScreen extends StatefulWidget {
  final UserSession session;
  const HomeScreen({super.key, required this.session});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _homeReloadKey = 0;

  void _onApiError(Object e) {
    if (e is ApiException && e.isUnauthorized) {
      handleUnauthorized();
    }
  }

  Future<void> _openAddBirthdayForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBirthdaySheet(session: widget.session, onApiError: _onApiError),
    );

    if (created == true && mounted) {
      setState(() {
        _tab = 0;
        _homeReloadKey++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _tab,
        children: [
          _HomeTab(
            key: ValueKey(_homeReloadKey),
            session: widget.session,
            onApiError: _onApiError,
          ),
          _CalendarTab(),
          _StatsTab(),
          _ProfileTab(session: widget.session, onApiError: _onApiError),
        ],
      ),
      bottomNavigationBar: _BottomNav(current: _tab, onTap: (i) => setState(() => _tab = i)),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddBirthdayForm,
        backgroundColor: AppColors.blue,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ── Bottom Navigation ────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onTap});
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.white,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.06),
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _NavItem(icon: Icons.home_rounded, label: 'Inicio', active: current == 0, onTap: () => onTap(0)),
            _NavItem(icon: Icons.calendar_month_rounded, label: 'Calendario', active: current == 1, onTap: () => onTap(1)),
            const SizedBox(width: 64),
            _NavItem(icon: Icons.bar_chart_rounded, label: 'Stats', active: current == 2, onTap: () => onTap(2)),
            _NavItem(icon: Icons.person_rounded, label: 'Perfil', active: current == 3, onTap: () => onTap(3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? AppColors.blue : AppColors.fg3, size: 22),
            const SizedBox(height: 3),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: active ? AppColors.blue : AppColors.fg3)),
          ],
        ),
      ),
    );
  }
}

// ── Home Tab ─────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab({super.key, required this.session, required this.onApiError});
  final UserSession session;
  final void Function(Object) onApiError;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<Birthday> _birthdays = [];
  List<Birthday> _filtered = [];
  String _search = '';
  String _activeTab = 'upcoming';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await DatabaseHelper.instance.getAllBirthdays(
        ownerUserId: widget.session.laravelUserId,
      );
      if (mounted) setState(() { _birthdays = list; _applyFilter(); _loading = false; });
    } catch (e) {
      widget.onApiError(e);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    final all = _birthdays.where((b) => b.name.toLowerCase().contains(q)).toList()
      ..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    final now = DateTime.now();
    setState(() {
      _filtered = switch (_activeTab) {
        'upcoming' => all.where((b) => b.daysUntil <= 30).toList(),
        'month' => all.where((b) => b.birthMonth == now.month).toList(),
        _ => all,
      };
    });
  }

  Future<void> _editBirthday(Birthday birthday) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBirthdaySheet(
        session: widget.session,
        onApiError: widget.onApiError,
        initialBirthday: birthday,
      ),
    );
    if (updated == true) {
      _load();
    }
  }

  Future<void> _deleteBirthday(Birthday birthday) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar cumpleaños', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('¿Seguro que deseas eliminar a ${birthday.name}?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: AppColors.fg2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (ok != true || birthday.id == null) return;

    try {
      if (birthday.backendBirthdayId != null) {
        await ApiService.instance.deleteBirthday(
          token: widget.session.laravelToken,
          birthdayId: birthday.backendBirthdayId!,
        );
      }

      await DatabaseHelper.instance.deleteBirthday(
        birthday.id!,
        ownerUserId: widget.session.laravelUserId,
      );
      _load();
    } on ApiException catch (e) {
      widget.onApiError(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el cumpleaños')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _birthdays.where((b) => b.daysUntil <= 30).length;
    final thisMonth = _birthdays.where((b) => b.birthMonth == DateTime.now().month).length;
    final next = _birthdays.isEmpty ? null
        : ([..._birthdays]..sort((a, b) => a.daysUntil.compareTo(b.daysUntil))).first;

    return Column(
      children: [
        // Header azul
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppColors.blueDark, AppColors.blue],
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_todayLabel(),
                          style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.65), fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('Cumpleaños',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  _UserAvatar(session: widget.session, size: 36),
                ],
              ),
              if (next != null) ...[const SizedBox(height: 16), _NextBirthdayBanner(birthday: next)],
            ],
          ),
        ),

        // Búsqueda + tabs
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bg, borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: TextField(
                  onChanged: (v) { _search = v; _applyFilter(); },
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar…',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.fg3),
                    prefixIcon: const Icon(Icons.search, color: AppColors.fg3, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _TabBtn(label: 'Próximos ($upcoming)', active: _activeTab == 'upcoming',
                        onTap: () { _activeTab = 'upcoming'; _applyFilter(); }),
                    _TabBtn(label: 'Mes ($thisMonth)', active: _activeTab == 'month',
                        onTap: () { _activeTab = 'month'; _applyFilter(); }),
                    _TabBtn(label: 'Todos (${_birthdays.length})', active: _activeTab == 'all',
                        onTap: () { _activeTab = 'all'; _applyFilter(); }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lista
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
              : _filtered.isEmpty
                  ? _EmptyState(search: _search, tab: _activeTab)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _BirthdayCard(
                        birthday: _filtered[i],
                        onEdit: () => _editBirthday(_filtered[i]),
                        onDelete: () => _deleteBirthday(_filtered[i]),
                        showActions: _activeTab == 'all',
                      ),
                    ),
        ),
      ],
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const dias = ['domingo','lunes','martes','miércoles','jueves','viernes','sábado'];
    const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${dias[now.weekday % 7]}, ${now.day} ${meses[now.month - 1]}';
  }
}

const _addBirthdayInterests = [
  'Gaming',
  'Música',
  'Lectura',
  'Deporte',
  'Gastronomía',
  'Arte',
  'Viajes',
  'Cine',
  'Animales',
  'Naturaleza',
  'Tecnología',
  'Fotografía',
  'Puzzles',
  'Vinos',
  'Juegos',
  'Moda',
];

class _AddBirthdaySheet extends StatefulWidget {
  const _AddBirthdaySheet({
    required this.session,
    required this.onApiError,
    this.initialBirthday,
  });
  final UserSession session;
  final void Function(Object) onApiError;
  final Birthday? initialBirthday;

  @override
  State<_AddBirthdaySheet> createState() => _AddBirthdaySheetState();
}

class _AddBirthdaySheetState extends State<_AddBirthdaySheet> {
  final _nameCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _gender;
  final Set<String> _selectedInterests = {};
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.initialBirthday != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialBirthday;
    if (initial == null) return;
    _nameCtrl.text = initial.name;
    _dayCtrl.text = initial.birthDay.toString();
    _monthCtrl.text = initial.birthMonth.toString();
    _yearCtrl.text = initial.birthYear?.toString() ?? '';
    _notesCtrl.text = initial.notes ?? '';
    _gender = initial.gender;
    _selectedInterests.addAll(initial.interestsList);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final day = int.tryParse(_dayCtrl.text.trim());
    final month = int.tryParse(_monthCtrl.text.trim());
    final year = _yearCtrl.text.trim().isEmpty ? null : int.tryParse(_yearCtrl.text.trim());
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'El nombre es obligatorio');
      return;
    }

    if (day == null || month == null || day < 1 || day > 31 || month < 1 || month > 12) {
      setState(() => _error = 'Ingresa un día y mes válidos');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final interests = _selectedInterests.isEmpty ? null : _selectedInterests.join('||');

      if (_isEdit) {
        final current = widget.initialBirthday!;
        if (current.backendBirthdayId != null) {
          await ApiService.instance.updateBirthday(
            token: widget.session.laravelToken,
            birthdayId: current.backendBirthdayId!,
            name: name,
            birthDay: day,
            birthMonth: month,
            birthYear: year,
            gender: _gender,
            interests: interests,
            notes: notes,
          );
        }

        if (current.id != null) {
          await DatabaseHelper.instance.updateBirthday(
            Birthday(
              id: current.id,
              backendBirthdayId: current.backendBirthdayId,
              name: name,
              birthDay: day,
              birthMonth: month,
              birthYear: year,
              gender: _gender,
              interests: interests,
              notes: notes,
              isSelf: current.isSelf,
              notifyDaysBefore: current.notifyDaysBefore,
              createdAt: current.createdAt,
            ),
            ownerUserId: widget.session.laravelUserId,
          );
        }
      } else {
        final data = await ApiService.instance.createBirthday(
          token: widget.session.laravelToken,
          name: name,
          birthDay: day,
          birthMonth: month,
          birthYear: year,
          gender: _gender,
          interests: interests,
          notes: notes,
        );

        final backendBirthday = data['birthday'] as Map<String, dynamic>?;
        final backendBirthdayId = backendBirthday?['id'] as int?;

        await DatabaseHelper.instance.insertBirthday(
          Birthday(
            backendBirthdayId: backendBirthdayId,
            name: name,
            birthDay: day,
            birthMonth: month,
            birthYear: year,
            gender: _gender,
            interests: interests,
            notes: notes,
            createdAt: DateTime.now().toIso8601String(),
          ),
          ownerUserId: widget.session.laravelUserId,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        widget.onApiError(e);
        if (mounted) Navigator.pop(context, false);
        return;
      }
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isEdit ? 'Editar cumpleaños' : 'Nuevo cumpleaños',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.fg,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close_rounded, color: AppColors.fg3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      Text(
                        'NOMBRE COMPLETO *',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.fg2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.fg),
                        decoration: InputDecoration(
                          hintText: 'Ej. Ana Rodríguez',
                          hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.fg3),
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.blue, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'GÉNERO',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.fg2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _GenderPill(
                            label: 'Hombre',
                            icon: Icons.male_rounded,
                            selected: _gender == 'hombre',
                            onTap: () => setState(() => _gender = _gender == 'hombre' ? null : 'hombre'),
                          ),
                          const SizedBox(width: 8),
                          _GenderPill(
                            label: 'Mujer',
                            icon: Icons.female_rounded,
                            selected: _gender == 'mujer',
                            onTap: () => setState(() => _gender = _gender == 'mujer' ? null : 'mujer'),
                          ),
                          const SizedBox(width: 8),
                          _GenderPill(
                            label: 'Otro',
                            icon: Icons.diversity_3_rounded,
                            selected: _gender == 'otro',
                            onTap: () => setState(() => _gender = _gender == 'otro' ? null : 'otro'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'FECHA DE CUMPLEAÑOS *',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.fg2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _DateField(ctrl: _dayCtrl, hint: 'DD', label: 'Día', maxLength: 2),
                          const SizedBox(width: 8),
                          _DateField(ctrl: _monthCtrl, hint: 'MM', label: 'Mes', maxLength: 2),
                          const SizedBox(width: 8),
                          _DateField(ctrl: _yearCtrl, hint: 'AAAA', label: 'Año (opcional)', maxLength: 4, flex: 2),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'LE GUSTA...',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.fg2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _addBirthdayInterests.map((interest) {
                          final selected = _selectedInterests.contains(interest);
                          return _InterestChip(
                            label: interest,
                            selected: selected,
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selectedInterests.remove(interest);
                                } else {
                                  _selectedInterests.add(interest);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'NOTAS',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.fg2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesCtrl,
                        minLines: 2,
                        maxLines: 4,
                        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.fg),
                        decoration: InputDecoration(
                          hintText: 'Ideas de regalo, datos especiales...',
                          hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.fg3),
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.blue, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _save,
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cake_rounded, color: Colors.white, size: 18),
                          label: Text(
                            _loading
                                ? (_isEdit ? 'Guardando...' : 'Registrando...')
                                : (_isEdit ? 'Guardar cambios' : 'Registrar'),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderPill extends StatelessWidget {
  const _GenderPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.blueLight : AppColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.border,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? AppColors.blue : AppColors.fg2),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.blue : AppColors.fg2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.ctrl,
    required this.hint,
    required this.label,
    required this.maxLength,
    this.flex = 1,
  });

  final TextEditingController ctrl;
  final String hint;
  final String label;
  final int maxLength;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: maxLength,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.fg),
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: GoogleFonts.poppins(fontSize: 15, color: AppColors.fg3),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.blue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.fg3,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueLight : AppColors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.blue : AppColors.border,
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.blue : AppColors.fg2,
          ),
        ),
      ),
    );
  }
}

// ── User Avatar (base64 o ícono) ─────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.session, this.size = 36});
  final UserSession session;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (session.photoB64 != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: MemoryImage(base64Decode(session.photoB64!)),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.white.withOpacity(0.2),
      child: Text(
        session.name.isNotEmpty ? session.name[0].toUpperCase() : 'U',
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.4),
      ),
    );
  }
}

// ── Tab widgets ───────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)] : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: active ? AppColors.blue : AppColors.fg3)),
        ),
      ),
    );
  }
}

class _NextBirthdayBanner extends StatelessWidget {
  const _NextBirthdayBanner({required this.birthday});
  final Birthday birthday;

  @override
  Widget build(BuildContext context) {
    final days = birthday.daysUntil;
    final isToday = days == 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _BirthdayAvatar(birthday: birthday, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isToday ? '¡Hoy!' : 'Próximo',
                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
              Text(isToday ? '¡Feliz cumpleaños, ${birthday.name.split(' ').first}!' : birthday.name.split(' ').first,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              if (!isToday)
                Text('En $days día${days == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Text(isToday ? '🎉' : '$days',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
              Text(isToday ? '¡HOY!' : 'días',
                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard({
    required this.birthday,
    required this.onEdit,
    required this.onDelete,
    this.showActions = true,
  });
  final Birthday birthday;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final days = birthday.daysUntil;
    final isToday = days == 0;
    final isSoon = days <= 7 && !isToday;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: isToday ? AppColors.blue.withOpacity(0.2) : Colors.black.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (isToday)
            Container(height: 3, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.blue, Color(0xFF60A5FA)]))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                _BirthdayAvatar(birthday: birthday, size: 48),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(birthday.name, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.fg)),
                  Text(_formatDate(birthday),
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.fg2)),
                ])),
                if (showActions) ...[
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.fg3, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                ] else
                  const SizedBox(width: 12),
                _CountdownPill(days: days, isToday: isToday, isSoon: isSoon),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Birthday b) {
    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final base = '${b.birthDay} ${meses[b.birthMonth - 1]}';
    return b.birthYear != null ? '$base ${b.birthYear}' : base;
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.days, required this.isToday, required this.isSoon});
  final int days;
  final bool isToday, isSoon;

  @override
  Widget build(BuildContext context) {
    final bg = isToday ? AppColors.blue : isSoon ? const Color(0xFFFEF3C7) : AppColors.blueLight;
    final tc = isToday ? Colors.white : isSoon ? const Color(0xFFD97706) : AppColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(isToday ? '🎂' : '$days',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: tc, height: 1)),
        Text(isToday ? '¡hoy!' : days == 1 ? 'día' : 'días',
            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: tc)),
      ]),
    );
  }
}

class _BirthdayAvatar extends StatelessWidget {
  const _BirthdayAvatar({required this.birthday, this.size = 48});
  final Birthday birthday;
  final double size;

  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0xFF2563FF), Color(0xFF60A5FA)],
      [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      [Color(0xFF059669), Color(0xFF34D399)],
      [Color(0xFFDC2626), Color(0xFFF87171)],
      [Color(0xFFD97706), Color(0xFFFCD34D)],
      [Color(0xFF0891B2), Color(0xFF67E8F9)],
    ];
    final code = birthday.name.codeUnitAt(0) * 41 + (birthday.name.length > 1 ? birthday.name.codeUnitAt(1) : 0) * 17;
    final pair = palettes[code % palettes.length];
    final initials = birthday.name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: pair)),
      child: Center(child: Text(initials,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: size * 0.36, fontWeight: FontWeight.w700))),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.search, required this.tab});
  final String search, tab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎈', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            search.isNotEmpty ? 'Sin resultados' : tab == 'month' ? 'Nadie cumple este mes' : 'Sin cumpleaños aún',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.fg)),
          if (search.isEmpty) ...[
            const SizedBox(height: 6),
            Text('¡Registra el primero con el botón +!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.fg3)),
          ],
        ]),
      ),
    );
  }
}

// ── Placeholder tabs ─────────────────────────────────────────

class _CalendarTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(children: [
    _BlueHeader(title: 'Calendario'),
    const Expanded(child: Center(child: Text('📅  Próximamente', style: TextStyle(fontSize: 18)))),
  ]);
}

class _StatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(children: [
    _BlueHeader(title: 'Estadísticas'),
    const Expanded(child: Center(child: Text('📊  Próximamente', style: TextStyle(fontSize: 18)))),
  ]);
}

// ── Profile Tab ────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.session, required this.onApiError});
  final UserSession session;
  final void Function(Object) onApiError;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppColors.blueDark, AppColors.blue],
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mi Perfil',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(children: [
              _UserAvatar(session: session, size: 64),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(session.name,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                Text(session.email,
                    style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              ])),
            ]),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text('Cerrar sesión',
                      style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFFEE2E2), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cerrar sesión', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('¿Seguro que quieres salir?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: AppColors.fg2))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text('Salir', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (ok == true) {
      await AuthService.instance.signOut(session.laravelToken);
      handleUnauthorized();
    }
  }
}

class _BlueHeader extends StatelessWidget {
  const _BlueHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.blueDark, AppColors.blue],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
      child: Text(title,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
    );
  }
}
