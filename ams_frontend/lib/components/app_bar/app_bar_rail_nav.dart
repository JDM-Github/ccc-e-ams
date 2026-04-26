import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ccc_ojt_schedule/components/login/grid_painter.dart';
import 'app_bar_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppRailNav  —  Left sidebar for landscape / desktop layout
// ─────────────────────────────────────────────────────────────────────────────

class AppRailNav extends StatelessWidget {
  final List<AppNavItem> items;
  final int currentIndex;
  final String officeName;
  final bool isSupervisorOrAdmin;
  final bool canAdvanceSY;

  // SY props
  final bool isViewingCurrentSY;
  final String selectedSYLabel;
  final List<int> syIterations;
  final int currentIteration;
  final int changeableIteration;
  final int currentSY;
  final int userSY;

  final ValueChanged<int> onItemTapped;
  final ValueChanged<int> onSYChanged;
  final VoidCallback onAdvanceSY;
  final VoidCallback onLogout;

  const AppRailNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.officeName,
    required this.isSupervisorOrAdmin,
    required this.canAdvanceSY,
    required this.isViewingCurrentSY,
    required this.selectedSYLabel,
    required this.syIterations,
    required this.currentIteration,
    required this.changeableIteration,
    required this.currentSY,
    required this.userSY,
    required this.onItemTapped,
    required this.onSYChanged,
    required this.onAdvanceSY,
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
          Positioned.fill(
            child: CustomPaint(painter: const GridPainter(brightness: Brightness.dark)),
          ),
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

          // Bottom-left accent blob
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

          // Content column
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildNavItems()),
              _buildFooter(context),
            ],
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          SizedBox(
            width: 120,
            height: 120,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset('assets/icon.png', fit: BoxFit.fill),
            ),
          ),

          // School name
          Text(
            'CITY COLLEGE OF CALAMBA',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$officeName Scheduling',
            style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withOpacity(0.40), fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // SY badge / dropdown
          isSupervisorOrAdmin
              ? SYDropdown(
                  dark: true,
                  isViewingCurrentSY: isViewingCurrentSY,
                  selectedSYLabel: selectedSYLabel,
                  syIterations: syIterations,
                  currentIteration: currentIteration,
                  changeableIteration: changeableIteration,
                  currentSY: currentSY,
                  onChanged: onSYChanged,
                )
              : StaticSYBadge(userSY: userSY),
        ],
      ),
    );
  }

  // ── Nav items ────────────────────────────────────────────────
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
          ...items.map(
            (item) =>
                _RailItem(item: item, isActive: currentIndex == item.index, onTap: () => onItemTapped(item.index)),
          ),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────

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
            if (canAdvanceSY) ...[_AdvanceSYRailButton(onTap: onAdvanceSY), const SizedBox(height: 8)],
            _LogoutRailButton(onTap: onLogout),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RailItem
// ─────────────────────────────────────────────────────────────────────────────

class _RailItem extends StatelessWidget {
  final AppNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _RailItem({required this.item, required this.isActive, required this.onTap});

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
                size: 18,
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
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF60A5FA)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AdvanceSYRailButton
// ─────────────────────────────────────────────────────────────────────────────

class _AdvanceSYRailButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AdvanceSYRailButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFBBF24).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.arrow_circle_up_outlined, size: 18, color: const Color(0xFFFBBF24).withOpacity(0.85)),
            const SizedBox(width: 12),
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

// ─────────────────────────────────────────────────────────────────────────────
// _LogoutRailButton
// ─────────────────────────────────────────────────────────────────────────────

class _LogoutRailButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutRailButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withOpacity(0.20)),
        ),
        child: Row(
          children: [
            Icon(Icons.logout_rounded, size: 18, color: Colors.red[400]),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.red[400]),
            ),
          ],
        ),
      ),
    );
  }
}
