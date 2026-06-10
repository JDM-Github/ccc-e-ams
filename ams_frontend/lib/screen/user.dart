import 'dart:convert';
import 'dart:typed_data';

import 'package:ccc_ojt_schedule/components/change_password.dart';
import 'package:ccc_ojt_schedule/components/change_profile.dart';
import 'package:ccc_ojt_schedule/components/dialogue_helpers.dart';
import 'package:ccc_ojt_schedule/components/logout.dart';
import 'package:ccc_ojt_schedule/components/members/edit_member.dart';
import 'package:ccc_ojt_schedule/components/schedule/proof_image.dart';
import 'package:ccc_ojt_schedule/components/schedule/schedule_record.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:ccc_ojt_schedule/store/member_store.dart';
import 'package:ccc_ojt_schedule/store/schedule_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';

class UserPage extends StatefulWidget {
  final VoidCallback? onLogout;
  const UserPage({super.key, this.onLogout});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> with TickerProviderStateMixin {
  final LoginStore _loginStore = LoginStore();
  final ScheduleStore _scheduleStore = ScheduleStore();
  bool _isLoading = true;

  late List<AnimationController> _staggerControllers;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const int _maxCards = 6;

  @override
  void initState() {
    super.initState();
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

    _loadData();
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
    super.dispose();
  }

  String _initials(String firstName, String lastName) {
    return ((firstName.isNotEmpty ? firstName[0] : '') + (lastName.isNotEmpty ? lastName[0] : '')).toUpperCase();
  }

  Future<void> _showLogoutDialog() async {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: const LogoutDialog(),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: const ChangePasswordDialog(),
      ),
    );
  }

  Future<void> _showChangeProfilePictureDialog(String initial) async {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ChangeProfilePictureDialog(loadData: _loadData, initial: initial),
      ),
    );
  }

  Future<void> _showChangeProfileInformation() async {
    final user = _loginStore.user.value;
    final member = Member(
      id: user['id']?.toString() ?? '0',
      firstName: user['first_name'],
      middleName: user['middle_name'],
      lastName: user['last_name'],
      extensionName: user['extension_name'],
      cccId: user['ccc_id'],
      email: user['email'],
      role: user['role'],
      customId: user['custom_id']?.toString() ?? '',
      profileLink: user['profile_link'],
      course: user['course'],
      targetHours: user['target_hours'],
      isAdmin: user['isAdmin'] ?? false,
      current_sy: user['current_sy'] ?? false,
      createdAt: DateTime.now(),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditMemberDialog(
        member: member,
        onConfirm: (m) async {
          AppSnackBar.loading(context, 'Updating profile…', id: 'edit-profile');
          try {
            final nav = Navigator.of(context).context;
            Navigator.pop(context);
            await _loginStore.editUser(m);
            await _loadData();
            if (!mounted) return;
            AppSnackBar.hide(nav, id: 'edit-profile');
            AppSnackBar.success(nav, 'Profile updated successfully.', id: 'edit-profile-success');
          } catch (_) {
            if (!mounted) return;
            AppSnackBar.hide(context, id: 'edit-profile');
            AppSnackBar.error(context, 'Failed to update profile.', id: 'edit-profile-error');
          }
        },
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _scheduleStore.loadFromLocal();
    final cccId = _loginStore.user.value['ccc_id'];
    if (cccId != null) await _scheduleStore.fetchSchedules(cccId);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refresh() async {
    _resetStagger();
    await _loadData();
  }

  TimeOfDay _effectiveTimeIn(ScheduleRecord r) {
    if (ScheduleRecord.isEarly(r.timeIn) && !r.isAcceptedEarly) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
    return r.timeIn;
  }

  bool _isPast(DateTime date) {
    final today = DateTime.now();
    return DateTime(date.year, date.month, date.day).isBefore(DateTime(today.year, today.month, today.day));
  }

  double _calcHours(TimeOfDay i, TimeOfDay o) {
    final inM = i.hour * 60 + i.minute;
    final outM = o.hour * 60 + o.minute;
    if (outM <= inM) return 0;
    int total = outM - inM;
    const ls = 12 * 60, le = 13 * 60;
    if (outM > ls && inM < le) {
      total -= ((outM < le ? outM : le) - (inM > ls ? inM : ls));
    }
    return total / 60.0;
  }

  double get _completedHours => _scheduleStore.schedules.fold(0.0, (sum, r) {
    if (r.isInOffice && !r.isAcceptedWorkFromHome) return sum;
    final tIn = _effectiveTimeIn(r);
    final tOut = r.timeOut ?? (_isPast(r.date) ? const TimeOfDay(hour: 17, minute: 0) : null);
    return tOut != null ? sum + _calcHours(tIn, tOut) : sum;
  });

  int get _totalDays => _scheduleStore.schedules.where((r) => !(r.isInOffice && !r.isAcceptedWorkFromHome)).length;

  int get _completed => _scheduleStore.schedules
      .where((r) => !(r.isInOffice && !r.isAcceptedWorkFromHome) && (r.timeOut != null || _isPast(r.date)))
      .length;

  int get _pending => _scheduleStore.schedules
      .where((r) => !(r.isInOffice && !r.isAcceptedWorkFromHome) && r.timeOut == null && !_isPast(r.date))
      .length;

  int get _wfhPending => _scheduleStore.schedules.where((r) => r.isInOffice && !r.isAcceptedWorkFromHome).length;

  Future<void> _showProofImage(String src, String title, DateTime date) async {
    Uint8List? bytes;
    if (src.startsWith('http')) {
      try {
        final f = await DefaultCacheManager().getSingleFile(src);
        bytes = await f.readAsBytes();
      } catch (_) {}
    } else {
      try {
        bytes = base64Decode(src);
      } catch (_) {}
    }
    bytes ??= Uint8List(0);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ProofImageViewer(imageBytes: bytes!, title: title, date: date),
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

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: _loginStore.user,
      builder: (context, user, _) {
        if (user.isEmpty) {
          return Scaffold(
            backgroundColor: ThemeManager.scaffold(context),
            body: Center(
              child: Text('No user logged in', style: GoogleFonts.dmSans(color: ThemeManager.muted(context))),
            ),
          );
        }

        final role = user['role'] as String;
        final firstName = user['first_name'] as String;
        final middleName = (user['middle_name'] as String?) ?? '';
        final lastName = user['last_name'] as String;
        final suffixName = user['suffix_name'] as String? ?? '';
        final extensionName = (user['extension_name'] as String?) ?? '';
        final cccId = user['ccc_id'] as String;
        final customId = user['custom_id']?.toString() ?? '';
        final email = user['email'] as String;
        final profileLink = user['profile_link'] as String?;
        final course = user['course'] as String? ?? '';
        final targetHours = user['target_hours'] as int? ?? 0;
        final isAdmin = user['isAdmin'] as bool? ?? false;
        final fullName = _formatFullName(firstName, middleName, lastName, suffixName, extensionName);
        final initial = _initials(firstName, lastName);
        final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

        return Scaffold(
          backgroundColor: ThemeManager.scaffold(context),
          body: RefreshIndicator(
            onRefresh: _refresh,
            color: Colors.white,
            backgroundColor: const Color(0xFF1B3769),
            child: role == 'student'
                ? (isLandscape
                      ? _studentPc(initial, fullName, cccId, customId, email, course, targetHours, profileLink, isDark)
                      : _studentMobile(
                          initial,
                          fullName,
                          cccId,
                          customId,
                          email,
                          course,
                          targetHours,
                          profileLink,
                          isDark,
                        ))
                : (isLandscape
                      ? _supervisorPc(initial, fullName, cccId, customId, email, isAdmin, profileLink, isDark)
                      : _supervisorMobile(initial, fullName, cccId, customId, email, isAdmin, profileLink, isDark)),
          ),
        );
      },
    );
  }

  // ── Student PC ────────────────────────────────────────────────────────────

  Widget _studentPc(
    String initial,
    String fullName,
    String cccId,
    String customId,
    String email,
    String course,
    int targetHours,
    String? profileLink,
    bool isDark,
  ) {
    final hours = _completedHours;
    final progress = targetHours > 0 ? (hours / targetHours).clamp(0.0, 1.0) : 0.0;
    final remaining = (targetHours - hours).clamp(0.0, double.infinity);
    final done = hours >= targetHours;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _animated(
                    0,
                    _profileHero(initial, fullName, cccId, customId, email, 'STUDENT', profileLink, isDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: _animated(1, _progressCard(hours, targetHours, progress, remaining, done, isDark)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _animated(2, _statsCard(isDark))),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: _animated(3, _academicCard(course, targetHours, isDark))),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: _animated(4, _settingsCard(initial, isDark))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Student Mobile ────────────────────────────────────────────────────────

  Widget _studentMobile(
    String initial,
    String fullName,
    String cccId,
    String customId,
    String email,
    String course,
    int targetHours,
    String? profileLink,
    bool isDark,
  ) {
    final hours = _completedHours;
    final progress = targetHours > 0 ? (hours / targetHours).clamp(0.0, 1.0) : 0.0;
    final remaining = (targetHours - hours).clamp(0.0, double.infinity);
    final done = hours >= targetHours;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        _animated(0, _profileHero(initial, fullName, cccId, customId, email, 'STUDENT', profileLink, isDark)),
        const SizedBox(height: 10),
        _animated(1, _progressCard(hours, targetHours, progress, remaining, done, isDark)),
        const SizedBox(height: 10),
        _animated(2, _statsCard(isDark)),
        const SizedBox(height: 10),
        _animated(3, _academicCard(course, targetHours, isDark)),
        const SizedBox(height: 10),
        _animated(4, _settingsCard(initial, isDark)),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Supervisor PC ─────────────────────────────────────────────────────────

  Widget _supervisorPc(
    String initial,
    String fullName,
    String cccId,
    String customId,
    String email,
    bool isAdmin,
    String? profileLink,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: _animated(
                0,
                _profileHero(
                  initial,
                  fullName,
                  cccId,
                  customId,
                  email,
                  isAdmin ? 'ADMIN' : 'SUPERVISOR',
                  profileLink,
                  isDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: _animated(1, _settingsCard(initial, isDark))),
          ],
        ),
      ),
    );
  }

  // ── Supervisor Mobile ─────────────────────────────────────────────────────

  Widget _supervisorMobile(
    String initial,
    String fullName,
    String cccId,
    String customId,
    String email,
    bool isAdmin,
    String? profileLink,
    bool isDark,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        _animated(
          0,
          _profileHero(
            initial,
            fullName,
            cccId,
            customId,
            email,
            isAdmin ? 'ADMIN' : 'SUPERVISOR',
            profileLink,
            isDark,
          ),
        ),
        const SizedBox(height: 10),
        _animated(1, _settingsCard(initial, isDark)),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Stagger wrapper ───────────────────────────────────────────────────────

  Widget _animated(int index, Widget child) {
    final i = index.clamp(0, _maxCards - 1);
    return FadeTransition(
      opacity: _fadeAnims[i],
      child: SlideTransition(position: _slideAnims[i], child: child),
    );
  }

  // ── Profile Hero ──────────────────────────────────────────────────────────

  Widget _profileHero(
    String initial,
    String fullName,
    String cccId,
    String customId,
    String email,
    String role,
    String? profileLink,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1C3A), Color(0xFF1B3769)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1B3769).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Changed from center to start for equal height alignment
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: profileLink != null && profileLink.isNotEmpty
                ? () => _showProofImage(profileLink, '$fullName\'s Profile Picture', DateTime.now())
                : null,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
              ),
              child: profileLink != null && profileLink.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        profileLink,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            initial,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(
              role,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.badge_outlined, size: 12, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(
                cccId,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              if (customId.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  width: 1,
                  height: 11,
                  color: Colors.white.withOpacity(0.3),
                ),
                Icon(Icons.tag_rounded, size: 12, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(
                  customId,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, size: 12, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white.withOpacity(0.65)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Progress Card ─────────────────────────────────────────────────────────

  Widget _progressCard(double hours, int target, double progress, double remaining, bool done, bool isDark) {
    return card(
      context,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      icon: Icons.timeline_rounded,
      title: 'OJT Progress',
      child: _isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(color: ThemeManager.blue(context)),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${hours.toStringAsFixed(1)} hrs',
                          style: GoogleFonts.dmSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: ThemeManager.primary(context),
                          ),
                        ),
                        Text(
                          'of $target hours',
                          style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: done
                            ? const Color(0xFF10B981).withOpacity(isDark ? 0.12 : 0.09)
                            : const Color(0xFF1B3769).withOpacity(0.09),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: done
                              ? const Color(0xFF10B981).withOpacity(0.3)
                              : const Color(0xFF1B3769).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        '${((progress * 100).clamp(0, 100)).floor()}%',
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: done ? const Color(0xFF10B981) : const Color(0xFF1B3769),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => LinearProgressIndicator(
                      value: val,
                      backgroundColor: ThemeManager.dividerColor(context),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        done ? const Color(0xFF10B981) : const Color(0xFF1B3769),
                      ),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle_rounded : Icons.access_time_rounded,
                      size: 14,
                      color: done ? const Color(0xFF10B981) : Colors.orange[600],
                    ),
                    const SizedBox(width: 5),
                    Text(
                      done ? 'Target hours completed' : '${remaining.toStringAsFixed(1)} hours remaining',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: done ? const Color(0xFF10B981) : ThemeManager.secondary(context),
                      ),
                    ),
                  ],
                ),
                if (_wfhPending > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.orange.withOpacity(0.08) : Colors.orange[50],
                      border: Border.all(color: isDark ? Colors.orange.withOpacity(0.2) : Colors.orange[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange[700]),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '$_wfhPending WFH record${_wfhPending > 1 ? 's' : ''} pending approval (not counted)',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  // ── Stats Card ────────────────────────────────────────────────────────────

  Widget _statsCard(bool isDark) {
    return card(
      context,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      icon: Icons.bar_chart_rounded,
      title: 'Statistics',
      child: Column(
        children: [
          _statRow(Icons.event_available_rounded, 'Total days', '$_totalDays', ThemeManager.blue(context), isDark),
          const SizedBox(height: 10),
          _statRow(Icons.check_circle_rounded, 'Completed', '$_completed', const Color(0xFF10B981), isDark),
          const SizedBox(height: 10),
          _statRow(Icons.pending_rounded, 'Pending', '$_pending', Colors.orange[600]!, isDark),
          if (_wfhPending > 0) ...[
            const SizedBox(height: 10),
            _statRow(Icons.home_outlined, 'WFH pending', '$_wfhPending', Colors.red[600]!, isDark),
          ],
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.12 : 0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.secondary(context))),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  // ── Academic Card ─────────────────────────────────────────────────────────

  Widget _academicCard(String course, int target, bool isDark) {
    return card(
      context,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      icon: Icons.school_rounded,
      title: 'Academic information',
      child: Column(
        children: [
          _infoRow('Course', course),
          Divider(height: 20, color: ThemeManager.dividerColor(context)),
          _infoRow('Target hours', '$target hours'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context))),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: ThemeManager.primary(context)),
          ),
        ),
      ],
    );
  }

  // ── Settings Card ─────────────────────────────────────────────────────────

  Widget _settingsCard(String initial, bool isDark) {
    return card(
      context,
      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
      icon: Icons.manage_accounts_rounded,
      title: 'Account settings',
      child: Column(
        children: [
          _actionTile(Icons.info_outline_rounded, 'Change profile information', _showChangeProfileInformation),
          Divider(height: 1, color: ThemeManager.dividerColor(context)),
          _actionTile(
            Icons.person_outline_rounded,
            'Change profile picture',
            () => _showChangeProfilePictureDialog(initial),
          ),
          Divider(height: 1, color: ThemeManager.dividerColor(context)),
          _actionTile(Icons.lock_outline_rounded, 'Change password', _showChangePasswordDialog),
          Divider(height: 1, color: ThemeManager.dividerColor(context)),
          _actionTile(Icons.logout_rounded, 'Logout', _showLogoutDialog, color: Colors.red[600]!),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    final c = color ?? ThemeManager.secondary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, color: c, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color ?? ThemeManager.primary(context),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: ThemeManager.faint(context)),
          ],
        ),
      ),
    );
  }
}
