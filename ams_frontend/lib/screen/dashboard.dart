import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  final LoginStore _loginStore = LoginStore();

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  late List<AnimationController> _staggerCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const int _maxCards = 8;

  bool get _isSupervisor => _loginStore.user.value['role'] == 'supervisor';

  @override
  void initState() {
    super.initState();
    _staggerCtrl = List.generate(
      _maxCards,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 340)),
    );
    _fadeAnims = _staggerCtrl
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut) as Animation<double>)
        .toList();
    _slideAnims = _staggerCtrl
        .map(
          (c) => Tween<Offset>(
            begin: const Offset(0, 0.07),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
        )
        .toList();

    _load();
  }

  @override
  void dispose() {
    for (final c in _staggerCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _runStagger() async {
    for (int i = 0; i < _maxCards; i++) {
      await Future.delayed(Duration(milliseconds: 55 * i));
      if (mounted) _staggerCtrl[i].forward();
    }
  }

  void _resetStagger() {
    for (final c in _staggerCtrl) {
      c.reset();
    }
    _runStagger();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = _loginStore.user.value;
      late Map<String, dynamic> result;

      if (_isSupervisor) {
        final officeId = user['office_id'] as String;
        result = await RequestHandler().handleRequest('dashboard/office/$officeId', method: 'GET');
      } else {
        final cccId = user['ccc_id'] as String;
        result = await RequestHandler().handleRequest('dashboard/student/$cccId', method: 'GET');
      }

      if (mounted) {
        setState(() => _data = result);
        _runStagger();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    _resetStagger();
    await _load();
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

    return Scaffold(
      backgroundColor: ThemeManager.scaffold(context),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: ThemeManager.blue(context)))
          : (_error != null || _data == null)
          ? _buildError(isDark)
          : RefreshIndicator(
              onRefresh: _refresh,
              color: Colors.white,
              backgroundColor: const Color(0xFF1B3769),
              child: _isSupervisor
                  ? _buildSupervisorDashboard(isDark, isLandscape)
                  : _buildStudentDashboard(isDark, isLandscape),
            ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3769).withOpacity(isDark ? 0.12 : 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off_rounded, size: 38, color: ThemeManager.muted(context)),
          ),
          const SizedBox(height: 14),
          Text(
            'Failed to load dashboard',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ThemeManager.secondary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(_error ?? '', style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context))),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: Text('Retry', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: ThemeManager.blue(context),
              side: BorderSide(color: ThemeManager.blue(context).withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STUDENT DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStudentDashboard(bool isDark, bool isLandscape) {
    final d = _data!;

    // ── Pull server-computed progress values directly from ojt_progress ──
    final ojt = d['ojt_progress'] as Map? ?? {};
    final student = d['student'] as Map? ?? {};
    final todaySched = d['today_schedule'] as Map?;
    final recentActivities = (d['recent_activities'] as List?)?.cast<Map>() ?? [];

    // Server owns these numbers — no local recomputation
    final targetHours = (ojt['target_hours'] as num?)?.toDouble() ?? 0;
    final rendered = (ojt['total_rendered_hours'] as num?)?.toDouble() ?? 0;
    final remaining = (ojt['remaining_hours'] as num?)?.toDouble() ?? 0;
    final progress = (ojt['progress_percentage'] as num?)?.toDouble() ?? 0;
    final totalDays = (ojt['total_days'] as num?)?.toInt() ?? 0;
    final isDone = ojt['is_done'] as bool? ?? false;

    // ── recent_schedules comes straight from the server ───────────────────
    // Shape: { date, time_in, time_out, isWorkFromHome,
    //          isAcceptedWorkFromHome, isAcceptedEarly }
    final recentSchedules = (d['recent_schedules'] as List?)?.cast<Map>() ?? [];

    final firstName = student['first_name'] as String? ?? '';
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: isLandscape
          ? _studentPcLayout(
              isDark,
              greeting,
              firstName,
              targetHours,
              rendered,
              remaining,
              progress,
              totalDays,
              isDone,
              todaySched,
              recentSchedules,
              recentActivities,
            )
          : _studentMobileLayout(
              isDark,
              greeting,
              firstName,
              targetHours,
              rendered,
              remaining,
              progress,
              totalDays,
              isDone,
              todaySched,
              recentSchedules,
              recentActivities,
            ),
    );
  }

  Widget _studentPcLayout(
    bool isDark,
    String greeting,
    String firstName,
    double targetHours,
    double rendered,
    double remaining,
    double progress,
    int totalDays,
    bool isDone,
    Map? todaySched,
    List<Map> recentSchedules,
    List<Map> recentActivities,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _animated(0, _greetingBanner(greeting, firstName, isDark)),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildMissionCard(context),
                  const SizedBox(height: 12),
                  _buildVisionCard(context),
                  const SizedBox(height: 12),
                  _animated(1, _progressCard(targetHours, rendered, remaining, progress, isDone, isDark)),
                  const SizedBox(height: 12),
                  _animated(3, _recentSchedulesCard(recentSchedules, isDark)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _animated(2, _todayCard(todaySched, isDark)),
                  const SizedBox(height: 12),
                  _animated(4, _statsRow(totalDays, rendered, isDone, isDark)),
                  if (recentActivities.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _animated(5, _activitiesCard(recentActivities, isDark)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _studentMobileLayout(
    bool isDark,
    String greeting,
    String firstName,
    double targetHours,
    double rendered,
    double remaining,
    double progress,
    int totalDays,
    bool isDone,
    Map? todaySched,
    List<Map> recentSchedules,
    List<Map> recentActivities,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _animated(0, _greetingBanner(greeting, firstName, isDark)),
        const SizedBox(height: 12),
        _animated(1, _progressCard(targetHours, rendered, remaining, progress, isDone, isDark)),
        const SizedBox(height: 12),
        _buildMissionCard(context),
        const SizedBox(height: 12),
        _buildVisionCard(context),
        const SizedBox(height: 10),
        _animated(2, _todayCard(todaySched, isDark)),
        const SizedBox(height: 10),
        _animated(3, _statsRow(totalDays, rendered, isDone, isDark)),
        const SizedBox(height: 10),
        _animated(4, _recentSchedulesCard(recentSchedules, isDark)),
        if (recentActivities.isNotEmpty) ...[
          const SizedBox(height: 10),
          _animated(5, _activitiesCard(recentActivities, isDark)),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Greeting banner ───────────────────────────────────────────────────────

  Widget _greetingBanner(String greeting, String firstName, bool isDark) {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.60),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName.isNotEmpty ? firstName : 'Student',
                  style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 9, color: Colors.white.withOpacity(0.70)),
                      const SizedBox(width: 5),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(now),
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Icon(Icons.school_rounded, size: 28, color: Colors.white.withOpacity(0.70)),
          ),
        ],
      ),
    );
  }

  // ── Progress card ─────────────────────────────────────────────────────────

  Widget _progressCard(double target, double rendered, double remaining, double progress, bool isDone, bool isDark) {
    final pct = (progress / 100).clamp(0.0, 1.0);
    final progressColor = isDone ? const Color(0xFF10B981) : const Color(0xFF1B3769);

    return _card(
      icon: Icons.timeline_rounded,
      title: 'OJT progress',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rendered.toStringAsFixed(1)} hrs',
                    style: GoogleFonts.dmSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: ThemeManager.primary(context),
                    ),
                  ),
                  Text(
                    'of ${target.toStringAsFixed(0)} hours',
                    style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(isDark ? 0.12 : 0.09),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: progressColor.withOpacity(0.25)),
                ),
                child: Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w800, color: progressColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                backgroundColor: ThemeManager.dividerColor(context),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.access_time_rounded,
                size: 14,
                color: isDone ? const Color(0xFF10B981) : Colors.orange[600],
              ),
              const SizedBox(width: 5),
              Text(
                isDone ? 'Target hours completed!' : '${remaining.toStringAsFixed(1)} hours remaining',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDone ? const Color(0xFF10B981) : ThemeManager.secondary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Today card ────────────────────────────────────────────────────────────

  Widget _todayCard(Map? sched, bool isDark) {
    // today_schedule is a raw Schedule row — field names are snake_case
    final hasEntry = sched != null;
    final hasTimeOut = hasEntry && sched['time_out'] != null;

    return _card(
      icon: Icons.today_rounded,
      title: "Today's attendance",
      isDark: isDark,
      child: hasEntry
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _timeRow(
                  Icons.login_rounded,
                  'Time in',
                  sched['time_in'] as String? ?? '--:--',
                  const Color(0xFF10B981),
                  isDark,
                ),
                Divider(height: 14, color: ThemeManager.dividerColor(context)),
                _timeRow(
                  Icons.logout_rounded,
                  'Time out',
                  hasTimeOut ? sched['time_out'] as String : '--:--',
                  hasTimeOut ? const Color(0xFFFF4E0B) : ThemeManager.muted(context),
                  isDark,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (sched['isWorkFromHome'] == true) ...[
                      _badge('WFH', const Color(0xFF2563EB), isDark),
                      const SizedBox(width: 6),
                    ],
                    _badge(
                      hasTimeOut ? 'Done' : 'Active',
                      hasTimeOut ? const Color(0xFF10B981) : const Color(0xFF1B3769),
                      isDark,
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                Icon(Icons.event_busy_rounded, size: 32, color: ThemeManager.faint(context)),
                const SizedBox(height: 8),
                Text(
                  'No attendance recorded today',
                  style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _timeRow(IconData icon, String label, String time, Color color, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: ThemeManager.blue(context)),
        ),
        const SizedBox(width: 6),
        Text(
          _formatTime(time),
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: ThemeManager.primary(context)),
        ),
      ],
    );
  }

  // ── Quick stats row ───────────────────────────────────────────────────────

  Widget _statsRow(int totalDays, double rendered, bool isDone, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _miniStatCard(
            Icons.event_available_rounded,
            '$totalDays',
            'Total days',
            ThemeManager.blue(context),
            isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStatCard(
            isDone ? Icons.check_circle_rounded : Icons.timer_outlined,
            '${rendered.toStringAsFixed(0)}h',
            'Rendered',
            isDone ? const Color(0xFF10B981) : const Color(0xFF1B3769),
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard(IconData icon, String value, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ThemeManager.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeManager.border(context)),
        boxShadow: isDark ? null : [const BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.12 : 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ThemeManager.primary(context),
                ),
              ),
              Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: ThemeManager.muted(context))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Recent schedules card ─────────────────────────────────────────────────
  // Reads server shape: { date, time_in, time_out,
  //                       isWorkFromHome, isAcceptedWorkFromHome, isAcceptedEarly }

  Widget _recentSchedulesCard(List<Map> schedules, bool isDark) {
    if (schedules.isEmpty) return const SizedBox.shrink();

    return _card(
      icon: Icons.history_rounded,
      title: 'Recent records',
      isDark: isDark,
      child: Column(
        children: schedules.take(5).toList().asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;

          final date = s['date'] as String? ?? '';
          final timeIn = s['time_in'] as String? ?? '--:--';
          final rawTimeOut = s['time_out'] as String?;
          // isWorkFromHome on the Schedule row means the student logged WFH.
          // isAcceptedWorkFromHome means the supervisor approved it.
          final isWfh = (s['isWorkFromHome'] as bool? ?? false) && (s['isAcceptedWorkFromHome'] as bool? ?? false);
          final isAcceptedEarly = s['isAcceptedEarly'] as bool? ?? true;

          // Mirror server getEffectiveTimeIn logic
          final parts = timeIn.split(':');
          final totalMinutes =
              (int.tryParse(parts[0]) ?? 99) * 60 + (int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
          final displayTimeIn = (!isAcceptedEarly && totalMinutes < 8 * 60) ? '08:00:00' : timeIn;

          return Column(
            children: [
              if (i > 0) Divider(height: 12, color: ThemeManager.dividerColor(context)),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(date),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ThemeManager.primary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatTime(displayTimeIn)} → ${rawTimeOut != null ? _formatTime(rawTimeOut) : '--:--'}',
                          style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.secondary(context)),
                        ),
                      ],
                    ),
                  ),
                  if (isWfh) ...[_badge('WFH', const Color(0xFF2563EB), isDark), const SizedBox(width: 6)],
                  _badge(
                    rawTimeOut != null ? 'Done' : 'Active',
                    rawTimeOut != null ? const Color(0xFF10B981) : const Color(0xFF1B3769),
                    isDark,
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Activities card ───────────────────────────────────────────────────────

  Widget _activitiesCard(List<Map> activities, bool isDark) {
    return _card(
      icon: Icons.photo_library_outlined,
      title: 'Recent activities',
      isDark: isDark,
      child: Column(
        children: activities.take(3).toList().asMap().entries.map((e) {
          final i = e.key;
          final a = e.value;
          final desc = a['description'] as String? ?? '';
          final createdAt = a['createdAt'] as String? ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (i > 0) Divider(height: 12, color: ThemeManager.dividerColor(context)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(isDark ? 0.12 : 0.09),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.photo_camera_outlined, size: 13, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          desc.isNotEmpty ? desc : 'Activity record',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ThemeManager.primary(context),
                          ),
                        ),
                        if (createdAt.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatDateTime(createdAt),
                            style: GoogleFonts.dmSans(fontSize: 10, color: ThemeManager.muted(context)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUPERVISOR DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSupervisorDashboard(bool isDark, bool isLandscape) {
    final d = _data!;
    final office = d['office'] as Map? ?? {};
    final attendanceToday = d['attendance_today'] as Map? ?? {};
    final students = (d['students'] as List?)?.cast<Map>() ?? [];
    final recentLogs = (d['recent_logs'] as List?)?.cast<Map>() ?? [];

    final totalStudents = (attendanceToday['total_students'] as num?)?.toInt() ?? 0;
    final present = (attendanceToday['present'] as num?)?.toInt() ?? 0;
    final timedOut = (attendanceToday['timed_out'] as num?)?.toInt() ?? 0;
    final wfh = (attendanceToday['wfh'] as num?)?.toInt() ?? 0;
    final absent = (attendanceToday['absent'] as num?)?.toInt() ?? 0;
    final officeName = office['office_name'] as String? ?? 'Office';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLandscape
            ? _supervisorPcLayout(
                isDark,
                officeName,
                totalStudents,
                present,
                timedOut,
                wfh,
                absent,
                students,
                recentLogs,
              )
            : _supervisorMobileLayout(
                isDark,
                officeName,
                totalStudents,
                present,
                timedOut,
                wfh,
                absent,
                students,
                recentLogs,
              ),
      ),
    );
  }

  Widget _supervisorPcLayout(
    bool isDark,
    String officeName,
    int total,
    int present,
    int timedOut,
    int wfh,
    int absent,
    List<Map> students,
    List<Map> recentLogs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _animated(0, _supervisorBanner(officeName, isDark)),
        const SizedBox(height: 14),
        _animated(1, _attendanceStatsRow(total, present, timedOut, wfh, absent, isDark)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: _buildMissionCard(context)),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: _buildVisionCard(context)),

          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _animated(2, _studentsCard(students, isDark))),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: _animated(3, _recentLogsCard(recentLogs, isDark))),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _supervisorMobileLayout(
    bool isDark,
    String officeName,
    int total,
    int present,
    int timedOut,
    int wfh,
    int absent,
    List<Map> students,
    List<Map> recentLogs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _animated(0, _supervisorBanner(officeName, isDark)),
        const SizedBox(height: 12),
        _animated(1, _attendanceStatsRow(total, present, timedOut, wfh, absent, isDark)),
        const SizedBox(height: 10),
        _animated(2, _studentsCard(students, isDark)),
        const SizedBox(height: 10),
        _animated(3, _recentLogsCard(recentLogs, isDark)),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Supervisor banner ─────────────────────────────────────────────────────

  Widget _supervisorBanner(String officeName, bool isDark) {
    final now = DateTime.now();
    final user = _loginStore.user.value;
    final firstName = user['first_name'] as String? ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.60),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName.isNotEmpty ? firstName : 'Supervisor',
                  style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 8),
                _heroBadge(Icons.business_rounded, officeName),
                const SizedBox(height: 4),
                _heroBadge(Icons.calendar_today_rounded, DateFormat('MMMM d, yyyy').format(now)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Icon(Icons.manage_accounts_rounded, size: 28, color: Colors.white.withOpacity(0.70)),
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: Colors.white.withOpacity(0.70)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.85),
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  // ── Attendance stats row ──────────────────────────────────────────────────

  Widget _attendanceStatsRow(int total, int present, int timedOut, int wfh, int absent, bool isDark) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    if (isLandscape) {
      return Row(
        children: [
          Expanded(child: _miniStatCard(Icons.people_rounded, '$total', 'Total', const Color(0xFF1B3769), isDark)),
          const SizedBox(width: 8),
          Expanded(child: _miniStatCard(Icons.login_rounded, '$present', 'Present', const Color(0xFF10B981), isDark)),
          const SizedBox(width: 8),
          Expanded(child: _miniStatCard(Icons.logout_rounded, '$timedOut', 'Done', const Color(0xFF2563EB), isDark)),
          const SizedBox(width: 8),
          Expanded(child: _miniStatCard(Icons.home_outlined, '$wfh', 'WFH', const Color(0xFF7C3AED), isDark)),
          const SizedBox(width: 8),
          Expanded(child: _miniStatCard(Icons.event_busy_rounded, '$absent', 'Absent', Colors.red[600]!, isDark)),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _miniStatCard(Icons.people_rounded, '$total', 'Total', const Color(0xFF1B3769), isDark)),
            const SizedBox(width: 8),
            Expanded(child: _miniStatCard(Icons.login_rounded, '$present', 'Present', const Color(0xFF10B981), isDark)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _miniStatCard(Icons.logout_rounded, '$timedOut', 'Done', const Color(0xFF2563EB), isDark)),
            const SizedBox(width: 8),
            Expanded(child: _miniStatCard(Icons.home_outlined, '$wfh', 'WFH', const Color(0xFF7C3AED), isDark)),
            const SizedBox(width: 8),
            Expanded(child: _miniStatCard(Icons.event_busy_rounded, '$absent', 'Absent', Colors.red[600]!, isDark)),
          ],
        ),
      ],
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
      final initials = middleName
          .trim()
          .split(RegExp(r'\s+'))
          .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
          .join('.');
      base = '$firstName $initials. $lastName';
    } else {
      base = '$firstName $lastName';
    }
    final suffix = suffixName.trim();
    if (suffix.isNotEmpty) base = '$base, $suffix';
    final ext = extensionName?.trim();
    if (ext != null && ext.isNotEmpty) base = '$base, $ext';
    return base;
  }

  Widget _studentsCard(List<Map> students, bool isDark) {
    if (students.isEmpty) {
      return _card(
        icon: Icons.groups_rounded,
        title: 'Students',
        isDark: isDark,
        child: Center(
          child: Text(
            'No students registered',
            style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.muted(context)),
          ),
        ),
      );
    }
    return _card(
      icon: Icons.groups_rounded,
      title: 'Students overview',
      isDark: isDark,
      trailing: Text(
        '${students.length} total',
        style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context), fontWeight: FontWeight.w500),
      ),
      child: Column(
        children: students.take(8).toList().asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          final firstName = s['first_name'] as String? ?? '';
          final middleName = s['middle_name'] as String? ?? '';
          final lastName = s['last_name'] as String? ?? '';
          final suffixName = s['suffix_name'] as String? ?? '';
          final extensionName = s['extension_name'] as String? ?? '';

          // progress.js fields come back on the student object
          final rendered = (s['completed_hours'] as num?)?.toDouble() ?? 0;
          final target = (s['target_hours'] as num?)?.toDouble() ?? 1;
          final pct = (rendered / target).clamp(0.0, 1.0);
          final isDone = s['is_done'] as bool? ?? rendered >= target;
          final todaySched = s['today_schedule'] as Map?;
          final isPresent = todaySched != null;
          final progressColor = isDone ? const Color(0xFF10B981) : const Color(0xFF1B3769);

          return Column(
            children: [
              if (i > 0) Divider(height: 14, color: ThemeManager.dividerColor(context)),
              Row(
                children: [
                  _buildStudentAvatar(s, 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatFullName(firstName, middleName, lastName, suffixName, extensionName),
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeManager.primary(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPresent ? const Color(0xFF10B981) : ThemeManager.faint(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: ThemeManager.dividerColor(context),
                                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                  minHeight: 5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${rendered.toStringAsFixed(0)}h',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: progressColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Recent logs card ──────────────────────────────────────────────────────

  Widget _recentLogsCard(List<Map> logs, bool isDark) {
    if (logs.isEmpty) return const SizedBox.shrink();
    return _card(
      icon: Icons.history_rounded,
      title: 'Recent activity',
      isDark: isDark,
      child: Column(
        children: logs.take(6).toList().asMap().entries.map((e) {
          final i = e.key;
          final log = e.value;
          final type = log['log_type'] as String? ?? 'info';
          final message = log['message'] as String? ?? '';
          final createdAt = log['createdAt'] as String? ?? '';
          final logColor = _logColor(type);
          final logIcon = _logIcon(type);

          return Column(
            children: [
              if (i > 0) Divider(height: 10, color: ThemeManager.dividerColor(context)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: logColor.withOpacity(isDark ? 0.12 : 0.09),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(logIcon, size: 12, color: logColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: ThemeManager.primary(context),
                          ),
                        ),
                        if (createdAt.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            _formatDateTime(createdAt),
                            style: GoogleFonts.dmSans(fontSize: 10, color: ThemeManager.muted(context)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStudentAvatar(Map student, double size) {
    final String? profileLink = student['profile_link'] ?? student['profileLink'];
    final String firstName = student['first_name'] as String? ?? '';
    final String lastName = student['last_name'] as String? ?? '';
    final String initials = (firstName.isNotEmpty ? firstName[0] : '') + (lastName.isNotEmpty ? lastName[0] : '');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1B3769).withOpacity(0.12)),
      child: ClipOval(
        child: profileLink != null && profileLink.isNotEmpty
            ? Image.network(
                profileLink,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitialsAvatar(initials, size),
              )
            : _buildInitialsAvatar(initials, size),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, double size) {
    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials.toUpperCase(),
        style: GoogleFonts.dmSans(fontSize: size * 0.4, fontWeight: FontWeight.w700, color: const Color(0xFF1B3769)),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required bool isDark,
    required Widget child,
    Widget? trailing,
  }) {
    final iconColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeManager.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeManager.border(context)),
        boxShadow: isDark ? null : [const BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager.primary(context),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          Divider(height: 20, color: ThemeManager.dividerColor(context)),
          child,
        ],
      ),
    );
  }

  Widget _badge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.09),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Color _logColor(String type) {
    switch (type) {
      case 'timeIn':
        return const Color(0xFF10B981);
      case 'timeOut':
        return const Color(0xFFFF4E0B);
      case 'create':
        return const Color(0xFF2563EB);
      case 'update':
        return const Color(0xFF7C3AED);
      case 'delete':
        return const Color(0xFFDC2626);
      case 'sync':
        return const Color(0xFF0891B2);
      case 'error':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _logIcon(String type) {
    switch (type) {
      case 'timeIn':
        return Icons.login_rounded;
      case 'timeOut':
        return Icons.logout_rounded;
      case 'create':
        return Icons.add_circle_rounded;
      case 'update':
        return Icons.edit_rounded;
      case 'delete':
        return Icons.delete_rounded;
      case 'sync':
        return Icons.sync_rounded;
      case 'error':
        return Icons.error_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final period = h >= 12 ? 'PM' : 'AM';
      final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$hour:$m $period';
    } catch (_) {
      return time;
    }
  }

  String _formatDate(String date) {
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  String _formatDateTime(String dt) {
    try {
      return DateFormat('MMM d  h:mm a').format(DateTime.parse(dt).toLocal());
    } catch (_) {
      return dt;
    }
  }

  Widget _buildVisionCard(BuildContext context) {
    return card(
      context,
      icon: Icons.visibility_outlined,
      iconColor: const Color(0xFF7C3AED),
      title: 'Vision',
      child: Text(
        _loginStore.user.value['office_vision'] as String? ?? '',
        style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.bodyColor(context), height: 1.65),
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context) {
    return card(
      context,
      icon: Icons.flag_outlined,
      iconColor: const Color(0xFFDB2777),
      title: 'Mission',
      child: Text(
        _loginStore.user.value['office_mission'] as String? ?? '',
        style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.bodyColor(context), height: 1.65),
      ),
    );
  }
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
