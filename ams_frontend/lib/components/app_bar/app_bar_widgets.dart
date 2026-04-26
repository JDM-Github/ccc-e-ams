import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Nav Item Model
// ─────────────────────────────────────────────────────────────────────────────

class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const AppNavItem({required this.icon, required this.activeIcon, required this.label, required this.index});
}

// ─────────────────────────────────────────────────────────────────────────────
// SY Dropdown
// ─────────────────────────────────────────────────────────────────────────────
class SYDropdown extends StatelessWidget {
  final bool dark;
  final bool isViewingCurrentSY;
  final String selectedSYLabel;
  final List<int> syIterations;
  final int currentIteration;
  final int changeableIteration;
  final int currentSY;
  final ValueChanged<int> onChanged;

  const SYDropdown({
    super.key,
    required this.dark,
    required this.isViewingCurrentSY,
    required this.selectedSYLabel,
    required this.syIterations,
    required this.currentIteration,
    required this.changeableIteration,
    required this.currentSY,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = dark ? Colors.white.withOpacity(0.08) : const Color(0xFFF1F5F9);
    final borderColor = dark ? Colors.white.withOpacity(0.15) : const Color(0xFFE2E8F0);
    final textColor = dark ? Colors.white.withOpacity(0.85) : const Color(0xFF374151);
    final iconColor = dark ? Colors.white.withOpacity(0.6) : const Color(0xFF64748B);
    final accentColor = isViewingCurrentSY
        ? (dark ? const Color(0xFF60A5FA) : const Color(0xFF0F1E3C))
        : const Color(0xFFD97706);

    return PopupMenuButton<int>(
      onSelected: onChanged,
      offset: const Offset(0, 36),
      color: const Color(0xFF0F1E3C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      itemBuilder: (context) => syIterations.reversed.map((iteration) {
        final isLive = iteration == currentIteration;
        final isSelected = iteration == changeableIteration;
        final sy = currentSY + iteration - 1;
        final label = 'AY $sy-${sy + 1}';

        return PopupMenuItem<int>(
          value: iteration,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF60A5FA) : Colors.white.withOpacity(0.15),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.55),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isLive ? const Color(0xFF22C55E).withOpacity(0.15) : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isLive ? 'ACTIVE' : 'PAST',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isLive ? const Color(0xFF22C55E) : Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isViewingCurrentSY ? borderColor : accentColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 12, color: accentColor),
            const SizedBox(width: 5),
            Text(
              'AY $selectedSYLabel',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isViewingCurrentSY ? textColor : accentColor,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_drop_down_rounded, size: 14, color: iconColor),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Static SY Badge  (non-supervisor users)
// ─────────────────────────────────────────────────────────────────────────────

class StaticSYBadge extends StatelessWidget {
  final int userSY;

  const StaticSYBadge({super.key, required this.userSY});

  @override
  Widget build(BuildContext context) {
    final label = '$userSY-${userSY + 1}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 12, color: Colors.white.withOpacity(0.6)),
          const SizedBox(width: 5),
          Text(
            'AY $label',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Avatar
// ─────────────────────────────────────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  final String? profileLink;
  final String firstName;
  final double size;
  final double radius;

  const UserAvatar({super.key, required this.profileLink, required this.firstName, this.size = 34, this.radius = 10});

  @override
  Widget build(BuildContext context) {
    if (profileLink != null && profileLink!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          profileLink!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        ),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B3769), Color(0xFF2D5299)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Text(
          firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.44),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill Badge  (target hours, office name, etc.)
// ─────────────────────────────────────────────────────────────────────────────

class TopBarPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? bgColor;
  final Color? borderColor;
  final Color? iconColor;
  final Color? labelColor;

  const TopBarPill({
    super.key,
    required this.icon,
    required this.label,
    this.bgColor,
    this.borderColor,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor ?? const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: labelColor ?? const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
