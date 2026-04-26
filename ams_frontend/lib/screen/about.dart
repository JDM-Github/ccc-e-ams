import 'package:ccc_ojt_schedule/components/dialogue_helpers.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _version = '1.0.0';
  static const String _buildNumber = '2026.03';

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final officeName = LoginStore().user.value['office_name'] ?? 'OJT Office';

    return Scaffold(
      backgroundColor: ThemeManager.scaffold(context),
      body: isLandscape ? _buildPcContent(context, officeName) : _buildMobileContent(context, officeName),
    );
  }

  // ── PC layout ──────────────────────────────────────────────────────────────

  Widget _buildPcContent(BuildContext context, String officeName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHero(context, officeName),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildVisionCard(context)),
                const SizedBox(width: 14),
                Expanded(child: _buildMissionCard(context)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildFeaturesCard(context),
          const SizedBox(height: 14),
          _buildVersionCard(context),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────────────────

  Widget _buildMobileContent(BuildContext context, String officeName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildHero(context, officeName),
          const SizedBox(height: 12),
          _buildVisionCard(context),
          const SizedBox(height: 12),
          _buildMissionCard(context),
          const SizedBox(height: 12),
          _buildFeaturesCard(context),
          const SizedBox(height: 12),
          _buildVersionCard(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Hero banner ────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context, String officeName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF080C14), Color(0xFF0F1E3C), Color(0xFF1B3769)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1B3769).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Image.asset('assets/ccc_icon.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CCC ATTENDANCE MONITORING SYSTEM',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'City College of Calamba',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$officeName — OJT Management',
                  style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.55), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _heroBadge(Icons.verified_rounded, 'v$_version'),
                    _heroBadge(Icons.calendar_today_rounded, 'Build $_buildNumber'),
                    _heroBadge(Icons.devices_rounded, 'Cross-Platform'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white.withOpacity(0.75)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.88)),
          ),
        ],
      ),
    );
  }

  // ── Vision ─────────────────────────────────────────────────────────────────

  Widget _buildVisionCard(BuildContext context) {
    return card(
      context,
      icon: Icons.visibility_outlined,
      iconColor: const Color(0xFF7C3AED),
      title: 'Vision',
      child: Text(
        'A reputable and internationally engaged local university that produces future-ready global professionals by 2035.',
        style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.bodyColor(context), height: 1.65),
      ),
    );
  }

  // ── Mission ────────────────────────────────────────────────────────────────

  Widget _buildMissionCard(BuildContext context) {
    return card(
      context,
      icon: Icons.flag_outlined,
      iconColor: const Color(0xFFDB2777),
      title: 'Mission',
      child: Text(
        'Cultivating future-ready global professionals through inclusive education, research-oriented culture and collaborative partnerships.',
        style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.bodyColor(context), height: 1.65),
      ),
    );
  }

  // ── Features ───────────────────────────────────────────────────────────────

  Widget _buildFeaturesCard(BuildContext context) {
    final features = [
      (
        Icons.location_on_rounded,
        const Color(0xFF10B981),
        'GPS-based Attendance',
        'Validates in-office presence using real-time GPS coordinates within a 40-meter radius.',
      ),
      (
        Icons.home_outlined,
        const Color(0xFF0891B2),
        'Work From Home Support',
        'Allows students to log WFH records, pending supervisor approval.',
      ),
      (
        Icons.photo_camera_outlined,
        const Color(0xFF7C3AED),
        'Proof Capture',
        'Camera integration for time-in/out photo proof on all platforms including Windows and Web.',
      ),
      (
        Icons.summarize_outlined,
        const Color(0xFFF59E0B),
        'Daily Summaries & Activities',
        'Students can document daily accomplishments with text summaries and photo records.',
      ),
      (
        Icons.table_chart_outlined,
        const Color(0xFF16A34A),
        'Excel Export',
        'Download complete OJT records as formatted Excel reports with custom date ranges.',
      ),
      (
        Icons.groups_outlined,
        const Color(0xFF1B3769),
        'Member Management',
        'Supervisors can view and manage all registered OJT students in their office.',
      ),
      (
        Icons.school_outlined,
        const Color(0xFFEA580C),
        'Multi-School Year',
        'Supports multiple academic iterations and school year advancement with full audit trail.',
      ),
      (
        Icons.devices_outlined,
        const Color(0xFF64748B),
        'Cross-Platform',
        'Runs on Android, iOS, Windows, and Web from a single codebase.',
      ),
    ];

    return card(
      context,
      icon: Icons.stars_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: 'Key Features',
      child: Column(
        children: features
            .asMap()
            .entries
            .map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: e.key < features.length - 1 ? 14 : 0),
                child: _featureRow(context, e.value.$1, e.value.$2, e.value.$3, e.value.$4),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _featureRow(BuildContext context, IconData icon, Color color, String title, String description) {
    final isDark = ThemeManager.isDark(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.15 : 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ThemeManager.primary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context), height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Version ────────────────────────────────────────────────────────────────

  Widget _buildVersionCard(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    return card(
      context,
      icon: Icons.info_outline_rounded,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      title: 'App Information',
      child: Column(
        children: [
          _versionRow(context, 'Version', _version),
          const SizedBox(height: 10),
          _versionRow(context, 'Build', _buildNumber),
          const SizedBox(height: 10),
          _versionRow(context, 'Institution', 'City College of Calamba'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3769).withOpacity(isDark ? 0.10 : 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1B3769).withOpacity(isDark ? 0.20 : 0.10)),
            ),
            child: Text(
              '© 2026 City College of Calamba.\nAll rights reserved.',
              style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context), height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _versionRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context), fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: ThemeManager.surfaceTint(context),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ThemeManager.border(context)),
          ),
          child: Text(
            value,
            style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.primary(context), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
