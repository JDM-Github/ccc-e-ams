import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/store/ar_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteARImageDialog extends StatelessWidget {
  final ARImage image;
  final String currentDateTarget;
  final String cccId;
  final ARStore arStore;

  const DeleteARImageDialog({
    super.key,
    required this.image,
    required this.currentDateTarget,
    required this.cccId,
    required this.arStore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);

    return Center(
      child: Container(
        width: 460,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: ThemeManager.surfaceElevated(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeManager.borderStrong(context)),
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: ThemeManager.errorTextColor(context).withOpacity(isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_rounded, color: ThemeManager.errorTextColor(context), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete Image',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ThemeManager.primary(context),
                          ),
                        ),
                        Text(
                          'This action cannot be undone',
                          style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context)),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
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
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: ThemeManager.dividerColor(context)),

            // ── Body ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeManager.errorBgColor(context),
                  borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                  border: Border.all(color: ThemeManager.errorBorderColor(context)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: ThemeManager.errorTextColor(context), size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Are you sure you want to delete this AR image?',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: ThemeManager.errorTextColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Actions ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ThemeManager.secondary(context),
                        side: BorderSide(color: ThemeManager.border(context)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeManager.errorTextColor(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        AppSnackBar.loading(null, 'Deleting image…', id: 'del-image');
                        Navigator.pop(context);
                        final success = await arStore.deleteImage(currentDateTarget + cccId, image.id);
                        AppSnackBar.hide(null, id: 'del-image');
                        if (success) {
                          AppSnackBar.success(null, 'Image deleted successfully.');
                        } else {
                          AppSnackBar.error(null, 'Failed to delete image.');
                        }
                      },
                      icon: const Icon(Icons.delete_rounded, size: 16),
                      label: Text('Delete', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
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
}