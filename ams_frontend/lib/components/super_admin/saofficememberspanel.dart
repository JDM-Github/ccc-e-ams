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

  // ── loading states ─────────────────────────────────────────────────────────
  bool _loadingAY = true; // fetching available AYs
  bool _loadingMembers = true; // fetching members
  String? _error;
  String _search = '';

  // ── AY filter ──────────────────────────────────────────────────────────────
  /// Raw list from /available-ay: [{ ay: 2025, label: "2025-2026" }, ...]
  List<Map<String, dynamic>> _availableAY = [];

  /// Currently selected ay value (int). null → "All AY" (no filter)
  int? _selectedAY;

  // ── member data ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _supervisors = [];
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _members = [];

  // ── combined loading guard ─────────────────────────────────────────────────
  bool get _loading => _loadingAY || _loadingMembers;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadAY(); // fetch AYs first
    _loadMembers(); // members can load in parallel
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── data fetchers ──────────────────────────────────────────────────────────

  Future<void> _loadAY() async {
    if (!mounted) return;
    setState(() => _loadingAY = true);
    try {
      final officeId = widget.office['office_id'];
      final r = await RequestHandler().handleRequest(
        'super-admin/office-members/$officeId/available-ay',
        method: 'GET',
      );
      if (mounted) {
        setState(() {
          _availableAY = List<Map<String, dynamic>>.from(r['available_ay'] ?? []);
        });
      }
    } catch (_) {
      // Non-fatal — AY filter just won't populate
    } finally {
      if (mounted) setState(() => _loadingAY = false);
    }
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;
    setState(() {
      _loadingMembers = true;
      _error = null;
    });
    try {
      final officeId = widget.office['office_id'];
      final query = _selectedAY != null ? '?ay=$_selectedAY' : '';
      final r = await RequestHandler().handleRequest('super-admin/office-members/$officeId$query', method: 'GET');
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
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  /// Reload everything (called by refresh button)
  Future<void> _reload() async {
    await Future.wait([_loadAY(), _loadMembers()]);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _fullNameExtended(Map<String, dynamic> u) {
    final firstName = (u['first_name'] as String? ?? '').trim();
    final lastName = (u['last_name'] as String? ?? '').trim();
    final middleName = (u['middle_name'] as String? ?? '').trim();
    final suffix = (u['suffix_name'] as String? ?? '').trim();
    final extension = (u['extension_name'] as String? ?? '').trim();

    String base;
    if (middleName.isNotEmpty) {
      final initials = middleName.split(RegExp(r'\s+')).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join('.');
      base = '$firstName $initials. $lastName';
    } else {
      base = '$firstName $lastName';
    }
    if (suffix.isNotEmpty) base = '$base, $suffix';
    if (extension.isNotEmpty) base = '$base, $extension';
    return base;
  }

  String _initials(Map<String, dynamic> u) {
    final f = (u['first_name'] as String? ?? '').isNotEmpty ? (u['first_name'] as String)[0] : '';
    final l = (u['last_name'] as String? ?? '').isNotEmpty ? (u['last_name'] as String)[0] : '';
    return '$f$l'.toUpperCase();
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> list) {
    if (_search.isEmpty) return list;
    final q = _search.toLowerCase();
    return list.where((u) {
      final name = _fullNameExtended(u).toLowerCase();
      final id = (u['ccc_id'] as String? ?? '').toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  // ── small widgets ──────────────────────────────────────────────────────────

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

  Widget _avatar(Map<String, dynamic> u, Color bg, Color fg) {
    final profileLink = u['profile_link'] as String?;
    final hasImage = profileLink != null && profileLink.isNotEmpty;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: fg.withOpacity(0.20)),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(profileLink, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initialsAvatar(u, fg))
            : _initialsAvatar(u, fg),
      ),
    );
  }

  Widget _initialsAvatar(Map<String, dynamic> u, Color fg) => Center(
    child: Text(
      _initials(u),
      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
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

  // ── AY selector ────────────────────────────────────────────────────────────

  Widget _aySelector() {
    if (_loadingAY) {
      return Container(
        height: 34,
        width: 130,
        decoration: BoxDecoration(
          color: _surfaceTint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderDim),
        ),
        child: Center(
          child: SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 1.6, color: _blue.withOpacity(0.5)),
          ),
        ),
      );
    }

    final items = <DropdownMenuItem<int?>>[
      DropdownMenuItem<int?>(
        value: null,
        child: Text('All AY', style: GoogleFonts.dmSans(fontSize: 12, color: _textSec)),
      ),
      ..._availableAY.map(
        (ay) => DropdownMenuItem<int?>(
          value: ay['ay'] as int,
          child: Text(
            ay['label'] as String,
            style: GoogleFonts.dmSans(fontSize: 12, color: _textPri, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ];

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _surfaceTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _selectedAY != null ? _blue.withOpacity(0.40) : _borderDim),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedAY,
          items: items,
          dropdownColor: _surface,
          icon: Icon(Icons.expand_more_rounded, size: 15, color: _selectedAY != null ? _blue : _textMut),
          style: GoogleFonts.dmSans(fontSize: 12, color: _textPri),
          isDense: true,
          onChanged: (val) {
            if (val == _selectedAY) return;
            setState(() => _selectedAY = val);
            _loadMembers();
          },
        ),
      ),
    );
  }

  // ── actions ────────────────────────────────────────────────────────────────

  void _openEditDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
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
    final name = _fullNameExtended(user);
    final cccId = user['ccc_id'] as String;

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
          await _loadMembers();
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

  // Future<void> _permanentDeleteMember(Map<String, dynamic> user) async {
  //   final name = _fullNameExtended(user);
  //   final cccId = user['ccc_id'] as String;

  //   final ok = await showDialog<bool>(
  //     context: context,
  //     barrierColor: Colors.black.withOpacity(0.65),
  //     builder: (ctx) => Center(
  //       child: Container(
  //         width: 480,
  //         margin: const EdgeInsets.symmetric(horizontal: 24),
  //         padding: const EdgeInsets.all(20),
  //         decoration: BoxDecoration(
  //           color: const Color(0xFF111827),
  //           borderRadius: BorderRadius.circular(14),
  //           border: Border.all(color: const Color(0x4D2D5299)),
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.all(8),
  //                   decoration: BoxDecoration(color: _red.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
  //                   child: const Icon(Icons.delete_forever_rounded, size: 16, color: _red),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 Expanded(
  //                   child: Text(
  //                     'Permanently delete $name?',
  //                     style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: _textPri),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 12),
  //             Text(
  //               'This action is irreversible. The member and all associated records will be removed from the system.',
  //               style: GoogleFonts.dmSans(fontSize: 12, color: _textSec),
  //             ),
  //             const SizedBox(height: 16),
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: OutlinedButton(
  //                     onPressed: () => Navigator.pop(ctx, false),
  //                     style: OutlinedButton.styleFrom(
  //                       side: BorderSide(color: _borderMed),
  //                       foregroundColor: _textSec,
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //                     ),
  //                     child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 12)),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Expanded(
  //                   child: ElevatedButton(
  //                     onPressed: () => Navigator.pop(ctx, true),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: _red,
  //                       foregroundColor: Colors.white,
  //                       elevation: 0,
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //                     ),
  //                     child: Text(
  //                       'Delete Permanently',
  //                       style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );

  //   if (ok != true || !mounted) return;

  //   AppSnackBar.loading(context, 'Permanently deleting $name…', id: 'perm_delete_$cccId');
  //   try {
  //     final r = await RequestHandler().handleRequest(
  //       'super-admin/permanent-delete-member',
  //       method: 'POST',
  //       body: {'ccc_id': cccId},
  //     );
  //     if (mounted) {
  //       AppSnackBar.hide(context, id: 'perm_delete_$cccId');
  //       if (r['success'] == true) {
  //         AppSnackBar.success(context, r['message'] ?? '$name permanently deleted.');
  //         // Remove the member from all lists
  //         setState(() {
  //           _supervisors.removeWhere((u) => u['ccc_id'] == cccId);
  //           _admins.removeWhere((u) => u['ccc_id'] == cccId);
  //           _members.removeWhere((u) => u['ccc_id'] == cccId);
  //         });
  //       } else {
  //         AppSnackBar.error(context, r['message'] ?? 'Permanent delete failed.');
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       AppSnackBar.hide(context, id: 'perm_delete_$cccId');
  //       AppSnackBar.error(context, 'Error: $e');
  //     }
  //   }
  // }

  // ── member row ─────────────────────────────────────────────────────────────

  Widget _memberRow(
    Map<String, dynamic> user, {
    required Color avatarBg,
    required Color avatarFg,
    required String roleLabel,
  }) {
    final status = user['status'] as String? ?? 'active';
    final isDeleted = status == 'deleted';
    final ay = user['current_sy'] as int?;

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
                  _fullNameExtended(user),
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
                    if (ay != null) ...[
                      Text(' · ', style: GoogleFonts.dmSans(fontSize: 10, color: _textHint)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: avatarFg.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: avatarFg.withOpacity(0.20)),
                        ),
                        child: Text(
                          'AY $ay-${ay + 1}',
                          style: GoogleFonts.dmMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: avatarFg.withOpacity(0.75),
                          ),
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
            // _iconBtn(
            //   label: 'Permanent Delete',
            //   color: _red,
            //   icon: Icons.delete_forever_rounded,
            //   onTap: () => _permanentDeleteMember(user),
            // ),
            // const SizedBox(width: 5),
          ],
          _iconBtn(label: 'Edit', color: _blue, icon: Icons.edit_rounded, onTap: () => _openEditDialog(user)),
        ],
      ),
    );
  }

  Widget _tabBody(
    List<Map<String, dynamic>> raw, {
    required Color avatarBg,
    required Color avatarFg,
    required String roleLabel,
    required String emptyLabel,
  }) {
    final list = _filtered(raw);
    if (list.isEmpty) return saEmpty(Icons.people_outline_rounded, 'No $emptyLabel found');
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
          // ── Header ────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: _surface,
              border: Border(bottom: BorderSide(color: _divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                      // Office info row
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
                              onPressed: _loading ? null : _reload,
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

                      if (!_loading && _error == null) ...[
                        const SizedBox(height: 12),

                        // Count chips + AY selector on same row
                        Row(
                          children: [
                            _countChip('supervisors', _supervisors.length, _purple),
                            const SizedBox(width: 7),
                            _countChip('admins', _admins.length, _blue),
                            const SizedBox(width: 7),
                            _countChip('members', _members.length, _green),
                            const Spacer(),
                            _aySelector(),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Search row — with active AY label if filter is on
                        Row(
                          children: [
                            Expanded(child: _searchField()),
                            if (_selectedAY != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _selectedAY = null);
                                  _loadMembers();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _blue.withOpacity(0.09),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _blue.withOpacity(0.25)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'AY $_selectedAY-${_selectedAY! + 1}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _blue,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Icon(Icons.close_rounded, size: 12, color: _blue.withOpacity(0.70)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
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

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: _loadingMembers
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
