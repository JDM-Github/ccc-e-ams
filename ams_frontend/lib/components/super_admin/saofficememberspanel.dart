// Author: JDM

import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/super_admin/edit_member_dialog.dart';
import 'package:ccc_ojt_schedule/components/super_admin/shared_widgets.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens — aligned with ThemeManager dark palette ───────────────────
const Color _bgBase = Color(0xFF0A0A0F);
const Color _surface = Color(0xFF111827);
const Color _surfaceCard = Color(0x14162B4C);
const Color _surfaceTint = Color(0x1A1B3769);
const Color _borderDim = Color(0x1A2D5299);
const Color _borderMed = Color(0x332D5299);
const Color _divider = Color(0x262D5299);

const Color _blue = Color(0xFF60A5FA);
const Color _green = Color(0xFF34D399);
const Color _greenDim = Color(0x1A34D399);
const Color _purple = Color(0xFFA78BFA);
const Color _amber = Color(0xFFFBBF24);
const Color _red = Color(0xFFFC8181);
const Color _redDim = Color(0x1AFC8181);

const Color _textPri = Color(0xE6FFFFFF);
const Color _textSec = Color(0x80FFFFFF);
const Color _textMut = Color(0x66FFFFFF);
const Color _textHint = Color(0x59FFFFFF);

class SAOfficeMembersPanel extends StatefulWidget {
  final Map<String, dynamic> office;
  final VoidCallback onBack;

  const SAOfficeMembersPanel({super.key, required this.office, required this.onBack});

  @override
  State<SAOfficeMembersPanel> createState() => _SAOfficeMembersPanelState();
}

