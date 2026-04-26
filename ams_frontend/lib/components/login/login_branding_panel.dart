import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'grid_painter.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'login_widgets.dart';

class LoginBrandingPanel extends StatelessWidget {
  const LoginBrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080C14),
      child: Stack(
        children: [
          // Grid — always dark on this panel
          Positioned.fill(
            child: CustomPaint(painter: const GridPainter(brightness: Brightness.dark)),
          ),

          // Blob 1 — top-right, purple
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [ThemeManager.accentPurple.withOpacity(0.22), Colors.transparent]),
              ),
            ),
          ),

          // Blob 2 — bottom-left, blue
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [ThemeManager.accentBlue.withOpacity(0.18), Colors.transparent]),
              ),
            ),
          ),

          // Blob 3 — center-right, green
          Positioned(
            bottom: 80,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [ThemeManager.accentGreen.withOpacity(0.12), Colors.transparent]),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AccentBadge(text: 'ATTENDANCE MANAGEMENT SYSTEM', accent: ThemeManager.accentBlue),

                const Spacer(),

                // Logo
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Opacity(opacity: 0.85, child: Image.asset('assets/icon.png', fit: BoxFit.contain)),
                ),

                const SizedBox(height: 8),

                // Hero text — always white gradient on dark bg
                _GradientText(
                  'Track.\nManage.\nComplete.',
                  style: GoogleFonts.dmSans(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -1.5,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'The complete platform for managing\nyour OJT internship hours and schedules.',
                  style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0x80FFFFFF), height: 1.65),
                ),

                const SizedBox(height: 48),

                // Stats strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0x14162B4C),
                    borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                    border: Border.all(color: const Color(0x332D5299)),
                  ),
                  child: const Row(
                    children: [
                      BrandingStatCell(value: '100%', label: 'Tracking\naccuracy'),
                      BrandingStatCell(value: '24/7', label: 'Schedule\naccess'),
                      BrandingStatCell(value: '∞', label: 'OJT\nrecords', showDivider: false),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  '© ${DateTime.now().year} CCC · All rights reserved',
                  style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0x33FFFFFF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient Text
// ─────────────────────────────────────────────────────────────────────────────

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _GradientText(this.text, {required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Color(0xB3FFFFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(text, style: style),
    );
  }
}
