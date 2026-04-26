import 'package:ccc_ojt_schedule/components/dialogue_helpers.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/controllers/location_controller.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> with TickerProviderStateMixin {
  late LocationController controller;
  late List<AnimationController> _staggerControllers;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const int _maxCards = 4; 

  @override
  void initState() {
    super.initState();
    controller = LocationController(loginStore: LoginStore());
    controller.initializeLocation(context);

    _staggerControllers = List.generate(
      _maxCards,
      (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 320)),
    );
    _fadeAnims = _staggerControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut) as Animation<double>)
        .toList();
    _slideAnims = _staggerControllers
        .map(
          (c) => Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
        )
        .toList();

    _runStagger();
  }

  void _runStagger() async {
    for (int i = 0; i < _maxCards; i++) {
      await Future.delayed(Duration(milliseconds: 60 * i));
      if (mounted) _staggerControllers[i].forward();
    }
  }

  void _resetStagger() {
    for (final c in _staggerControllers) {
      c.reset();
    }
    _runStagger();
  }

  @override
  void dispose() {
    for (final c in _staggerControllers) {
      c.dispose();
    }
    controller.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    final i = index.clamp(0, _maxCards - 1);
    return FadeTransition(
      opacity: _fadeAnims[i],
      child: SlideTransition(position: _slideAnims[i], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final distance = controller.getDistanceToTarget();
        final inOffice = controller.isInOffice();

        return Scaffold(
          backgroundColor: ThemeManager.scaffold(context),
          body: Column(
            children: [
              _buildTopBar(inOffice, isDark),
              Expanded(
                child: controller.isLoading && controller.currentPosition == null
                    ? Center(child: CircularProgressIndicator(color: ThemeManager.blue(context)))
                    : isLandscape
                    ? _buildPcContent(distance, inOffice, isDark)
                    : _buildMobileContent(distance, inOffice, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(bool inOffice, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        border: Border(bottom: BorderSide(color: ThemeManager.dividerColor(context))),
      ),
      child: Row(
        children: [
          _buildStatusPill(inOffice),
          const Spacer(),
          if (controller.isSupervisor) ...[
            _topBtn(
              label: 'Set office location',
              icon: Icons.edit_location_alt_rounded,
              onTap: () {
                if (controller.currentPosition == null) {
                  AppSnackBar.error(context, 'No GPS signal yet. Please wait.');
                  return;
                }
                controller.enterSetLocationMode();
                _resetStagger();
              },
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            height: 32,
            width: 32,
            child: OutlinedButton(
              onPressed: () {
                controller.refreshLocation(context);
                _resetStagger();
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: ThemeManager.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: controller.isLoading
                  ? SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ThemeManager.blue(context)),
                    )
                  : Icon(Icons.refresh_rounded, size: 16, color: ThemeManager.secondary(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(bool inOffice) {
    final color = inOffice ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final bg = inOffice ? const Color(0xFF10B981).withOpacity(0.09) : const Color(0xFFEF4444).withOpacity(0.08);
    final border = inOffice ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFEF4444).withOpacity(0.3);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(color: color, pulse: !inOffice),
          const SizedBox(width: 6),
          Text(
            inOffice ? 'In office' : 'Outside office',
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _topBtn({required String label, required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      height: 34,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeManager.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // ── PC Layout with staggered cards and equal height ───────────────────────

  Widget _buildPcContent(double? distance, bool inOffice, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (controller.isSettingLocation) ...[_buildSetLocationPanel(isDark), const SizedBox(height: 16)],
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _animated(0, _buildHeroCard(inOffice))),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _animated(
                    1,
                    distance != null
                        ? _buildDistanceCard(distance, isDark)
                        : _buildEmptyCard(Icons.straighten_rounded, 'Distance unavailable', isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _animated(2, _buildYourLocationCard(isDark))),
                const SizedBox(width: 12),
                Expanded(child: _animated(3, _buildOfficeLocationCard(isDark))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile layout (vertical, staggered) ───────────────────────────────────

  Widget _buildMobileContent(double? distance, bool inOffice, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (controller.isSettingLocation) ...[_buildSetLocationPanel(isDark), const SizedBox(height: 12)],
          _animated(0, _buildHeroCard(inOffice)),
          const SizedBox(height: 10),
          if (distance != null) ...[_animated(1, _buildDistanceCard(distance, isDark)), const SizedBox(height: 10)],
          if (controller.currentPosition != null) ...[
            _animated(2, _buildYourLocationCard(isDark)),
            const SizedBox(height: 10),
          ],
          _animated(3, _buildOfficeLocationCard(isDark)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Set Location Panel (no changes, but kept) ─────────────────────────────

  Widget _buildSetLocationPanel(bool isDark) {
    final hasGps = controller.currentPosition != null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Container(
        key: const ValueKey('set-location'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeManager.surface(context),
          border: Border.all(color: const Color(0xFF1B3769).withOpacity(0.25), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF1B3769).withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF10B981), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set office location',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ThemeManager.primary(context),
                        ),
                      ),
                      Text(
                        'Your current GPS coordinates will be saved as the office check-in point',
                        style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: ThemeManager.dividerColor(context)),
            const SizedBox(height: 14),
            if (hasGps) ...[
              Row(
                children: [
                  Expanded(
                    child: _coordPreview(
                      label: 'New latitude',
                      value: controller.currentPosition!.latitude.toStringAsFixed(6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _coordPreview(
                      label: 'New longitude',
                      value: controller.currentPosition!.longitude.toStringAsFixed(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.gps_fixed_rounded, size: 12, color: ThemeManager.green(context)),
                  const SizedBox(width: 4),
                  Text(
                    'Accuracy: ${controller.currentPosition!.accuracy.toStringAsFixed(1)} m',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: ThemeManager.green(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.orange.withOpacity(0.08) : Colors.orange[50],
                  border: Border.all(color: isDark ? Colors.orange.withOpacity(0.2) : Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.gps_not_fixed_rounded, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for GPS signal…',
                      style: GoogleFonts.dmSans(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: controller.isConfirming ? null : controller.cancelSetLocation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ThemeManager.secondary(context),
                        side: BorderSide(color: ThemeManager.border(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: (!hasGps || controller.isConfirming)
                          ? null
                          : () => controller.confirmSetLocation(context),
                      icon: controller.isConfirming
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 15),
                      label: Text(
                        controller.isConfirming ? 'Saving…' : 'Confirm set location',
                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3769),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        disabledBackgroundColor: ThemeManager.surfaceTint(context),
                        disabledForegroundColor: ThemeManager.muted(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _coordPreview({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3769).withOpacity(0.04),
        border: Border.all(color: const Color(0xFF1B3769).withOpacity(0.12)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 10, color: ThemeManager.muted(context), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1B3769)),
          ),
        ],
      ),
    );
  }

  // ── Info Cards (wrapped with staggered animation in parent) ───────────────

  Widget _buildHeroCard(bool inOffice) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: inOffice
              ? [const Color(0xFF059669), const Color(0xFF10B981)]
              : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  inOffice ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inOffice ? 'In office' : 'Out of office',
                    style: GoogleFonts.dmSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    inOffice ? 'You are within the office radius' : 'You are outside the office radius',
                    style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard(double distance, bool isDark) {
    return card(
      context,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      icon: Icons.straighten_rounded,
      title: 'Distance to office',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.formatDistance(distance),
            style: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.w600, color: const Color(0xFF1B3769)),
          ),
          const SizedBox(height: 3),
          Text('from office coordinates', style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context))),
        ],
      ),
    );
  }

  Widget _buildYourLocationCard(bool isDark) {
    return card(
      context,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      icon: Icons.my_location_rounded,
      title: 'Your location',
      child: controller.currentPosition != null
          ? Column(
              children: [
                _infoRow('Latitude', controller.currentPosition!.latitude.toStringAsFixed(6)),
                _divider(),
                _infoRow('Longitude', controller.currentPosition!.longitude.toStringAsFixed(6)),
                _divider(),
                _infoRow(
                  'Accuracy',
                  '${controller.currentPosition!.accuracy.toStringAsFixed(1)} m',
                  badge: true,
                  badgeColor: ThemeManager.green(context),
                ),
              ],
            )
          : Text(
              'Waiting for GPS signal…',
              style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.muted(context)),
            ),
    );
  }

  Widget _buildOfficeLocationCard(bool isDark) {
    return card(
      context,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      icon: Icons.location_on_rounded,
      title: 'Office location',
      child: Column(
        children: [
          _infoRow('Latitude', controller.targetLat.toStringAsFixed(6)),
          _divider(),
          _infoRow('Longitude', controller.targetLng.toStringAsFixed(6)),
          _divider(),
          _infoRow('Check-in radius', '40 m'),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(IconData icon, String message, bool isDark) {
    return card(
      context,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      icon: icon,
      title: 'Distance to office',
      child: Text(message, style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context))),
    );
  }

  Widget _infoRow(String label, String value, {bool badge = false, Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context))),
          badge && badgeColor != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    value,
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
                  ),
                )
              : Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ThemeManager.primary(context),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 10, color: ThemeManager.dividerColor(context));
}

// ── Pulsing dot widget (unchanged) ─────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool pulse;
  const _PulsingDot({required this.color, required this.pulse});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.35).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      );
    }
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}
