import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ccc_ojt_schedule/components/login/grid_painter.dart';
import 'package:ccc_ojt_schedule/context/theme_notifier.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'app_bar_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Top Bar  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class AppTopBar extends StatelessWidget {
  final String pageLabel;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffixName;
  final String extensionName;

  final String role;
  final String course;
  final String officeName;
  final String targetHours;
  final String? profileLink;
  final bool isSupervisor;
  final bool canAdvanceSY;
  final bool isAdvancing;

  // SY props
  final bool isSupervisorOrAdmin;
  final bool isViewingCurrentSY;
  final String selectedSYLabel;
  final List<int> syIterations;
  final int currentIteration;
  final int changeableIteration;
  final int currentSY;
  final int userSY;
  final bool isAdmin;

  final ValueChanged<int> onSYChanged;
  final VoidCallback onAdvanceSY;

  const AppTopBar({
    super.key,
    required this.pageLabel,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.suffixName,
    required this.extensionName,
    required this.role,
    required this.course,
    required this.officeName,
    required this.targetHours,
    required this.profileLink,
    required this.isSupervisor,
    required this.canAdvanceSY,
    required this.isAdvancing,
    required this.isSupervisorOrAdmin,
    required this.isViewingCurrentSY,
    required this.selectedSYLabel,
    required this.syIterations,
    required this.currentIteration,
    required this.changeableIteration,
    required this.currentSY,
    required this.userSY,
    required this.isAdmin,
    required this.onSYChanged,
    required this.onAdvanceSY,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDark = ThemeManager.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pageLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ThemeManager.primary(context),
                ),
              ),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(now),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: ThemeManager.muted(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          isSupervisorOrAdmin
              ? SYDropdown(
                  dark: isDark,
                  isViewingCurrentSY: isViewingCurrentSY,
                  selectedSYLabel: selectedSYLabel,
                  syIterations: syIterations,
                  currentIteration: currentIteration,
                  changeableIteration: changeableIteration,
                  currentSY: currentSY,
                  onChanged: onSYChanged,
                )
              : _StaticSYBadgeLight(userSY: userSY, isDark: isDark),
          const SizedBox(width: 8),
          if (role != 'supervisor') ...[
            _HoursPill(targetHours: targetHours, isDark: isDark),
            const SizedBox(width: 10),
          ],
          if (canAdvanceSY && !isAdvancing) ...[_AdvanceSYPill(onTap: onAdvanceSY), const SizedBox(width: 10)],
          _OfficePill(officeName: officeName, isDark: isDark),
          const SizedBox(width: 16),
          Container(width: 1, height: 32, color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
          const SizedBox(width: 16),
          const _ThemeToggleChip(),
          const SizedBox(width: 12),
          UserAvatar(profileLink: profileLink, firstName: firstName),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatFullName(firstName, middleName, lastName, suffixName, extensionName),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ThemeManager.primary(context),
                ),
              ),
              Text(
                role == 'supervisor'
                    ? (isAdmin ? 'Admin' : 'Supervisor')
                    : (course.length > 36 ? '${course.substring(0, 36)}…' : course),
                style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFullName(
    String firstName,
    String middleName,
    String lastName,
    String suffixName, [
    String? extensionName,
  ]) {
    String base;
    if (middleName.trim().isNotEmpty) {
      final middleInitials = middleName
          .trim()
          .split(RegExp(r'\s+'))
          .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
          .join('.');
      base = '$firstName $middleInitials. $lastName';
    } else {
      base = '$firstName $lastName';
    }
    final suffix = suffixName.trim();
    if (suffix.isNotEmpty) base = '$base, $suffix';
    final ext = extensionName?.trim();
    if (ext != null && ext.isNotEmpty) base = '$base, $ext';
    return base;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile AppBar  — restructured
//
// Layout:
//   leading  │  title col (school label + office row)  │  actions: [theme, logout]
//
// The SY selector (supervisor/admin), advance-SY button, and AY badge are
// moved into a slim sub-bar that sits BELOW the main AppBar via a Column +
// PreferredSize trick. This keeps actions lean (2 icons only) and surfaces
// the contextual controls in a dedicated row.
// ─────────────────────────────────────────────────────────────────────────────

class AppMobileBar extends StatelessWidget implements PreferredSizeWidget {
  final String officeName;
  final bool isSupervisorOrAdmin;
  final bool isSupervisor;
  final bool canAdvanceSY;

  final bool isViewingCurrentSY;
  final String selectedSYLabel;
  final List<int> syIterations;
  final int currentIteration;
  final int changeableIteration;
  final int currentSY;
  final int userSY;

  final ValueChanged<int> onSYChanged;
  final VoidCallback onAdvanceSY;
  final VoidCallback onLogout;

  const AppMobileBar({
    super.key,
    required this.officeName,
    required this.isSupervisorOrAdmin,
    required this.isSupervisor,
    required this.canAdvanceSY,
    required this.isViewingCurrentSY,
    required this.selectedSYLabel,
    required this.syIterations,
    required this.currentIteration,
    required this.changeableIteration,
    required this.currentSY,
    required this.userSY,
    required this.onSYChanged,
    required this.onAdvanceSY,
    required this.onLogout,
  });

  // 85 (56) + sub-bar height (36) when the sub-bar is shown
  bool get _hasSubBar => isSupervisorOrAdmin || canAdvanceSY || !isSupervisor;
  static const double _subBarHeight = 36.0;

  @override
  Size get preferredSize => Size.fromHeight(85 + (_hasSubBar ? _subBarHeight : 0));

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Main bar ────────────────────────────────────────────
        _buildMainBar(context),

        // ── Sub-bar (SY / AY / Advance) ─────────────────────────
        if (_hasSubBar) _buildSubBar(context),
      ],
    );
  }

  Widget _buildMainBar(BuildContext context) {
    return SizedBox(
      height: 85,
      child: AppBar(
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
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
          child: Image.asset('assets/icon.png', fit: BoxFit.contain, isAntiAlias: true),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CITY COLLEGE OF CALAMBA',
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.55),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              officeName,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        // Only 2 actions: theme toggle + logout
        actions: [
          const Padding(padding: EdgeInsets.only(right: 2), child: _ThemeToggleMobileButton()),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              tooltip: 'Logout',
              onPressed: onLogout,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubBar(BuildContext context) {
    // Same gradient as main bar, slightly darker tint at bottom
    return Container(
      height: _subBarHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF080C14).withOpacity(0.92),
            const Color(0xFF0F1E3C).withOpacity(0.92),
            const Color(0xFF1B3769).withOpacity(0.92),
          ],
        ),
        border: const Border(bottom: BorderSide(color: Color(0x22FFFFFF), width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            // AY badge for students
            if (!isSupervisor) ...[StaticSYBadge(userSY: userSY), const SizedBox(width: 8)],

            // SY dropdown for supervisor/admin
            if (isSupervisorOrAdmin) ...[
              SYDropdown(
                dark: true,
                isViewingCurrentSY: isViewingCurrentSY,
                selectedSYLabel: selectedSYLabel,
                syIterations: syIterations,
                currentIteration: currentIteration,
                changeableIteration: changeableIteration,
                currentSY: currentSY,
                onChanged: onSYChanged,
              ),
              const SizedBox(width: 8),
            ],

            // Advance SY button
            if (canAdvanceSY) ...[_AdvanceSYSubBarButton(onTap: onAdvanceSY)],

            const Spacer(),

            // Subtle date label on the right
            Text(
              DateFormat('MMM d, yyyy').format(DateTime.now()),
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: Colors.white.withOpacity(0.40),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact "Next AY" button styled for the dark sub-bar
class _AdvanceSYSubBarButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AdvanceSYSubBarButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFBBF24).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_circle_up_outlined, size: 12, color: Color(0xFFFBBF24)),
            const SizedBox(width: 5),
            Text(
              'Next AY',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFBBF24).withOpacity(0.90),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Bottom Navigation Bar  — horizontally scrollable
// ─────────────────────────────────────────────────────────────────────────────

class AppBottomNav extends StatelessWidget {
  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemTapped;

  const AppBottomNav({super.key, required this.items, required this.currentIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: isDark ? null : const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // Center content when items fit without scrolling
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding(context, items.length), vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: items
                .map(
                  (item) => _BottomNavItem(
                    item: item,
                    isActive: currentIndex == item.index,
                    onTap: () => onItemTapped(item.index),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  /// Returns padding so items appear centered when they all fit on screen,
  /// and collapses to a small edge gap when the user needs to scroll.
  double _horizontalPadding(BuildContext context, int count) {
    const itemWidth = 70.0; // approx width per nav item
    final screenWidth = MediaQuery.of(context).size.width;
    final totalItems = count * itemWidth;
    if (totalItems < screenWidth) {
      return (screenWidth - totalItems) / 2;
    }
    return 8.0;
  }
}

class _BottomNavItem extends StatelessWidget {
  final AppNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    final activeColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769);
    final inactiveColor = isDark ? Colors.white.withOpacity(0.35) : const Color(0xFF94A3B8);
    final activeBg = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFF1B3769).withOpacity(0.10);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? item.activeIcon : item.icon, color: isActive ? activeColor : inactiveColor, size: 22),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme Toggle — Desktop chip (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeToggleChip extends StatelessWidget {
  const _ThemeToggleChip();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeModeNotifier>();
    final dark = notifier.value == ThemeMode.dark;
    final isDark = ThemeManager.isDark(context);

    return Tooltip(
      message: dark ? 'Switch to light mode' : 'Switch to dark mode',
      child: GestureDetector(
        onTap: notifier.toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(ThemeManager.radiusBtn),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 14,
                color: ThemeManager.toggleIcon(context),
              ),
              const SizedBox(width: 5),
              Text(
                dark ? 'Light' : 'Dark',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ThemeManager.toggleIcon(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme Toggle — Mobile icon button (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeToggleMobileButton extends StatelessWidget {
  const _ThemeToggleMobileButton();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeModeNotifier>();
    final dark = notifier.value == ThemeMode.dark;

    return IconButton(
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: Colors.white, size: 20),
      onPressed: notifier.toggle,
      tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill widgets (desktop top bar)  — unchanged
// ─────────────────────────────────────────────────────────────────────────────

class _StaticSYBadgeLight extends StatelessWidget {
  final int userSY;
  final bool isDark;
  const _StaticSYBadgeLight({required this.userSY, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final label = '$userSY-${userSY + 1}';
    final bg = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFF1B3769).withOpacity(0.06);
    final border = isDark ? Colors.white.withOpacity(0.15) : const Color(0xFF1B3769).withOpacity(0.15);
    final color = isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1B3769);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            'AY $label',
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _HoursPill extends StatelessWidget {
  final String targetHours;
  final bool isDark;
  const _HoursPill({required this.targetHours, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1B3769).withOpacity(0.25) : const Color(0xFF1B3769).withOpacity(0.07);
    final color = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            '$targetHours hrs target',
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _AdvanceSYPill extends StatelessWidget {
  final VoidCallback onTap;
  const _AdvanceSYPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFBBF24).withOpacity(0.08),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFFBBF24)),
            const SizedBox(width: 8),
            Text(
              'Next AY',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFBBF24).withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficePill extends StatelessWidget {
  final String officeName;
  final bool isDark;
  const _OfficePill({required this.officeName, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF1F5F9);
    final border = isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFE2E8F0);
    final iconColor = isDark ? Colors.white.withOpacity(0.45) : const Color(0xFF64748B);
    final textColor = isDark ? Colors.white.withOpacity(0.75) : const Color(0xFF374151);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_outlined, size: 13, color: iconColor),
          const SizedBox(width: 6),
          Text(
            officeName,
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }
}
