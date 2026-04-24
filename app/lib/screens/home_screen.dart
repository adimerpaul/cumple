import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';
import '../core/services/auth_service.dart';
import '../core/database/database_helper.dart';
import '../models/birthday.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _tab,
        children: [
          _HomeTab(user: user),
          _CalendarTab(),
          _StatsTab(),
          _ProfileTab(user: user),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: abrir formulario de nuevo cumpleaños
        },
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
            const SizedBox(width: 64), // espacio FAB
            _NavItem(icon: Icons.notifications_rounded, label: 'Stats', active: current == 2, onTap: () => onTap(2)),
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
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.blue : AppColors.fg3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Home Tab ─────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab({required this.user});
  final User user;

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
    final list = await DatabaseHelper.instance.getAllBirthdays();
    if (mounted) {
      setState(() {
        _birthdays = list;
        _applyFilter();
        _loading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final upcoming = _birthdays.where((b) => b.daysUntil <= 30).length;
    final thisMonth = _birthdays.where((b) => b.birthMonth == DateTime.now().month).length;
    final next = _birthdays.isEmpty
        ? null
        : ([..._birthdays]..sort((a, b) => a.daysUntil.compareTo(b.daysUntil))).first;

    return Column(
      children: [
        // Header azul
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _todayLabel(),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cumpleaños',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: widget.user.photoURL != null
                        ? NetworkImage(widget.user.photoURL!)
                        : null,
                    child: widget.user.photoURL == null
                        ? const Icon(Icons.person, color: Colors.white, size: 20)
                        : null,
                  ),
                ],
              ),
              if (next != null) ...[
                const SizedBox(height: 16),
                _NextBirthdayBanner(birthday: next),
              ],
            ],
          ),
        ),

        // Barra de búsqueda + tabs
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            children: [
              // Search
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: TextField(
                  onChanged: (v) {
                    _search = v;
                    _applyFilter();
                  },
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
              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _TabBtn(label: 'Próximos ($upcoming)', id: 'upcoming', active: _activeTab == 'upcoming', onTap: () { _activeTab = 'upcoming'; _applyFilter(); }),
                    _TabBtn(label: 'Mes ($thisMonth)', id: 'month', active: _activeTab == 'month', onTap: () { _activeTab = 'month'; _applyFilter(); }),
                    _TabBtn(label: 'Todos (${_birthdays.length})', id: 'all', active: _activeTab == 'all', onTap: () { _activeTab = 'all'; _applyFilter(); }),
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
                      itemBuilder: (_, i) => _BirthdayCard(birthday: _filtered[i]),
                    ),
        ),
      ],
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const dias = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];
    const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dias[now.weekday % 7]}, ${now.day} ${meses[now.month - 1]}';
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.label, required this.id, required this.active, required this.onTap});
  final String label, id;
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
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.blue : AppColors.fg3,
            ),
          ),
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Avatar(birthday: birthday, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? '¡Hoy!' : 'Próximo',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                  ),
                ),
                Text(
                  isToday
                      ? '¡Feliz cumpleaños, ${birthday.name.split(' ').first}!'
                      : birthday.name.split(' ').first,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isToday)
                  Text(
                    'En $days día${days == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  isToday ? '🎉' : '$days',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  isToday ? '¡HOY!' : 'días',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard({required this.birthday});
  final Birthday birthday;

  @override
  Widget build(BuildContext context) {
    final days = birthday.daysUntil;
    final isToday = days == 0;
    final isSoon = days <= 7 && !isToday;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? AppColors.blue.withOpacity(0.2)
                : Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (isToday)
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.blue, Color(0xFF60A5FA)],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                _Avatar(birthday: birthday, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        birthday.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.fg,
                        ),
                      ),
                      Text(
                        _formatDate(birthday),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.fg2,
                        ),
                      ),
                    ],
                  ),
                ),
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
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
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
    Color bg, textColor;
    if (isToday) {
      bg = AppColors.blue;
      textColor = Colors.white;
    } else if (isSoon) {
      bg = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
    } else {
      bg = AppColors.blueLight;
      textColor = AppColors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            isToday ? '🎂' : '$days',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1,
            ),
          ),
          Text(
            isToday ? '¡hoy!' : days == 1 ? 'día' : 'días',
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.birthday, this.size = 48});
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
    final code = birthday.name.codeUnitAt(0) * 41 +
        (birthday.name.length > 1 ? birthday.name.codeUnitAt(1) : 0) * 17;
    final pair = palettes[code % palettes.length];
    final initials = birthday.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: pair,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.search, required this.tab});
  final String search;
  final String tab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎈', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              search.isNotEmpty
                  ? 'Sin resultados'
                  : tab == 'month'
                      ? 'Nadie cumple este mes'
                      : 'Sin cumpleaños aún',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.fg,
              ),
            ),
            const SizedBox(height: 6),
            if (search.isEmpty)
              Text(
                '¡Registra el primero con el botón +!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.fg3),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Calendar Tab (placeholder) ────────────────────────────────

class _CalendarTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BlueHeader(title: 'Calendario'),
        const Expanded(
          child: Center(child: Text('📅  Próximamente', style: TextStyle(fontSize: 18))),
        ),
      ],
    );
  }
}

// ── Stats Tab (placeholder) ────────────────────────────────

class _StatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BlueHeader(title: 'Estadísticas'),
        const Expanded(
          child: Center(child: Text('📊  Próximamente', style: TextStyle(fontSize: 18))),
        ),
      ],
    );
  }
}

// ── Profile Tab ────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header azul con datos del usuario
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.blueDark, AppColors.blue],
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi Perfil',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? const Icon(Icons.person, color: Colors.white, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'Usuario',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          user.email ?? '',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Botón cerrar sesión
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmSignOut(context),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      'Cerrar sesión',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFFEE2E2), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cerrar sesión', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('¿Seguro que quieres salir?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: AppColors.fg2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Salir', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) await AuthService.instance.signOut();
  }
}

// ── Shared header widget ─────────────────────────────────────

class _BlueHeader extends StatelessWidget {
  const _BlueHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blueDark, AppColors.blue],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
