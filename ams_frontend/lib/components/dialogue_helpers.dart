import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget closeBtn(BuildContext context, bool isDark) {
  return GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceTint(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeManager.border(context)),
      ),
      child: Icon(Icons.close_rounded, size: 15, color: ThemeManager.secondary(context)),
    ),
  );
}

Widget cancelBtn(BuildContext context, bool isDark, {VoidCallback? onTap}) {
  return OutlinedButton(
    onPressed: onTap ?? () => Navigator.pop(context),
    style: OutlinedButton.styleFrom(
      foregroundColor: ThemeManager.secondary(context),
      side: BorderSide(color: ThemeManager.border(context)),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
  );
}

Widget card(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required Widget child,
}) {
  final isDark = ThemeManager.isDark(context);
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: ThemeManager.surface(context),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ThemeManager.border(context)),
      boxShadow: isDark
          ? null
          : [BoxShadow(color: const Color(0xFF1B3769).withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(isDark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 15),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ThemeManager.primary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(color: ThemeManager.dividerColor(context), height: 1),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}