class _SAOfficeMembersPanelState extends State<SAOfficeMembersPanel> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;
  String? _error;
  String _search = '';

  List<Map<String, dynamic>> _supervisors = [];
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final officeId = widget.office['office_id'];
      final r = await RequestHandler().handleRequest('super-admin/office-members/$officeId', method: 'GET');
      if (mounted) {
        setState(() {
          _supervisors = List<Map<String, dynamic>>.from(r['supervisors'] ?? []);
          _admins = List<Map<String, dynamic>>.from(r['admins'] ?? []);
          _members = List<Map<String, dynamic>>.from(r['members'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _initials(Map<String, dynamic> u) {
    final f = (u['first_name'] as String? ?? '').isNotEmpty ? (u['first_name'] as String)[0] : '';
    final l = (u['last_name'] as String? ?? '').isNotEmpty ? (u['last_name'] as String)[0] : '';
    return '$f$l'.toUpperCase();
  }

  String _fullName(Map<String, dynamic> u) => '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> list) {
    if (_search.isEmpty) return list;
    final q = _search.toLowerCase();
    return list
        .where(
          (u) => _fullName(u).toLowerCase().contains(q) || (u['ccc_id'] as String? ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  // ── small components ───────────────────────────────────────────────────────

  Widget _statusBadge(String? status) {
    switch (status) {
      case 'active':
        return _pill('Active', _green, _greenDim);
      case 'pending_for_delete':
        return _pill('Pending', _amber, const Color(0x1AFBBF24));
      case 'deleted':
        return _pill('Deleted', _red, _redDim);
      default:
        return _pill(status ?? '—', _textSec, _borderDim);
    }
  }

  Widget _pill(String label, Color text, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: text.withOpacity(0.22)),
    ),
    child: Text(
      label.toUpperCase(),
      style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: text),
    ),
  );

  Widget _avatar(Map<String, dynamic> u, Color bg, Color fg) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: bg,
      border: Border.all(color: fg.withOpacity(0.20)),
    ),
    child: Center(
      child: Text(
        _initials(u),
        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    ),
  );

  Widget _iconBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
    bool loading = false,
  }) => GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedOpacity(
      opacity: loading ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: loading
            ? SizedBox(width: 11, height: 11, child: CircularProgressIndicator(strokeWidth: 1.6, color: color))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 11, color: color), const SizedBox(width: 4)],
                  Text(
                    label,
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),
      ),
    ),
  );

  // ── actions ───────────────────────────────────────────────────────────────

  void _openEditDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      // ── FIX: use dialogContext instead of capturing the outer context ──
      builder: (dialogContext) => EditMemberDialog(
        user: user,
        onSaved: (updated) {
          if (!mounted) return;
          setState(() {
            for (final list in [_supervisors, _admins, _members]) {
              final idx = list.indexWhere((u) => u['ccc_id'] == updated['ccc_id']);
              if (idx != -1) {
                list[idx] = updated;
                break;
              }
            }
          });
          AppSnackBar.success(context, 'Member updated.');
        },
      ),
    );
  }

  Future<void> _restoreMember(Map<String, dynamic> user) async {
    final name = _fullName(user);
    final cccId = user['ccc_id'] as String;

    // Confirm
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => Center(
        child: Container(
          width: 340,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x4D2D5299)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _green.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.restore_rounded, size: 16, color: _green),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Restore member?',
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: _textPri),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$name will be restored to active status.',
                style: GoogleFonts.dmSans(fontSize: 12, color: _textSec),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _borderMed),
                        foregroundColor: _textSec,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Restore', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true || !mounted) return;

    AppSnackBar.loading(context, 'Restoring $name…', id: 'restore_$cccId');
    try {
      final r = await RequestHandler().handleRequest(
        'super-admin/restore-member',
        method: 'POST',
        body: {'ccc_id': cccId},
      );
      if (mounted) {
        AppSnackBar.hide(context, id: 'restore_$cccId');
        if (r['success'] == true) {
          AppSnackBar.success(context, r['message'] ?? '$name restored.');
          await _load();
        } else {
          AppSnackBar.error(context, r['message'] ?? 'Restore failed.');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.hide(context, id: 'restore_$cccId');
        AppSnackBar.error(context, 'Error: $e');
      }
    }
  }

  // ── member row ─────────────────────────────────────────────────────────────

  Widget _memberRow(
    Map<String, dynamic> user, {
    required Color avatarBg,
    required Color avatarFg,
    required String roleLabel,
  }) {
    final status = user['status'] as String? ?? 'active';
    final isDeleted = status == 'deleted';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDeleted ? _redDim : _surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDeleted ? _red.withOpacity(0.18) : _borderDim),
      ),
      child: Row(
        children: [
          _avatar(user, avatarBg, avatarFg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName(user),
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDeleted ? _red.withOpacity(0.70) : _textPri,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(user['ccc_id'] ?? '', style: GoogleFonts.dmMono(fontSize: 10, color: _textMut)),
                    if ((user['course'] as String? ?? '').isNotEmpty) ...[
                      Text(' · ', style: GoogleFonts.dmSans(fontSize: 10, color: _textHint)),
                      Flexible(
                        child: Text(
                          user['course'] as String,
                          style: GoogleFonts.dmSans(fontSize: 10, color: _textMut),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _statusBadge(status),
          const SizedBox(width: 6),
          if (isDeleted) ...[
            _iconBtn(label: 'Restore', color: _green, icon: Icons.restore_rounded, onTap: () => _restoreMember(user)),
            const SizedBox(width: 5),
          ],
          _iconBtn(label: 'Edit', color: _blue, icon: Icons.edit_rounded, onTap: () => _openEditDialog(user)),
        ],
      ),
    );
  }

  // ── section / tab body ────────────────────────────────────────────────────

  Widget _tabBody(
    List<Map<String, dynamic>> raw, {
    required Color avatarBg,
    required Color avatarFg,
    required String roleLabel,
    required String emptyLabel,
  }) {
    final list = _filtered(raw);
    if (list.isEmpty) {
      return saEmpty(Icons.people_outline_rounded, 'No $emptyLabel found');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
      itemCount: list.length,
      itemBuilder: (_, i) => _memberRow(list[i], avatarBg: avatarBg, avatarFg: avatarFg, roleLabel: roleLabel),
    );
  }

  // ── count chip ─────────────────────────────────────────────────────────────

  Widget _countChip(String label, int count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.09),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.20)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w800, color: color, height: 1.0),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: color.withOpacity(0.65)),
        ),
      ],
    ),
  );

  // ── search field ───────────────────────────────────────────────────────────

  Widget _searchField() => Container(
    height: 34,
    decoration: BoxDecoration(
      color: _surfaceTint,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _borderDim),
    ),
    child: TextField(
      style: GoogleFonts.dmSans(fontSize: 13, color: _textPri),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search_rounded, color: _textMut, size: 16),
        hintText: 'Search by name or ID…',
        hintStyle: GoogleFonts.dmSans(fontSize: 13, color: _textHint),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      onChanged: (v) => setState(() => _search = v),
    ),
  );

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final officeName = widget.office['office_name'] as String? ?? 'Office';
    final officeId = widget.office['office_id'] as String? ?? '';
    final isDeact = widget.office['deactivated'] == true;

    return Scaffold(
      backgroundColor: _bgBase,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: _surface,
              border: Border(bottom: BorderSide(color: _divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + title row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_new_rounded, size: 11, color: _blue.withOpacity(0.65)),
                            const SizedBox(width: 4),
                            Text(
                              'Offices',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: _blue.withOpacity(0.65),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Office info
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: isDeact ? _red.withOpacity(0.12) : const Color(0xFF1B3769).withOpacity(0.30),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDeact ? _red.withOpacity(0.22) : _borderMed),
                            ),
                            child: Icon(
                              isDeact ? Icons.business_outlined : Icons.business_rounded,
                              size: 16,
                              color: isDeact ? _red : _blue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  officeName,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDeact ? _red.withOpacity(0.80) : _textPri,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(officeId, style: GoogleFonts.dmMono(fontSize: 10, color: _textMut)),
                              ],
                            ),
                          ),
                          _pill(
                            isDeact ? 'Deactivated' : 'Active',
                            isDeact ? _red : _green,
                            isDeact ? _redDim : _greenDim,
                          ),
                          const SizedBox(width: 6),
                          // Refresh
                          SizedBox(
                            height: 32,
                            width: 32,
                            child: OutlinedButton(
                              onPressed: _loading ? null : _load,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                side: BorderSide(color: _borderMed),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _loading
                                  ? SizedBox(
                                      width: 13,
                                      height: 13,
                                      child: CircularProgressIndicator(strokeWidth: 1.8, color: _blue),
                                    )
                                  : Icon(Icons.refresh_rounded, size: 15, color: _textSec),
                            ),
                          ),
                        ],
                      ),

                      // Count chips + search
                      if (!_loading && _error == null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _countChip('supervisors', _supervisors.length, _purple),
                            const SizedBox(width: 7),
                            _countChip('admins', _admins.length, _blue),
                            const SizedBox(width: 7),
                            _countChip('members', _members.length, _green),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _searchField(),
                      ],
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                // Tab bar
                TabBar(
                  controller: _tabs,
                  indicatorColor: _blue,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2,
                  labelColor: _blue,
                  unselectedLabelColor: _textSec,
                  labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
                  dividerColor: _divider,
                  tabs: [
                    _tab('Supervisors', _supervisors.length, _purple),
                    _tab('Admins', _admins.length, _blue),
                    _tab('Members', _members.length, _green),
                  ],
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2))
                : _error != null
                ? saEmpty(Icons.wifi_off_rounded, 'Failed to load members')
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _tabBody(
                        _supervisors,
                        avatarBg: _purple.withOpacity(0.14),
                        avatarFg: _purple,
                        roleLabel: 'Supervisor',
                        emptyLabel: 'supervisors',
                      ),
                      _tabBody(
                        _admins,
                        avatarBg: _blue.withOpacity(0.14),
                        avatarFg: _blue,
                        roleLabel: 'Admin',
                        emptyLabel: 'admins',
                      ),
                      _tabBody(
                        _members,
                        avatarBg: _green.withOpacity(0.14),
                        avatarFg: _green,
                        roleLabel: 'Student',
                        emptyLabel: 'members',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, int count, Color color) => Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Text(
            '$count',
            style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    ),
  );
}
