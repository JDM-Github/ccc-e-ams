import 'package:ccc_ojt_schedule/components/super_admin/shared_widgets.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ── Static dark tokens (matches ThemeManager dark statics + AboutPage hero) ──
const Color _border = Color(0x332D5299);
const Color _divider = Color(0x262D5299);
const Color _textPrimary = Color(0xE6FFFFFF);
const Color _textSecondary = Color(0x80FFFFFF);
const Color _textMuted = Color(0x66FFFFFF);
const Color _textFaint = Color(0x33FFFFFF);
const Color _brand = Color(0xFF1B3769);
const Color _accentBlue = Color(0xFF60A5FA);
const Color _accentGreen = Color(0xFF34D399);
const Color _accentAmber = Color(0xFFFBBF24);
const Color _accentPurple = Color(0xFFA78BFA);
const Color _accentRed = Color(0xFFF87171);
const Color _accentCyan = Color(0xFF22D3EE);
const Color _accentOrange = Color(0xFFFB923C);

class SADashboardPanel extends StatefulWidget {
  final List<Map<String, dynamic>> offices;
  const SADashboardPanel({super.key, required this.offices});

  @override
  State<SADashboardPanel> createState() => _SADashboardPanelState();
}

class _SADashboardPanelState extends State<SADashboardPanel> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await RequestHandler().handleRequest('dashboard/superadmin', method: 'GET');
      if (mounted) setState(() => _data = r);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) return _buildLoading();
    if (_error != null || _data == null) return _buildError();

    final d = _data!;
    final officesData = d['offices'] as Map? ?? {};
    final usersData = d['users'] as Map? ?? {};
    final ojt = d['ojt_platform'] as Map? ?? {};
    final today = d['attendance_today'] as Map? ?? {};
    final keysData = d['special_keys'] as Map? ?? {};
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return RefreshIndicator(
      onRefresh: _load,
      color: Colors.white,
      backgroundColor: _brand,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SAStaggerItem(index: 0, child: _buildHero()),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats grid ─────────────────────────────────────
                  _buildStatsGrid(officesData, usersData, ojt, today, keysData, isLandscape),
                  const SizedBox(height: 16),

                  // ── Summary strip ──────────────────────────────────
                  SAStaggerItem(
                    index: 5,
                    child: _buildSummaryStrip(
                      totalStudents: _toInt(usersData['active_students']),
                      totalHours: _toInt(ojt['total_target_hours']),
                      completedEntries: _toInt(ojt['completed_schedule_entries']),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _accentBlue, strokeWidth: 2),
          const SizedBox(height: 14),
          Text('Loading dashboard…', style: GoogleFonts.dmSans(fontSize: 12, color: _textMuted)),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _accentBlue.withOpacity(0.06), shape: BoxShape.circle),
            child: Icon(Icons.wifi_off_rounded, size: 36, color: _textFaint),
          ),
          const SizedBox(height: 14),
          Text('Failed to load dashboard', style: GoogleFonts.dmSans(fontSize: 13, color: _textSecondary)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: _accentBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accentBlue.withOpacity(0.25)),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: _accentBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero — matches AboutPage hero exactly ─────────────────────────────────

  Widget _buildHero() {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF080C14), Color(0xFF0F1E3C), Color(0xFF1B3769)],
        ),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Logo box — same style as AboutPage
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Image.asset('assets/ccc_icon.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUPER ADMIN',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.40),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Platform Overview',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _heroBadge(Icons.calendar_today_rounded, DateFormat('EEEE, MMM d').format(now)),
                    _heroBadge(Icons.business_rounded, '${widget.offices.length} offices'),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Icon(Icons.refresh_rounded, size: 15, color: Colors.white.withOpacity(0.50)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: Colors.white.withOpacity(0.70)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  // ── Stats grid ────────────────────────────────────────────────────────────

  Widget _buildStatsGrid(Map offices, Map users, Map ojt, Map today, Map keys, bool isLandscape) {
    final stats = [
      _StatData(
        icon: Icons.business_rounded,
        color: _accentBlue,
        label: 'Offices',
        value: '${_toInt(offices['total'])}',
        sub: '${_toInt(offices['active'])} active',
        subColor: _accentGreen,
      ),
      _StatData(
        icon: Icons.groups_rounded,
        color: _accentGreen,
        label: 'Active students',
        value: '${_toInt(users['active_students'])}',
        sub: '${_toInt(users['active_supervisors'])} supervisors',
      ),
      _StatData(
        icon: Icons.timer_outlined,
        color: _accentAmber,
        label: 'Target hours',
        value: _fmtHours(_toInt(ojt['total_target_hours'])),
        sub: '${_toInt(ojt['total_student_count'])} students',
      ),
      _StatData(
        icon: Icons.check_circle_outline_rounded,
        color: _accentGreen,
        label: 'Completed entries',
        value: '${_toInt(ojt['completed_schedule_entries'])}',
        sub: 'all-time records',
      ),
      _StatData(
        icon: Icons.login_rounded,
        color: _accentCyan,
        label: 'Timed in today',
        value: '${_toInt(today['timed_in'])}',
        sub: '${_toInt(today['wfh'])} WFH',
      ),
      _StatData(
        icon: Icons.logout_rounded,
        color: _accentRed,
        label: 'Timed out today',
        value: '${_toInt(today['timed_out'])}',
        sub: 'completed today',
      ),
      _StatData(
        icon: Icons.vpn_key_rounded,
        color: _accentPurple,
        label: 'Active keys',
        value: '${_toInt(keys['active'])}',
        sub: '${_toInt(keys['expired'])} expired',
      ),
      _StatData(
        icon: Icons.pending_outlined,
        color: _accentOrange,
        label: 'Pending deletion',
        value: '${_toInt(users['pending_deletion'])}',
        sub: 'user accounts',
      ),
    ];

    final cols = isLandscape ? 4 : 2;
    final rows = <Widget>[];

    for (int i = 0; i < stats.length; i += cols) {
      final slice = stats.sublist(i, (i + cols).clamp(0, stats.length));
      rows.add(
        SAStaggerItem(
          index: i ~/ cols + 1,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: slice.asMap().entries.map((e) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: e.key == 0 ? 0 : 10),
                    child: _StatCard(stat: e.value),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  static String _fmtHours(int h) => h >= 1000 ? '${(h / 1000).toStringAsFixed(1)}k' : '$h';

  // ── Summary strip — matches AboutPage card style ──────────────────────────

  Widget _buildSummaryStrip({required int totalStudents, required int totalHours, required int completedEntries}) {
    final avg = totalStudents > 0 ? (totalHours / totalStudents).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x14162B4C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x301B3769), Color(0x14080C14)],
        ),
      ),
      child: Row(
        children: [
          _summaryCell(Icons.speed_rounded, _accentBlue, '$avg hrs', 'Avg target'),
          _summaryDivider(),
          _summaryCell(Icons.people_rounded, _accentGreen, '$totalStudents', 'Total students'),
          _summaryDivider(),
          _summaryCell(Icons.receipt_long_rounded, _accentAmber, '$completedEntries', 'Records'),
        ],
      ),
    );
  }

  Widget _summaryCell(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color.withOpacity(0.65)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w800, color: _textPrimary),
              ),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.dmSans(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: _textFaint,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() =>
      Container(width: 1, height: 30, color: _divider, margin: const EdgeInsets.symmetric(horizontal: 6));
}

// ── Stat data model ───────────────────────────────────────────────────────────

class _StatData {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? sub;
  final Color? subColor;

  const _StatData({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.sub,
    this.subColor,
  });
}

// ── Stat card — matches AboutPage _featureRow card shell ─────────────────────

class _StatCard extends StatelessWidget {
  final _StatData stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332D5299)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: stat.color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(stat.icon, size: 14, color: stat.color),
              ),
              const Spacer(),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(shape: BoxShape.circle, color: stat.color.withOpacity(0.45)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            stat.value,
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xE6FFFFFF),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            stat.label,
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0x80FFFFFF)),
          ),
          if (stat.sub != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: (stat.subColor ?? Colors.white).withOpacity(0.08),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: (stat.subColor ?? Colors.white).withOpacity(0.12)),
              ),
              child: Text(
                stat.sub!,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: stat.subColor ?? const Color(0x66FFFFFF),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
