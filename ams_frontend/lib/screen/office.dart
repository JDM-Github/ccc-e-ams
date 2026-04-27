import 'package:ccc_ojt_schedule/components/dialogue_helpers.dart';
import 'package:ccc_ojt_schedule/controllers/office_controller.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:google_fonts/google_fonts.dart';

class OfficePage extends StatefulWidget {
  const OfficePage({super.key});

  @override
  State<OfficePage> createState() => _OfficePageState();
}

class _OfficePageState extends State<OfficePage> with TickerProviderStateMixin {
  late OfficeController controller;
  late List<AnimationController> _staggerControllers;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const int _maxCards = 5; // Identity, Policy, Schedule, Location, Data

  @override
  void initState() {
    super.initState();
    controller = OfficeController(loginStore: LoginStore());

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
    controller.disposeControllers();
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
        return Scaffold(
          backgroundColor: ThemeManager.scaffold(context),
          body: Column(
            children: [
              _buildTopBar(isDark),
              Expanded(child: isLandscape ? _buildPcContent(isDark) : _buildMobileContent(isDark)),
            ],
          ),
        );
      },
    );
  }

  // ── Top Bar (unchanged except resetStagger on edit) ───────────────────────

  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        border: Border(bottom: BorderSide(color: ThemeManager.dividerColor(context))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3769).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business_rounded, color: Color(0xFF1B3769), size: 17),
          ),
          const SizedBox(width: 10),
          Text(
            controller.user['office_name'] ?? 'Office',
            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeManager.primary(context)),
          ),
          const Spacer(),
          if (controller.isSupervisor && !controller.isEditing)
            _topBtn(
              label: 'Edit Settings',
              icon: Icons.edit_rounded,
              onTap: () {
                controller.startEdit();
                _resetStagger();
              },
              filled: true,
            ),
          if (controller.isEditing) ...[
            _topBtn(
              label: 'Cancel',
              icon: Icons.close_rounded,
              onTap: controller.isSaving
                  ? null
                  : () {
                      controller.cancelEdit();
                      _resetStagger();
                    },
            ),
            const SizedBox(width: 8),
            _topBtn(
              label: controller.isSaving ? 'Saving…' : 'Save Changes',
              icon: controller.isSaving ? null : Icons.check_rounded,
              onTap: controller.isSaving ? null : () => controller.saveChanges(context),
              filled: true,
              fillColor: const Color(0xFF16A34A),
              loading: controller.isSaving,
            ),
          ],
        ],
      ),
    );
  }

  Widget _topBtn({
    required String label,
    IconData? icon,
    VoidCallback? onTap,
    bool filled = false,
    Color fillColor = const Color(0xFF1B3769),
    bool loading = false,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? fillColor : ThemeManager.surfaceElevated(context),
          foregroundColor: filled ? Colors.white : ThemeManager.secondary(context),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: filled ? fillColor : ThemeManager.border(context)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else if (icon != null)
              Icon(icon, size: 14),
            if ((icon != null || loading) && label.isNotEmpty) const SizedBox(width: 5),
            Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── PC Layout with staggered cards and equal height ───────────────────────

  Widget _buildPcContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (controller.isEditing) ...[_buildEditBanner(), const SizedBox(height: 12)],
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _animated(0, _buildIdentityCard(isDark))),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: _animated(1, _buildPolicyCard(isDark))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _animated(2, _buildScheduleCard(isDark))),
                const SizedBox(width: 12),
                Expanded(child: _animated(3, _buildLocationCard(isDark))),
              ],
            ),
          ),
          if (controller.isSupervisor) ...[const SizedBox(height: 12), _animated(4, _buildDataCard(isDark))],
        ],
      ),
    );
  }

  // ── Mobile Layout (vertical, staggered) ───────────────────────────────────

  Widget _buildMobileContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (controller.isEditing) ...[_buildEditBanner(), const SizedBox(height: 10)],
          _animated(0, _buildIdentityCard(isDark)),
          const SizedBox(height: 10),
          _animated(1, _buildPolicyCard(isDark)),
          const SizedBox(height: 10),
          _animated(2, _buildScheduleCard(isDark)),
          const SizedBox(height: 10),
          _animated(3, _buildLocationCard(isDark)),
          if (controller.isSupervisor) ...[const SizedBox(height: 10), _animated(4, _buildDataCard(isDark))],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Edit Banner (unchanged) ───────────────────────────────────────────────

  Widget _buildEditBanner() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Container(
        key: const ValueKey('edit-banner'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3769).withOpacity(0.05),
          border: Border.all(color: const Color(0xFF1B3769).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: Color(0xFF1B3769), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Editing mode — make your changes below and press Save Changes when done.',
                style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF1B3769), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
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
    if (suffix.isNotEmpty) {
      base = '$base, $suffix';
    }

    final ext = extensionName?.trim();
    if (ext != null && ext.isNotEmpty) {
      base = '$base, $ext';
    }
    return base;
  }

  // ── Cards using the new `card` from dialogue_helpers.dart ─────────────────

  Widget _buildIdentityCard(bool isDark) {
    final u = controller.user;
    final fullName = _formatFullName(
      u['first_name'] ?? '',
      u['middle_name'] ?? '',
      u['last_name'] ?? '',
      u['suffix_name'] ?? '',
      u['extension_name'],
    );

    return card(
      context,
      icon: Icons.business_rounded,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      title: 'Office identity',
      child: Column(
        children: [
          if (controller.isEditing) ...[
            _editField(label: 'Office name', ctrl: controller.officeNameCtrl, icon: Icons.business_outlined),
            const SizedBox(height: 10),
          ] else ...[
            _infoRow('Office name', u['office_name'] ?? '—'),
            _divider(),
          ],
          _infoRow('Supervisor ID', u['ccc_id'] ?? '—'),
          _divider(),
          _infoRow('Supervisor', fullName.isEmpty ? '—' : fullName),
          _divider(),
          _infoRow('Email', u['email'] ?? '—', valueColor: ThemeManager.blue(context)),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(bool isDark) {
    final u = controller.user;
    final currentSY = (u['current_sy'] as num?)?.toInt() ?? 2025;
    final currentIter = (u['current_iteration'] as num?)?.toInt() ?? 1;
    final activeSY = currentSY + currentIter - 1;
    return card(
      context,
      icon: Icons.policy_outlined,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      title: 'Academic year & policy',
      child: Column(
        children: [
          _infoRow('Active academic year', 'AY $activeSY-${activeSY + 1}', badge: true),
          _divider(),
          _infoRow('Iteration', '#$currentIter'),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(bool isDark) {
    final u = controller.user;
    return card(
      context,
      icon: Icons.schedule_rounded,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      title: 'Schedule settings',
      child: controller.isEditing
          ? Column(
              children: [
                _timeField(label: 'Time in start (office)', ctrl: controller.timeInStartCtrl),
                const SizedBox(height: 8),
                _timeField(label: 'Time in start (WFH)', ctrl: controller.timeInStartWfhCtrl),
                const SizedBox(height: 8),
                _timeField(label: 'Time in end', ctrl: controller.timeInEndCtrl),
                const SizedBox(height: 8),
                _timeField(label: 'Time out cap', ctrl: controller.timeOutCapCtrl),
                const SizedBox(height: 10),
                _toggleRow(
                  label: 'Allow weekend',
                  subtitle: 'Students can log records on Sat & Sun',
                  value: controller.allowWeekend,
                  onChanged: controller.setAllowWeekend,
                ),
              ],
            )
          : Column(
              children: [
                _infoRow('Time in start (office)', _fmtTime(u['time_in_start'])),
                _divider(),
                _infoRow('Time in start (WFH)', _fmtTime(u['time_in_start_wfh'])),
                _divider(),
                _infoRow('Time in end', _fmtTime(u['time_in_end'])),
                _divider(),
                _infoRow('Time out cap', _fmtTime(u['time_out_cap'])),
                _divider(),
                _infoRow('Allow weekends', (u['allow_weekend'] ?? false) ? 'Yes' : 'No'),
              ],
            ),
    );
  }

  Widget _buildLocationCard(bool isDark) {
    final u = controller.user;
    final lat = (u['latitude'] as num?)?.toDouble();
    final lng = (u['longitude'] as num?)?.toDouble();
    return card(
      context,
      icon: Icons.location_on_rounded,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      title: 'Office location',
      child: Column(
        children: [
          _infoRow('Latitude', lat != null ? lat.toStringAsFixed(6) : '—'),
          _divider(),
          _infoRow('Longitude', lng != null ? lng.toStringAsFixed(6) : '—'),
          _divider(),
          _infoRow('Check-in radius', '40 m'),
        ],
      ),
    );
  }

  Widget _buildDataCard(bool isDark) {
    return card(
      context,
      icon: Icons.storage_rounded,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      title: 'Data management',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3769).withOpacity(0.04),
              border: Border.all(color: const Color(0xFF1B3769).withOpacity(0.12)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: const Color(0xFF1B3769).withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Backup saves all users, schedules, and records. Restore will overwrite current office data.',
                    style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.secondary(context), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: (controller.isBackingUp || controller.isRestoring)
                        ? null
                        : () => controller.backupOffice(context),
                    icon: controller.isBackingUp
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded, size: 15),
                    label: Text(
                      controller.isBackingUp ? 'Backing up…' : 'Backup',
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B3769),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: (controller.isBackingUp || controller.isRestoring)
                        ? null
                        : () => controller.restoreOffice(context),
                    icon: controller.isRestoring
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                          )
                        : const Icon(Icons.restore_rounded, size: 15),
                    label: Text(
                      controller.isRestoring ? 'Restoring…' : 'Restore',
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: BorderSide(color: const Color(0xFFDC2626).withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shared UI helpers (unchanged) ─────────────────────────────────────────

  Widget _infoRow(String label, String value, {Color? valueColor, bool badge = false}) {
    final color = valueColor ?? ThemeManager.primary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context))),
          badge
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ThemeManager.blue(context).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ThemeManager.blue(context),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: color),
                ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 10, color: ThemeManager.dividerColor(context));

  Widget _editField({required String label, required TextEditingController ctrl, required IconData icon}) {
    return TextFormField(
      controller: ctrl,
      style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.primary(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context)),
        prefixIcon: Icon(icon, size: 15, color: ThemeManager.muted(context)),
        filled: true,
        fillColor: ThemeManager.inputFillColor(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1B3769), width: 1.5),
        ),
      ),
    );
  }

  Widget _timeField({required String label, required TextEditingController ctrl}) {
    return GestureDetector(
      onTap: () => controller.pickTime(context, ctrl),
      child: AbsorbPointer(
        child: TextFormField(
          controller: ctrl,
          style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.primary(context)),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context)),
            prefixIcon: Icon(Icons.access_time_rounded, size: 15, color: ThemeManager.muted(context)),
            suffixIcon: Icon(Icons.arrow_drop_down_rounded, color: ThemeManager.muted(context)),
            filled: true,
            fillColor: ThemeManager.inputFillColor(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ThemeManager.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ThemeManager.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1B3769), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeManager.inputFillColor(context),
        border: Border.all(color: ThemeManager.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager.primary(context),
                  ),
                ),
                Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF1B3769),
            activeColor: Colors.white,
          ),
        ],
      ),
    );
  }

  String _fmtTime(dynamic raw) {
    if (raw == null) return '—';
    final parts = raw.toString().split(':');
    if (parts.length < 2) return raw.toString();
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }
}
