import 'package:ccc_ojt_schedule/components/dialogue_helpers.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RestoreConfirmDialog extends StatelessWidget {
  final String fileName;
  const RestoreConfirmDialog({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    return Center(
      child: Container(
        width: 360,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: ThemeManager.surfaceElevated(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeManager.border(context)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.1), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.restore_rounded, color: Colors.red[isDark ? 300 : 600], size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Restore office data',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ThemeManager.primary(context),
                          ),
                        ),
                        Text(
                          'This action cannot be undone',
                          style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context)),
                        ),
                      ],
                    ),
                  ),
                  closeBtn(context, isDark),
                ],
              ),
            ),

            Divider(height: 1, color: ThemeManager.dividerColor(context)),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // File name row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: ThemeManager.inputFillColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ThemeManager.border(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file_outlined, size: 14, color: ThemeManager.muted(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ThemeManager.blue(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Warning
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(isDark ? 0.08 : 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(isDark ? 0.2 : 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 15, color: Colors.red[isDark ? 300 : 600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This will permanently overwrite all current office data including users, schedules, and records.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: Colors.red[isDark ? 300 : 700],
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: cancelBtn(context, isDark)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Yes, restore',
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
