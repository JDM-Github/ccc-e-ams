import 'dart:convert';
import 'dart:typed_data';
import 'package:ccc_ojt_schedule/components/schedule/proof_image.dart';
import 'package:ccc_ojt_schedule/components/schedule/schedule_record.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/screen/ar.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class RecordItem extends StatelessWidget {
  final ScheduleRecord record;
  final VoidCallback onAddTimeOut;
  final LoginStore loginStore = LoginStore();

  RecordItem({super.key, required this.record, required this.onAddTimeOut});

  Future<void> _showProofImage(BuildContext context, String imageSource, String title, DateTime date) async {
    Uint8List? imageBytes;
    final isUrl = imageSource.startsWith('http://') || imageSource.startsWith('https://');
    if (isUrl) {
      try {
        final file = await DefaultCacheManager().getSingleFile(imageSource);
        imageBytes = await file.readAsBytes();
      } catch (_) {}
    } else {
      try {
        imageBytes = base64Decode(imageSource);
      } catch (_) {}
    }
    imageBytes ??= Uint8List(0);
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ProofImageViewer(imageBytes: imageBytes!, title: title, date: date),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(date.year, date.month, date.day).isBefore(today);
  }

  TimeOfDay _getEffectiveTimeIn() {
    if (ScheduleRecord.isEarly(record.timeIn) && !record.isAcceptedEarly) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
    return record.timeIn;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    final hasTimeOut = record.timeOut != null;
    final isToday = _isToday(record.date);
    final isPast = _isPastDate(record.date);
    final canAddTimeOut = isToday && !hasTimeOut;
    final effectiveTimeIn = _getEffectiveTimeIn();
    final isNotRecorded = record.isInOffice && !record.isAcceptedWorkFromHome;
    final isActive =
        loginStore.user.value['user_sy'] ==
        loginStore.user.value['current_sy'] + loginStore.user.value['current_iteration'] - 1;

    // Card colors
    final cardBg = isNotRecorded
        ? (isDark ? Colors.red.withOpacity(0.06) : Colors.red[50]!)
        : ThemeManager.surface(context);
    final cardBorder = isNotRecorded
        ? (isDark ? Colors.red.withOpacity(0.25) : Colors.red[200]!)
        : ThemeManager.border(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder, width: isNotRecorded ? 1.5 : 1),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isNotRecorded ? 0.04 : 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Left: badges + times
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge row
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          // Date
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 11, color: ThemeManager.secondary(context)),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMMM d, yyyy').format(record.date),
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isNotRecorded
                                      ? ThemeManager.secondary(context)
                                      : ThemeManager.primary(context),
                                ),
                              ),
                            ],
                          ),

                          // Done / Active
                          _statusBadge(
                            context,
                            hasTimeOut || isPast ? 'Done' : 'Active',
                            hasTimeOut || isPast ? const Color(0xFF10B981) : const Color(0xFF1B3769),
                            isDark,
                          ),

                          // WFH
                          if (!record.isInOffice)
                            _iconBadge(
                              context,
                              record.isAcceptedWorkFromHome ? Icons.home : Icons.home_outlined,
                              record.isAcceptedWorkFromHome ? 'WFH' : 'WFH Pending',
                              record.isAcceptedWorkFromHome
                                  ? (isDark ? Colors.blue[300]! : Colors.blue[700]!)
                                  : (isDark ? Colors.red[300]! : Colors.red[700]!),
                              isDark,
                            ),

                          // Early
                          if (ScheduleRecord.isEarly(record.timeIn))
                            _iconBadge(
                              context,
                              record.isAcceptedEarly ? Icons.wb_sunny : Icons.schedule,
                              record.isAcceptedEarly ? 'Early' : 'Early (Adjusted)',
                              record.isAcceptedEarly
                                  ? (isDark ? Colors.orange[300]! : Colors.orange[700]!)
                                  : (isDark ? Colors.amber[300]! : Colors.amber[800]!),
                              isDark,
                            ),

                          // Not recorded
                          if (isNotRecorded)
                            _iconBadge(
                              context,
                              Icons.block,
                              'Not Recorded',
                              isDark ? Colors.red[300]! : Colors.red[700]!,
                              isDark,
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Time row
                      Row(
                        children: [
                          _buildCompactTime(
                            context: context,
                            icon: Icons.login,
                            label: 'IN',
                            time: effectiveTimeIn,
                            originalTime: ScheduleRecord.isEarly(record.timeIn) && !record.isAcceptedEarly
                                ? record.timeIn
                                : null,
                            color: isNotRecorded ? ThemeManager.muted(context) : const Color(0xFF10B981),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: ThemeManager.dividerColor(context),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          if (hasTimeOut)
                            _buildCompactTime(
                              context: context,
                              icon: Icons.logout,
                              label: 'OUT',
                              time: record.timeOut!,
                              color: isNotRecorded ? ThemeManager.muted(context) : const Color(0xFFFF4E0B),
                            )
                          else if (isPast && !hasTimeOut)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 12,
                                  color: isNotRecorded ? ThemeManager.muted(context) : Colors.orange[700],
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'OUT:',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    color: ThemeManager.blue(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '5:00 PM',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isNotRecorded ? ThemeManager.muted(context) : Colors.orange[700],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: 'Auto-timed out at 5:00 PM',
                                  child: Icon(Icons.info_outline, size: 12, color: ThemeManager.muted(context)),
                                ),
                              ],
                            )
                          else
                            Text(
                              '--:--',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ThemeManager.faint(context),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right: action icons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (record.proofIn != null && !isNotRecorded)
                      _actionIcon(
                        context,
                        Icons.image,
                        'View Time In Proof',
                        const Color(0xFF1B3769),
                        () => _showProofImage(context, record.proofIn!, 'Time In Proof', record.date),
                      ),
                    if (record.proofOut != null && !isNotRecorded)
                      _actionIcon(
                        context,
                        Icons.image,
                        'View Time Out Proof',
                        const Color(0xFF2563EB),
                        () => _showProofImage(context, record.proofOut!, 'Time Out Proof', record.date),
                      ),
                    if ((record.proofIn != null || record.proofOut != null) && !isNotRecorded)
                      Container(
                        width: 1,
                        height: 20,
                        color: ThemeManager.dividerColor(context),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    if (canAddTimeOut && !isNotRecorded && isActive)
                      _actionIcon(context, Icons.logout, 'Add Time Out', const Color(0xFF1B3769), onAddTimeOut)
                    else if (!hasTimeOut && isPast && !isNotRecorded)
                      Tooltip(
                        message: 'Cannot add timeout for past dates',
                        child: _actionIcon(context, Icons.lock, '', ThemeManager.muted(context), () {}),
                      ),
                    _actionIcon(
                      context,
                      Icons.folder_outlined,
                      'AR Folder',
                      const Color(0xFF1B3769),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ARPage(
                            record: record,
                            cccId: loginStore.user.value['ccc_id'],
                            role: loginStore.user.value['role'],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Warning banner
            if (isNotRecorded) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.red.withOpacity(0.08) : Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? Colors.red.withOpacity(0.2) : Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 15, color: isDark ? Colors.red[300] : Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This work-from-home request is pending approval. Hours will not be counted until approved.',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: isDark ? Colors.red[300] : Colors.red[700],
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
      ),
    );
  }

  // ── Badge helpers ──────────────────────────────────────────────────────────

  Widget _statusBadge(BuildContext context, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(isDark ? 0.15 : 0.10), borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _iconBadge(BuildContext context, IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(isDark ? 0.25 : 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(BuildContext context, IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 18,
      color: color,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }

  // ── Compact time widget ────────────────────────────────────────────────────

  Widget _buildCompactTime({
    required BuildContext context,
    required IconData icon,
    required String label,
    required TimeOfDay time,
    TimeOfDay? originalTime,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          '$label:',
          style: GoogleFonts.dmSans(fontSize: 10, color: ThemeManager.blue(context), fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time.format(context),
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: ThemeManager.primary(context),
              ),
            ),
            if (originalTime != null)
              Text(
                '(was ${originalTime.format(context)})',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: ThemeManager.muted(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
