import 'package:ccc_ojt_schedule/components/login/grid_painter.dart';
import 'package:ccc_ojt_schedule/components/super_admin/change_password.dart';
import 'package:ccc_ojt_schedule/components/super_admin/change_profile.dart';
import 'package:ccc_ojt_schedule/components/super_admin/create_key.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/super_admin/sa_backup_panel.dart';
import 'package:ccc_ojt_schedule/components/super_admin/shared_widgets.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ccc_ojt_schedule/components/super_admin/sa_offices_panel.dart';
import 'package:ccc_ojt_schedule/components/super_admin/sa_keys_panel.dart';
import 'package:ccc_ojt_schedule/components/super_admin/sa_dashboard_panel.dart';
import 'package:ccc_ojt_schedule/components/super_admin/sa_logs_panel.dart';

// ─── Nav item model ────────────────────────────────────────────────────────────
class _SANavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  const _SANavItem({required this.icon, required this.activeIcon, required this.label, required this.index});
}

const _navItems = [
  _SANavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', index: 0),
  _SANavItem(icon: Icons.business_outlined, activeIcon: Icons.business_rounded, label: 'Offices', index: 1),
  _SANavItem(icon: Icons.backup_outlined, activeIcon: Icons.backup_rounded, label: 'Backups', index: 2),
  _SANavItem(icon: Icons.vpn_key_outlined, activeIcon: Icons.vpn_key_rounded, label: 'Keys', index: 3),
  _SANavItem(icon: Icons.history_outlined, activeIcon: Icons.history_rounded, label: 'Logs', index: 4),
];

// ─── Main page ─────────────────────────────────────────────────────────────────
class SuperAdminPage extends StatefulWidget {
  final VoidCallback onLogout;
  const SuperAdminPage({super.key, required this.onLogout});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  final LoginStore _loginStore = LoginStore();
  int _currentIndex = 0;

  List<Map<String, dynamic>> offices = [];
  List<Map<String, dynamic>> keys = [];
  bool loadingOffices = true;
  bool loadingKeys = true;

