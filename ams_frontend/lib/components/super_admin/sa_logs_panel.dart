import 'package:ccc_ojt_schedule/components/super_admin/shared_widgets.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SALogsPanel extends StatefulWidget {
  const SALogsPanel({super.key});

  @override
  State<SALogsPanel> createState() => _SALogsPanelState();
}

class _SALogsPanelState extends State<SALogsPanel> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String? _error;
  String _search = '';

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
      final r = await RequestHandler().handleRequest('super-admin/superadmin-logs', method: 'GET');
      if (mounted) {
        if (r['logs'] != null) {
          setState(() => _logs = List<Map<String, dynamic>>.from(r['logs']));
        } else {
          setState(() => _error = r['message'] ?? 'Failed to load logs.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _logs;
    final q = _search.toLowerCase();
    return _logs.where((l) {
      final action = (l['action'] ?? '').toString().toLowerCase();
      final details = (l['details'] ?? l['message'] ?? '').toString().toLowerCase();
      return action.contains(q) || details.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        _buildToolbar(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: saSurface,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: saBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: saBlue.withOpacity(0.25)),
            ),
            child: Text(
              '${_filtered.length} logs',
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: saBlue),
            ),
          ),
          const SizedBox(width: 10),
          // Search
          Expanded(
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.09)),
              ),
              child: TextField(
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.28), size: 15),
                  hintText: 'Filter logs…',
                  hintStyle: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.22), fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Refresh
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.09)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: saBlue),
                    )
                  : Icon(Icons.refresh_rounded, size: 15, color: Colors.white.withOpacity(0.40)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: saBlue));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 36, color: Colors.red.withOpacity(0.35)),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.30)),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: saBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: saBlue.withOpacity(0.28)),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: saBlue),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _filtered;
    if (filtered.isEmpty) {
      return saEmpty(Icons.history_outlined, _search.isEmpty ? 'No logs yet' : 'No matching logs');
    }

    return SAStaggerList(children: filtered.map((l) => _LogCard(log: l)).toList());
  }
}

// ─── Log card ──────────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _LogCard({required this.log});

  Color _actionColor(String? action) {
    if (action == null) return Colors.white.withOpacity(0.35);
    final a = action.toLowerCase();
    if (a.contains('delete') || a.contains('remove') || a.contains('deactivate')) return const Color(0xFFF87171);
    if (a.contains('create') || a.contains('add') || a.contains('restore')) return const Color(0xFF4ADE80);
    if (a.contains('update') || a.contains('change') || a.contains('advance')) return const Color(0xFFFBBF24);
    if (a.contains('login') || a.contains('auth')) return saBlue;
    return Colors.white.withOpacity(0.45);
  }

  IconData _actionIcon(String? action) {
    if (action == null) return Icons.history_outlined;
    final a = action.toLowerCase();
    if (a.contains('delete') || a.contains('remove')) return Icons.delete_outline_rounded;
    if (a.contains('deactivate')) return Icons.block_rounded;
    if (a.contains('create')) return Icons.add_circle_outline_rounded;
    if (a.contains('restore')) return Icons.upload_rounded;
    if (a.contains('backup')) return Icons.download_rounded;
    if (a.contains('advance')) return Icons.arrow_circle_up_outlined;
    if (a.contains('update') || a.contains('change')) return Icons.edit_outlined;
    if (a.contains('login')) return Icons.login_rounded;
    return Icons.history_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final action = log['action'] as String?;
    final details = (log['details'] ?? log['message'] ?? '') as String;
    final username = log['username'] as String?;
    final color = _actionColor(action);
    final icon = _actionIcon(action);

    final createdAt = log['createdAt'] != null ? DateTime.tryParse(log['createdAt'].toString()) : null;
    final dateStr = createdAt != null ? DateFormat('MMM d, yyyy').format(createdAt) : '';
    final timeStr = createdAt != null
        ? DateFormat('hh:mm:ss a').format(createdAt.toUtc().add(const Duration(hours: 8)))
        : '';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: saCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action label + username
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        action ?? 'ACTION',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (username != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '— $username',
                        style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withOpacity(0.32)),
                      ),
                    ],
                  ],
                ),

                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.55), height: 1.45),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Timestamp
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(dateStr, style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withOpacity(0.25))),
              Text(
                timeStr,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
