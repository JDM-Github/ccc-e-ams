import 'package:ccc_ojt_schedule/components/schedule/schedule_record.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/store/member_detail_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EditScheduleDialog extends StatefulWidget {
  final ScheduleRecord record;
  final int originalIndex;
  final MemberDetailStore detailStore;

  const EditScheduleDialog({super.key, required this.record, required this.originalIndex, required this.detailStore});

  @override
  State<EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends State<EditScheduleDialog> {
  late TimeOfDay _timeIn;
  TimeOfDay? _timeOut;
  late bool _isInOffice;
  late bool _acceptEarly;
  late bool _acceptWFH;

  bool get _isEarly => _timeIn.hour < 8;

  @override
  void initState() {
    super.initState();
    _timeIn = widget.record.timeIn;
    _timeOut = widget.record.timeOut;
    _isInOffice = widget.record.isInOffice;
    _acceptEarly = widget.record.isAcceptedEarly;
    _acceptWFH = widget.record.isAcceptedWorkFromHome;
  }

  Future<void> _pickTimeIn() async {
    final time = await showTimePicker(context: context, initialTime: _timeIn);
    if (time != null) {
      setState(() {
        _timeIn = time;
        if (_isEarly) _acceptEarly = false;
      });
    }
  }

  Future<void> _pickTimeOut() async {
    final time = await showTimePicker(context: context, initialTime: _timeOut ?? TimeOfDay.now());
    if (time != null) setState(() => _timeOut = time);
  }

  Future<void> _save() async {
    final updated = ScheduleRecord(
      id: widget.record.id,
      date: widget.record.date,
      timeIn: _timeIn,
      timeOut: _timeOut,
      proofIn: widget.record.proofIn,
      proofOut: widget.record.proofOut,
      proofInFile: widget.record.proofInFile,
      proofOutFile: widget.record.proofOutFile,
      alreadyInDatabase: widget.record.alreadyInDatabase,
    );
    updated.isInOffice = _isInOffice;
    updated.isAcceptedEarly = _isEarly ? _acceptEarly : true;
    updated.isAcceptedWorkFromHome = !_isInOffice ? _acceptWFH : true;

    AppSnackBar.loading(context, 'Updating record…', id: 'update-loading-id');
    try {
      await widget.detailStore.updateSchedule(widget.originalIndex, updated);
      if (mounted) {
        AppSnackBar.hide(context, id: 'update-loading-id');
        AppSnackBar.success(context, 'Record updated successfully');
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.hide(context, id: 'update-loading-id');
        AppSnackBar.error(context, 'Failed to update record. Please try again.');
      }
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hours = _timeOut != null ? widget.detailStore.calculateHours(_timeIn, _timeOut!) : null;

    return Center(
      child: Container(
        width: 460,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: ThemeManager.surfaceElevated(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeManager.borderStrong(context)),
          boxShadow: ThemeManager.isDark(context)
              ? null
              : [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  _headerIcon(Icons.edit_calendar_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Schedule',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ThemeManager.primary(context),
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(widget.record.date),
                          style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context)),
                        ),
                      ],
                    ),
                  ),
                  _closeButton(),
                ],
              ),
            ),

            Divider(height: 1, color: ThemeManager.dividerColor(context)),

            // Body
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _pickTile(
                            icon: Icons.login_rounded,
                            label: 'Time In',
                            value: _timeIn.format(context),
                            onTap: _pickTimeIn,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _pickTile(
                            icon: Icons.logout_rounded,
                            label: 'Time Out',
                            value: _timeOut?.format(context) ?? 'Not set',
                            onTap: _pickTimeOut,
                            muted: _timeOut == null,
                          ),
                        ),
                      ],
                    ),

                    if (hours != null) ...[const SizedBox(height: 12), _hoursBadge(hours)],

                    const SizedBox(height: 20),
                    Divider(color: ThemeManager.dividerColor(context)),
                    const SizedBox(height: 12),

                    if (_isEarly) ...[
                      _warningBanner('Time-in is before 8:00 AM', Icons.schedule_rounded, Colors.amber),
                      const SizedBox(height: 8),
                      _toggleCard(
                        label: 'Accept Early Time-In',
                        subtitle: 'Allow this early time-in record',
                        icon: Icons.check_circle_outline_rounded,
                        value: _acceptEarly,
                        onChanged: (v) => setState(() => _acceptEarly = v),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _toggleCard(
                      label: 'Work From Home',
                      subtitle: _isInOffice ? 'Currently: In Office' : 'Currently: Remote',
                      icon: Icons.home_work_outlined,
                      value: !_isInOffice,
                      onChanged: (v) => setState(() {
                        _isInOffice = !v;
                        _acceptWFH = false;
                      }),
                    ),

                    if (!_isInOffice) ...[
                      const SizedBox(height: 8),
                      _warningBanner(
                        'This record is marked as Work From Home',
                        Icons.info_outline_rounded,
                        Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _toggleCard(
                        label: 'Accept Work From Home',
                        subtitle: 'Approve this WFH record',
                        icon: Icons.check_circle_outline_rounded,
                        value: _acceptWFH,
                        onChanged: (v) => setState(() => _acceptWFH = v),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: ThemeManager.dividerColor(context)),

            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(child: _cancelButton()),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
                      label: Text('Save Changes', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeManager.blue(context),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared sub-widgets ────────────────────────────────────────────────────

  Widget _headerIcon(IconData icon) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: ThemeManager.blue(context).withOpacity(ThemeManager.isDark(context) ? 0.15 : 0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: ThemeManager.blue(context), size: 20),
  );

  Widget _closeButton() => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceTint(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeManager.border(context)),
      ),
      child: Icon(Icons.close_rounded, size: 16, color: ThemeManager.secondary(context)),
    ),
  );

  Widget _cancelButton() => OutlinedButton(
    onPressed: () => Navigator.pop(context),
    style: OutlinedButton.styleFrom(
      foregroundColor: ThemeManager.secondary(context),
      side: BorderSide(color: ThemeManager.border(context)),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
  );

  Widget _hoursBadge(double hours) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: ThemeManager.blue(context).withOpacity(ThemeManager.isDark(context) ? 0.12 : 0.06),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ThemeManager.blue(context).withOpacity(0.15)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.access_time_rounded, size: 15, color: ThemeManager.blue(context)),
        const SizedBox(width: 6),
        Text(
          'Total: ${hours.toStringAsFixed(2)} hours',
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeManager.blue(context)),
        ),
      ],
    ),
  );

  Widget _pickTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool muted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ThemeManager.inputFillColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ThemeManager.inputBorderColor(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ThemeManager.blue(context).withOpacity(ThemeManager.isDark(context) ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: ThemeManager.blue(context)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: ThemeManager.muted(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: muted ? ThemeManager.faint(context) : ThemeManager.primary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: ThemeManager.faint(context)),
          ],
        ),
      ),
    );
  }

  Widget _toggleCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? ThemeManager.blue(context).withOpacity(ThemeManager.isDark(context) ? 0.12 : 0.05)
            : ThemeManager.inputFillColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? ThemeManager.blue(context).withOpacity(0.25) : ThemeManager.inputBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ThemeManager.blue(context).withOpacity(ThemeManager.isDark(context) ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: ThemeManager.blue(context)),
          ),
          const SizedBox(width: 10),
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
            activeColor: ThemeManager.blue(context),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _warningBanner(String message, IconData icon, MaterialColor color) {
    final isDark = ThemeManager.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.10) : color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? color.withOpacity(0.25) : color[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: isDark ? color[300] : color[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: isDark ? color[300] : color[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