  @override
  void initState() {
    super.initState();
    _loadOffices();
    _loadKeys();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadOffices() async {
    if (!mounted) return;
    setState(() => loadingOffices = true);
    try {
      final r = await RequestHandler().handleRequest('super-admin/offices', method: 'GET');
      if (r['success'] == true && mounted) {
        setState(() => offices = List<Map<String, dynamic>>.from(r['offices']));
      } else if (mounted) {
        AppSnackBar.error(context, r['message'] ?? 'Failed to load offices.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Network error: $e');
    } finally {
      if (mounted) setState(() => loadingOffices = false);
    }
  }

  Future<void> _loadKeys() async {
    if (!mounted) return;
    setState(() => loadingKeys = true);
    try {
      final r = await RequestHandler().handleRequest('super-admin/special-keys', method: 'GET');
      if (r['success'] == true && mounted) {
        setState(() => keys = List<Map<String, dynamic>>.from(r['keys']));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => loadingKeys = false);
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showCreateKey() =>
      showDialog(context: context, builder: (_) => const CreateSpecialKeyDialog()).then((_) => _loadKeys());

  void _showChangeProfile() => showDialog(context: context, builder: (_) => const ChangeProfileDialog());

  void _showChangePassword() => showDialog(context: context, builder: (_) => const ChangePasswordDialog());

  Future<void> _logout() async {
    final ok = await showSAConfirmDialog(
      context,
      title: 'Logout?',
      message: 'You will be signed out of the Super Admin panel.',
      confirmLabel: 'Logout',
      isDanger: true,
    );
    if (ok == true) widget.onLogout();
  }

  // ── Pages ─────────────────────────────────────────────────────────────────
  List<Widget> get _pages => [
    SADashboardPanel(offices: offices),
    SAOfficesPanel(offices: offices, loading: loadingOffices, onRefresh: _loadOffices, onOfficesChanged: _loadOffices),
    SABackupPanel(offices: offices),
    SAKeysPanel(keys: keys, loading: loadingKeys, onRefresh: _loadKeys),
    const SALogsPanel(),
  ];

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(backgroundColor: saNavy, body: isLandscape ? _buildLandscape() : _buildMobile());
  }

  // ── Landscape: left rail + content ───────────────────────────────────────

  Widget _buildLandscape() {
    final admin = _loginStore.superAdmin.value;
    return Row(
      children: [
        _SARailNav(
          admin: admin,
          currentIndex: _currentIndex,
          onItemTapped: (i) => setState(() => _currentIndex = i),
          onCreateKey: _showCreateKey,
          onChangeProfile: _showChangeProfile,
          onChangePassword: _showChangePassword,
          onLogout: _logout,
        ),
        Expanded(
          child: Column(
            children: [
              _SATopBar(pageLabel: _navItems[_currentIndex].label, admin: admin),
              Expanded(child: _pages[_currentIndex]),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile: appbar + bottom nav ───────────────────────────────────────────

  Widget _buildMobile() {
    final admin = _loginStore.superAdmin.value;
    return Scaffold(
      backgroundColor: saNavy,
      appBar: _SAMobileAppBar(
        admin: admin,
        onCreateKey: _showCreateKey,
        onChangeProfile: _showChangeProfile,
        onChangePassword: _showChangePassword,
        onLogout: _logout,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: _SABottomNav(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
    );
  }
}

// ─── Left Rail Navigation ──────────────────────────────────────────────────────
class _SARailNav extends StatelessWidget {
  final Map<String, dynamic> admin;
  final int currentIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback onCreateKey;
  final VoidCallback onChangeProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  const _SARailNav({
    required this.admin,
    required this.currentIndex,
    required this.onItemTapped,
    required this.onCreateKey,
    required this.onChangeProfile,
    required this.onChangePassword,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF080C14),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
      ),
      child: Stack(
        children: [
          // Grid background
          Positioned.fill(
            child: CustomPaint(painter: const GridPainter(brightness: Brightness.dark)),
          ),
          // Purple blob top-right
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFFA78BFA).withOpacity(0.10), Colors.transparent]),
              ),
            ),
          ),
          // Blue blob bottom-left
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF60A5FA).withOpacity(0.08), Colors.transparent]),
              ),
            ),
          ),

          Column(
            children: [
              // Header
              _buildHeader(),
              // Nav items
              Expanded(child: _buildNavItems()),
              // Footer actions
              _buildFooter(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset('assets/icon.png', fit: BoxFit.fill),
            ),
          ),
          Text(
            'SUPER ADMIN',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            admin['username'] ?? '',
            style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.40), fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Admin badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: saGreenDk.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: saGreenDk.withOpacity(0.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: saGreen),
                ),
                const SizedBox(width: 6),
                Text(
                  'Active Session',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: saGreen,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NAVIGATION',
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.28),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ..._navItems.map(
            (item) => _NavItem(item: item, isActive: currentIndex == item.index, onTap: () => onItemTapped(item.index)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            _footerBtn(icon: Icons.vpn_key_rounded, label: 'Create Key', color: saGreen, onTap: onCreateKey),
            const SizedBox(height: 6),
            _footerBtn(
              icon: Icons.manage_accounts_rounded,
              label: 'Edit Profile',
              color: saBlue,
              onTap: onChangeProfile,
            ),
            const SizedBox(height: 6),
            _footerBtn(
              icon: Icons.password_outlined,
              label: 'Password',
              color: const Color(0xFFA78BFA),
              onTap: onChangePassword,
            ),
            const SizedBox(height: 6),
            // Logout
            GestureDetector(
              onTap: onLogout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 16, color: Colors.red[400]),
                    const SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.red[400]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.20)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color.withOpacity(0.85)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: color.withOpacity(0.85)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _SANavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: 17,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.40),
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.40),
                ),
              ),
              if (isActive) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: saBlue),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Desktop Top Bar ───────────────────────────────────────────────────────────
class _SATopBar extends StatelessWidget {
  final String pageLabel;
  final Map<String, dynamic> admin;

  const _SATopBar({required this.pageLabel, required this.admin});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: saSurface,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Row(
        children: [
          Text(
            pageLabel,
            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const Spacer(),
          // Username chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings_rounded, size: 12, color: saBlue.withOpacity(0.80)),
                const SizedBox(width: 6),
                Text(
                  admin['username'] ?? '',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.70),
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

// ─── Mobile AppBar ─────────────────────────────────────────────────────────────
class _SAMobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Map<String, dynamic> admin;
  final VoidCallback onCreateKey;
  final VoidCallback onChangeProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  const _SAMobileAppBar({
    required this.admin,
    required this.onCreateKey,
    required this.onChangeProfile,
    required this.onChangePassword,
    required this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF080C14), Color(0xFF0F1E3C), Color(0xFF1B3769)],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: const GridPainter(brightness: Brightness.dark)),
          ),
        ],
      ),
      title: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Opacity(opacity: 0.8, child: Image.asset('assets/icon.png', fit: BoxFit.fill)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Super Admin',
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                admin['username'] ?? '',
                style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.50), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.vpn_key_rounded, color: saGreen, size: 18),
          onPressed: onCreateKey,
          style: IconButton.styleFrom(
            backgroundColor: saGreenDk.withOpacity(0.15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
          onPressed: onLogout,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ─── Mobile Bottom Nav ─────────────────────────────────────────────────────────
class _SABottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SABottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: saSurface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems
                .map(
                  (item) =>
                      _BottomNavItem(item: item, isActive: currentIndex == item.index, onTap: () => onTap(item.index)),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final _SANavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? saBlue : Colors.white.withOpacity(0.35),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? saBlue : Colors.white.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
