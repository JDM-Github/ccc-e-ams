// Author: JDM

import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/super_admin/shared_widgets.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ── Design tokens — aligned with ThemeManager dark palette ───────────────────
const Color _bgBase = Color(0xFF0A0A0F);
const Color _surface = Color(0xFF111827);
const Color _surfaceCard = Color(0x14162B4C);
const Color _borderDim = Color(0x1A2D5299);
const Color _borderMed = Color(0x332D5299);
const Color _divider = Color(0x262D5299);

const Color _blue = Color(0xFF60A5FA);
const Color _blueDim = Color(0x1260A5FA);
const Color _green = Color(0xFF34D399);
const Color _purple = Color(0xFFA78BFA);
const Color _purpleDim = Color(0x12A78BFA);
const Color _amber = Color(0xFFFBBF24);
const Color _amberDim = Color(0x12FBBF24);

const Color _textPri = Color(0xE6FFFFFF);
const Color _textSec = Color(0x80FFFFFF);
const Color _textMut = Color(0x66FFFFFF);
const Color _textHint = Color(0x59FFFFFF);

class SABackupPanel extends StatefulWidget {
  final List<Map<String, dynamic>> offices;

  const SABackupPanel({super.key, required this.offices});

  @override
  State<SABackupPanel> createState() => _SABackupPanelState();
}

