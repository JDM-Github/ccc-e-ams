// Author: JDM
// Created on: 2026-03-24T10:34:44.487Z

import 'dart:convert';
import 'dart:io';

import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/super_admin/saofficememberspanel.dart';
import 'package:ccc_ojt_schedule/components/super_admin/shared_widgets.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/components/web_download_stub.dart'
    if (dart.library.html) 'package:ccc_ojt_schedule/components/web_download.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class SAOfficesPanel extends StatefulWidget {
  final List<Map<String, dynamic>> offices;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onOfficesChanged;

  const SAOfficesPanel({
    super.key,
    required this.offices,
    required this.loading,
    required this.onRefresh,
    required this.onOfficesChanged,
  });

  @override
  State<SAOfficesPanel> createState() => _SAOfficesPanelState();
}

class _SAOfficesPanelState extends State<SAOfficesPanel> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _search = '';
  String _filter = 'All';

  // When non-null, show the members sub-panel instead of the list
  Map<String, dynamic>? _selectedOffice;

  final Set<String> _backingUp = {};
  final Set<String> _restoring = {};

  List<Map<String, dynamic>> get _filtered {
    return widget.offices.where((o) {
      final matchSearch =
          _search.isEmpty ||
          (o['office_name'] as String).toLowerCase().contains(_search.toLowerCase()) ||
          (o['office_id'] as String).toLowerCase().contains(_search.toLowerCase());
      final matchFilter =
          _filter == 'All' ||
          (_filter == 'Active' && o['deactivated'] == false) ||
          (_filter == 'Deactivated' && o['deactivated'] == true);
      return matchSearch && matchFilter;
    }).toList();
  }

  // ── file helpers ──────────────────────────────────────────────────────────

  Future<bool> _saveFile(Uint8List bytes, String fileName) async {
    try {
      if (kIsWeb) {
        await downloadWebFile(bytes, fileName);
        return true;
      } else if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        await File('${dir!.path}/$fileName').writeAsBytes(bytes);
        return true;
      } else {
        final r = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );
        return r != null;
      }
    } catch (_) {
      return false;
    }
  }

  // ── actions ───────────────────────────────────────────────────────────────

  Future<void> _backup(Map<String, dynamic> office) async {
    final id = office['office_id'] as String;
    final name = office['office_name'] as String;

    final ok = await showSAConfirmDialog(
      context,
      title: 'Backup "$name"?',
      message: 'A full JSON snapshot will be downloaded to your device.',
      confirmLabel: 'Backup',
      isDanger: false,
      confirmColor: const Color(0xFF0EA5E9),
      confirmIcon: Icons.download_rounded,
    );
    if (ok != true) return;

    setState(() => _backingUp.add(id));
    try {
      final r = await RequestHandler().handleRequest('backup/office/$id', method: 'GET');
      if (r['success'] != true) {
        if (mounted) AppSnackBar.error(context, r['message'] ?? 'Backup failed.');
        return;
      }
      final json = const JsonEncoder.withIndent('  ').convert(r['backup']);
      final bytes = utf8.encode(json);
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final saved = await _saveFile(Uint8List.fromList(bytes), 'backup_${id}_$ts.json');
      if (mounted) {
        AppSnackBar.success(context, saved ? 'Backup saved successfully.' : 'Backup ready but save was cancelled.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Backup error: $e');
    } finally {
      if (mounted) setState(() => _backingUp.remove(id));
    }
  }

  Future<void> _restore(Map<String, dynamic> office) async {
    final id = office['office_id'] as String;
    final name = office['office_name'] as String;

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
        dialogTitle: 'Select backup for "$name"',
      );
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Could not open file picker: $e');
      return;
    }
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      if (mounted) AppSnackBar.error(context, 'Could not read file.');
      return;
    }

    Map<String, dynamic> backup;
    try {
      backup = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Invalid JSON: $e');
      return;
    }

    if (backup['meta']?['office_id'] != id) {
      if (mounted) {
        AppSnackBar.error(context, 'Wrong backup file. Expected "$id", got "${backup['meta']?['office_id']}".');
      }
      return;
    }

    final backedAt = backup['meta']?['backed_up_at'] != null
        ? DateTime.tryParse(backup['meta']['backed_up_at'].toString())
        : null;
    final userCount = (backup['users'] as List?)?.length ?? 0;

    final ok = await showSAConfirmDialog(
      context,
      title: 'Restore "$name"?',
      message:
          'ALL current data for this office will be permanently replaced with the '
          'backup from ${backedAt != null ? DateFormat('MMM d, yyyy – hh:mm a').format(backedAt) : 'unknown date'}.\n\n'
          '$userCount user(s) and their records will be restored. This cannot be undone.',
      confirmLabel: 'Restore',
      isDanger: true,
    );
    if (ok != true) return;

    setState(() => _restoring.add(id));
    try {
      final r = await RequestHandler().handleRequest('backup/restore', method: 'POST', body: {'backup': backup});
      if (mounted) {
        if (r['success'] == true) {
          AppSnackBar.success(context, r['message'] ?? 'Restore complete.');
          widget.onOfficesChanged();
        } else {
          AppSnackBar.error(context, r['message'] ?? 'Restore failed.');
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Restore error: $e');
    } finally {
      if (mounted) setState(() => _restoring.remove(id));
    }
  }

  Future<void> _toggle(Map<String, dynamic> office) async {
    final isDeact = office['deactivated'] == true;
    final ok = await showSAConfirmDialog(
      context,
      title: isDeact ? 'Reactivate Office?' : 'Deactivate Office?',
      message: isDeact
          ? 'Users in "${office['office_name']}" will be able to log in again.'
          : 'All users in "${office['office_name']}" will be blocked until reactivated.',
      confirmLabel: isDeact ? 'Reactivate' : 'Deactivate',
      isDanger: !isDeact,
    );
    if (ok != true) return;
    try {
      final r = await RequestHandler().handleRequest(
        'super-admin/toggle-office',
        method: 'POST',
        body: {'office_id': office['office_id']},
      );
      if (r['success'] == true) {
        widget.onOfficesChanged();
        if (mounted) AppSnackBar.success(context, r['message'] ?? 'Done.');
      } else {
        if (mounted) AppSnackBar.error(context, r['message'] ?? 'Failed.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Network error: $e');
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ── Members sub-panel ─────────────────────────────────────────────────
    if (_selectedOffice != null) {
      return SAOfficeMembersPanel(office: _selectedOffice!, onBack: () => setState(() => _selectedOffice = null));
    }

    // ── Office list ───────────────────────────────────────────────────────
    final filtered = _filtered;
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: widget.loading
              ? const Center(child: CircularProgressIndicator(color: saBlue))
              : filtered.isEmpty
              ? saEmpty(Icons.business_outlined, 'No offices found')
              : SAStaggerList(
                  children: filtered
                      .map(
                        (o) => _OfficeCard(
                          office: o,
                          isBacking: _backingUp.contains(o['office_id']),
                          isRestoring: _restoring.contains(o['office_id']),
                          onTap: () => setState(() => _selectedOffice = o),
                          onBackup: () => _backup(o),
                          onRestore: () => _restore(o),
                          onToggle: () => _toggle(o),
                        ),
                      )
                      .toList(),
                ),
        ),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.09)),
                  ),
                  child: TextField(
                    style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.28), size: 17),
                      hintText: 'Search offices…',
                      hintStyle: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.22), fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                width: 36,
                child: OutlinedButton(
                  onPressed: widget.onRefresh,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: BorderSide(color: Colors.white.withOpacity(0.14)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: widget.loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: saBlue),
                        )
                      : Icon(Icons.refresh_rounded, size: 16, color: Colors.white.withOpacity(0.45)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: ['All', 'Active', 'Deactivated'].map((f) {
              final sel = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel ? saBlue.withOpacity(0.13) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: sel ? saBlue.withOpacity(0.45) : Colors.white.withOpacity(0.09)),
                    ),
                    child: Text(
                      f,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sel ? saBlue : Colors.white.withOpacity(0.38),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Office card ──────────────────────────────────────────────────────────────

class _OfficeCard extends StatelessWidget {
  final Map<String, dynamic> office;
  final bool isBacking;
  final bool isRestoring;
  final VoidCallback onTap;
  final VoidCallback onBackup;
  final VoidCallback onRestore;
  final VoidCallback onToggle;

  const _OfficeCard({
    required this.office,
    required this.isBacking,
    required this.isRestoring,
    required this.onTap,
    required this.onBackup,
    required this.onRestore,
    required this.onToggle,
  });

  String _fmt(dynamic raw) {
    if (raw == null) return '—';
    final p = raw.toString().split(':');
    if (p.length < 2) return raw.toString();
    final h = int.tryParse(p[0]) ?? 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final disp = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$disp:${p[1]} $period';
  }

  @override
  Widget build(BuildContext context) {
    final isOff = office['deactivated'] == true;
    final id = office['office_id'] as String;
    final created = office['createdAt'] != null ? DateTime.tryParse(office['createdAt'].toString()) : null;
    final isBusy = isBacking || isRestoring;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isOff ? Colors.red.withOpacity(0.04) : saCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isOff ? Colors.red.withOpacity(0.18) : Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isOff ? Colors.red.withOpacity(0.10) : const Color(0xFF1B3769).withOpacity(0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOff ? Icons.business_outlined : Icons.business_rounded,
                    color: isOff ? const Color(0xFFF87171) : saBlue,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        office['office_name'] ?? '',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isOff ? const Color(0xFFFCA5A5) : Colors.white,
                        ),
                      ),
                      Text(id, style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withOpacity(0.30))),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOff ? Colors.red.withOpacity(0.12) : saGreenDk.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOff ? 'DEACTIVATED' : 'ACTIVE',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isOff ? const Color(0xFFF87171) : saGreen,
                    ),
                  ),
                ),
              ],
            ),

            // "Tap to view members" hint
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.people_outline_rounded, size: 11, color: Colors.white.withOpacity(0.20)),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to view members',
                    style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withOpacity(0.22)),
                  ),
                ],
              ),
            ),

            const Divider(height: 18, thickness: 0.5, color: Color(0x0CFFFFFF)),

            // Info chips
            Wrap(
              spacing: 18,
              runSpacing: 6,
              children: [
                _chip(
                  Icons.access_time_rounded,
                  'In: ${_fmt(office['time_in_start'])} – ${_fmt(office['time_in_end'])}',
                ),
                _chip(Icons.home_work_outlined, 'WFH: ${_fmt(office['time_in_start_wfh'])}'),
                _chip(Icons.lock_clock_rounded, 'Cap: ${_fmt(office['time_out_cap'])}'),
                _chip(Icons.weekend_outlined, office['allow_weekend'] == true ? 'Weekends ✓' : 'No weekends'),
                if (created != null) _chip(Icons.calendar_today_rounded, DateFormat('MMM d, yyyy').format(created)),
              ],
            ),

            const Divider(height: 18, thickness: 0.5, color: Color(0x08FFFFFF)),

            // Actions row
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: isBacking ? 'Backing up…' : 'Backup',
                    icon: Icons.download_rounded,
                    color: const Color(0xFF0EA5E9),
                    isLoading: isBacking,
                    enabled: !isBusy,
                    onTap: onBackup,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: isRestoring ? 'Restoring…' : 'Restore',
                    icon: Icons.upload_rounded,
                    color: const Color(0xFFF59E0B),
                    isLoading: isRestoring,
                    enabled: !isBusy,
                    onTap: onRestore,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: isOff ? 'Reactivate' : 'Deactivate',
                    icon: isOff ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                    color: isOff ? saGreenDk : const Color(0xFFDC2626),
                    enabled: !isBusy,
                    onTap: onToggle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: Colors.white.withOpacity(0.28)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white.withOpacity(0.42))),
    ],
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 180),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(width: 11, height: 11, child: CircularProgressIndicator(strokeWidth: 1.8, color: color))
              else
                Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
