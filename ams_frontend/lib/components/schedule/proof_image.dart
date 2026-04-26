import 'dart:io';

import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ccc_ojt_schedule/components/web_download_stub.dart'
    if (dart.library.html) 'package:ccc_ojt_schedule/components/web_download.dart';
import 'package:path_provider/path_provider.dart';

class ProofImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final String title;
  final DateTime date;
  final bool canModify;
  final Function? onDelete;

  const ProofImageViewer({
    super.key,
    required this.imageBytes,
    required this.title,
    required this.date,
    this.canModify = false,
    this.onDelete,
  });

  @override
  State<ProofImageViewer> createState() => _ProofImageViewerState();
}

class _ProofImageViewerState extends State<ProofImageViewer> {
  final TransformationController _transformationController = TransformationController();
  bool _isDownloading = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() => _transformationController.value = Matrix4.identity();

  Future<void> _downloadImage() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'CCC_Proof_$timestamp.jpg';
      if (kIsWeb) {
        await downloadWebFile(widget.imageBytes, fileName);
        if (mounted) AppSnackBar.success(context, 'Downloaded successfully', id: 'download');
      } else if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        await File('${dir!.path}/$fileName').writeAsBytes(widget.imageBytes);
        if (mounted) AppSnackBar.success(context, 'Saved to storage', id: 'download');
      } else {
        await FilePicker.platform.saveFile(
          dialogTitle: 'Save Image',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['jpg'],
          bytes: widget.imageBytes,
        );
        if (mounted) AppSnackBar.success(context, 'Image saved successfully', id: 'download');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Download failed: $e', id: 'download');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    return isLandscape ? _buildPcLayout(context, size) : _buildMobileLayout(context, size);
  }

  // ── PC layout ──────────────────────────────────────────────────────────────

  Widget _buildPcLayout(BuildContext context, Size size) {
    final isDark = ThemeManager.isDark(context);

    return Container(
      width: size.width * 0.82,
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeManager.border(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.18), blurRadius: 48, offset: const Offset(0, 16)),
        ],
      ),
      child: Row(
        children: [
          // ── Image panel ──────────────────────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Container(
                color: const Color(0xFF080C14),
                child: widget.imageBytes.isNotEmpty
                    ? Stack(
                        children: [
                          Center(
                            child: InteractiveViewer(
                              transformationController: _transformationController,
                              minScale: 0.3,
                              maxScale: 6.0,
                              child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
                            ),
                          ),
                          // Zoom hint
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.touch_app_rounded, size: 12, color: Colors.white.withOpacity(0.55)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Scroll to zoom  ·  Drag to pan',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.55),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _buildBrokenImage(context),
              ),
            ),
          ),

          // ── Side panel ───────────────────────────────────────────────────
          Container(
            width: 248,
            decoration: BoxDecoration(
              color: ThemeManager.surfaceElevated(context),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              border: Border(left: BorderSide(color: ThemeManager.dividerColor(context))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: ThemeManager.dividerColor(context))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B3769).withOpacity(isDark ? 0.18 : 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.image_outlined,
                          size: 15,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Image Details',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ThemeManager.primary(context),
                          ),
                        ),
                      ),
                      _closeBtn(context),
                    ],
                  ),
                ),

                // Info rows
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(context, Icons.label_outline_rounded, 'Type', widget.title),
                      const SizedBox(height: 14),
                      _infoRow(context, Icons.calendar_today_outlined, 'Date', _formatDate(widget.date)),
                      const SizedBox(height: 14),
                      _infoRow(
                        context,
                        Icons.photo_size_select_actual_outlined,
                        'File Size',
                        '${(widget.imageBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    children: [
                      _outlineBtn(context, icon: Icons.zoom_out_map_rounded, label: 'Reset Zoom', onTap: _resetZoom),
                      const SizedBox(height: 8),
                      _solidBtn(
                        context,
                        icon: _isDownloading ? null : Icons.download_rounded,
                        label: _isDownloading ? 'Saving…' : 'Download',
                        color: const Color(0xFF1B3769),
                        isLoading: _isDownloading,
                        onTap: _isDownloading ? null : _downloadImage,
                      ),
                      if (widget.canModify) ...[
                        const SizedBox(height: 8),
                        _solidBtn(
                          context,
                          icon: _isDeleting ? null : Icons.delete_outline_rounded,
                          label: _isDeleting ? 'Deleting…' : 'Delete',
                          color: const Color(0xFFDC2626),
                          isLoading: _isDeleting,
                          onTap: _isDeleting
                              ? null
                              : () {
                                  setState(() => _isDeleting = true);
                                  widget.onDelete?.call();
                                },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context, Size size) {
    final isDark = ThemeManager.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeManager.border(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: ThemeManager.dividerColor(context))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ThemeManager.primary(context),
                        ),
                      ),
                      Text(
                        _formatDate(widget.date),
                        style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context)),
                      ),
                    ],
                  ),
                ),
                _mobileIconBtn(
                  context,
                  icon: _isDownloading ? null : Icons.download_rounded,
                  tooltip: 'Download',
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3769),
                  isLoading: _isDownloading,
                  onTap: _isDownloading ? null : _downloadImage,
                ),
                _mobileIconBtn(
                  context,
                  icon: Icons.zoom_out_map_rounded,
                  tooltip: 'Reset Zoom',
                  color: ThemeManager.secondary(context),
                  onTap: _resetZoom,
                ),
                _closeBtn(context),
              ],
            ),
          ),

          // Image
          Flexible(
            child: widget.imageBytes.isNotEmpty
                ? Container(
                    color: const Color(0xFF080C14),
                    constraints: BoxConstraints(maxHeight: size.height * 0.66),
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
                    ),
                  )
                : _buildBrokenImage(context),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: ThemeManager.dividerColor(context))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, size: 12, color: ThemeManager.muted(context)),
                const SizedBox(width: 6),
                Text(
                  'Pinch to zoom  ·  Drag to pan',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: ThemeManager.muted(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared sub-widgets ─────────────────────────────────────────────────────

  Widget _buildBrokenImage(BuildContext context) {
    return Container(
      height: 240,
      color: ThemeManager.surfaceTint(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 44, color: ThemeManager.faint(context)),
            const SizedBox(height: 8),
            Text('Failed to load image', style: GoogleFonts.dmSans(color: ThemeManager.muted(context), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: ThemeManager.muted(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: ThemeManager.muted(context),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ThemeManager.primary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _closeBtn(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.close_rounded, color: ThemeManager.secondary(context), size: 18),
      onPressed: () => Navigator.pop(context),
      tooltip: 'Close',
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
    );
  }

  Widget _mobileIconBtn(
    BuildContext context, {
    IconData? icon,
    required String tooltip,
    required Color color,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return IconButton(
      icon: isLoading
          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color))
          : Icon(icon, color: color, size: 20),
      onPressed: onTap,
      tooltip: tooltip,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
    );
  }

  Widget _outlineBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: ThemeManager.secondary(context),
          side: BorderSide(color: ThemeManager.border(context)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _solidBtn(
    BuildContext context, {
    IconData? icon,
    required String label,
    required Color color,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 15),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ThemeManager.surfaceTint(context),
          disabledForegroundColor: ThemeManager.muted(context),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