class _SABackupPanelState extends State<SABackupPanel> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _loading = true;
  bool _backingUpAll = false;
  String? _error;
  String _filterOffice = 'All';

  Map<String, List<Map<String, dynamic>>> _backupsByOffice = {};
  final Set<String> _restoring = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── data ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Map<String, List<Map<String, dynamic>>> result = {};
      await Future.wait(
        widget.offices.map((office) async {
          final id = office['office_id'] as String;
          final r = await RequestHandler().handleRequest('super-admin/backup/list/$id', method: 'GET');
          result[id] = List<Map<String, dynamic>>.from(r['backups'] ?? []);
        }),
      );
      if (mounted) setState(() => _backupsByOffice = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _backupAll() async {
    final ok = await showSAConfirmDialog(
      context,
      title: 'Backup all offices?',
      message: 'A new snapshot will be created for every office in the system.',
      confirmLabel: 'Backup all',
      isDanger: false,
      confirmColor: _blue,
      confirmIcon: Icons.download_rounded,
    );
    if (ok != true) return;
    setState(() => _backingUpAll = true);
    try {
      final r = await RequestHandler().handleRequest('super-admin/backup/all', method: 'GET');
      if (mounted) {
        if (r['success'] == true) {
          AppSnackBar.success(context, r['message'] ?? 'All offices backed up.');
          await _load();
        } else {
          AppSnackBar.error(context, r['message'] ?? 'Backup failed.');
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Backup error: $e');
    } finally {
      if (mounted) setState(() => _backingUpAll = false);
    }
  }

  Future<void> _restore(Map<String, dynamic> backup, String officeName) async {
    final uniqueId = backup['unique_id'] as String? ?? '';
    final officeId = backup['office_id'] as String? ?? '';
    final version = backup['version'] ?? '';
    final createdAt = backup['createdAt'] != null ? DateTime.tryParse(backup['createdAt'].toString()) : null;

    final ok = await showSAConfirmDialog(
      context,
      title: 'Restore "$officeName"?',
      message:
          'ALL current data for this office will be replaced with backup v$version'
          '${createdAt != null ? ' from ${DateFormat('MMM d, yyyy – hh:mm a').format(createdAt)}' : ''}.'
          '\n\nThis cannot be undone.',
      confirmLabel: 'Restore',
      isDanger: true,
    );
    if (ok != true) return;

    setState(() => _restoring.add(uniqueId));
    try {
      final r = await RequestHandler().handleRequest(
        'backup/restore',
        method: 'POST',
        body: {
          'backup': {'unique_id': uniqueId, 'office_id': officeId},
        },
      );
      if (mounted) {
        if (r['success'] == true) {
          AppSnackBar.success(context, r['message'] ?? 'Restore complete.');
          await _load();
        } else {
          AppSnackBar.error(context, r['message'] ?? 'Restore failed.');
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Restore error: $e');
    } finally {
      if (mounted) setState(() => _restoring.remove(uniqueId));
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  int get _totalBackups => _backupsByOffice.values.fold(0, (s, l) => s + l.length);
  int get _superAdminBackups =>
      _backupsByOffice.values.expand((l) => l).where((b) => b['backup_by_superadmin'] == true).length;
  int get _officeBackups => _totalBackups - _superAdminBackups;

  String _officeName(String officeId) {
    final o = widget.offices.firstWhere((o) => o['office_id'] == officeId, orElse: () => {'office_name': officeId});
    return o['office_name'] as String? ?? officeId;
  }

  // ── small components ──────────────────────────────────────────────────────

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

  Widget _statBox(String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: color, height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 10, color: color.withOpacity(0.55), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );

  // ── backup row ─────────────────────────────────────────────────────────────

  Widget _backupRow(Map<String, dynamic> backup, String officeName) {
    final uniqueId = backup['unique_id'] as String? ?? '';
    final version = backup['version'] ?? '?';
    final isSA = backup['backup_by_superadmin'] == true;
    final isRestoring = _restoring.contains(uniqueId);
    final createdAt = backup['createdAt'] != null ? DateTime.tryParse(backup['createdAt'].toString()) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderDim),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSA ? _purpleDim : _blueDim,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: isSA ? _purple.withOpacity(0.20) : _blue.withOpacity(0.18)),
            ),
            child: Icon(Icons.save_rounded, size: 15, color: isSA ? _purple : _blue),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uniqueId,
                  style: GoogleFonts.dmMono(fontSize: 11, color: _textPri.withOpacity(0.75)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (createdAt != null) DateFormat('MMM d, yyyy · h:mm a').format(createdAt),
                    'v$version',
                  ].join(' · '),
                  style: GoogleFonts.dmSans(fontSize: 10, color: _textMut),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Source badge
          _pill(isSA ? 'Super admin' : 'By office', isSA ? _purple : _blue, isSA ? _purpleDim : _blueDim),
          const SizedBox(width: 6),

          // Restore button
          GestureDetector(
            onTap: isRestoring ? null : () => _restore(backup, officeName),
            child: AnimatedOpacity(
              opacity: isRestoring ? 0.45 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _amberDim,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _amber.withOpacity(0.24)),
                ),
                child: isRestoring
                    ? SizedBox(width: 11, height: 11, child: CircularProgressIndicator(strokeWidth: 1.8, color: _amber))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.upload_rounded, size: 11, color: _amber),
                          const SizedBox(width: 4),
                          Text(
                            'Restore',
                            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: _amber),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── office section ─────────────────────────────────────────────────────────

  Widget _officeSection(String officeId) {
    final name = _officeName(officeId);
    final backups = _backupsByOffice[officeId] ?? [];
    if (backups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Icon(Icons.business_rounded, size: 12, color: _blue.withOpacity(0.45)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textSec,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _blueDim,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: _blue.withOpacity(0.18)),
                ),
                child: Text(
                  '${backups.length}',
                  style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: _blue),
                ),
              ),
            ],
          ),
        ),
        ...backups.map((b) => _backupRow(b, name)),
        const SizedBox(height: 10),
        Divider(color: _divider, thickness: 1),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── office filter chip ─────────────────────────────────────────────────────

  Widget _officeChip(String id) {
    final sel = _filterOffice == id;
    final label = id == 'All' ? 'All offices' : _officeName(id);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _filterOffice = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: sel ? _blue.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: sel ? _blue.withOpacity(0.40) : _textHint.withOpacity(0.15)),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? _blue : _textMut),
          ),
        ),
      ),
    );
  }

  // ── toolbar button ─────────────────────────────────────────────────────────

  Widget _toolbarBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool loading = false,
  }) => GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedOpacity(
      opacity: loading ? 0.50 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(width: 11, height: 11, child: CircularProgressIndicator(strokeWidth: 1.8, color: color))
            else
              Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    ),
  );

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final officeIds = _filterOffice == 'All' ? _backupsByOffice.keys.toList() : [_filterOffice];

    return Scaffold(
      backgroundColor: _bgBase,
      body: Column(
        children: [
          // ── Toolbar ─────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: _surface,
              border: Border(bottom: BorderSide(color: _divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _blueDim,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _borderMed),
                        ),
                        child: const Icon(Icons.save_rounded, size: 14, color: _blue),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Backup Management',
                        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: _textPri),
                      ),
                      const Spacer(),
                      _toolbarBtn(
                        label: _backingUpAll ? 'Backing up…' : 'Backup all',
                        icon: Icons.download_rounded,
                        color: _blue,
                        onTap: _backingUpAll ? null : _backupAll,
                        loading: _backingUpAll,
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 34,
                        width: 34,
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
                ),

                // Stat boxes
                if (!_loading && _error == null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: Row(
                      children: [
                        _statBox('$_totalBackups', 'Total backups', _textSec),
                        const SizedBox(width: 8),
                        _statBox('${widget.offices.length}', 'Offices covered', _blue),
                        const SizedBox(width: 8),
                        _statBox('$_superAdminBackups', 'By super admin', _purple),
                        const SizedBox(width: 8),
                        _statBox('$_officeBackups', 'By office', _green),
                      ],
                    ),
                  ),
                ],

                // Office filter chips
                if (!_loading && _error == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'All',
                          ...widget.offices.map((o) => o['office_id'] as String),
                        ].map(_officeChip).toList(),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2))
                : _error != null
                ? saEmpty(Icons.wifi_off_rounded, 'Failed to load backups')
                : officeIds.isEmpty || officeIds.every((id) => (_backupsByOffice[id] ?? []).isEmpty)
                ? saEmpty(Icons.save_outlined, 'No backups found')
                : RefreshIndicator(
                    onRefresh: _load,
                    color: Colors.white,
                    backgroundColor: const Color(0xFF1B3769),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                      children: officeIds.map(_officeSection).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
