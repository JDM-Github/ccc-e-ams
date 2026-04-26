import 'dart:convert';
import 'dart:io';
import 'package:ccc_ojt_schedule/components/camera_preview.dart';
import 'package:ccc_ojt_schedule/components/schedule/schedule_record.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

bool get _isDesktopOrWeb => kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS));
bool get _supportsNativeCamera => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class AddRecordSheet extends StatefulWidget {
  final bool isInOffice;
  final Function(ScheduleRecord) onSave;

  const AddRecordSheet({super.key, required this.isInOffice, required this.onSave});

  @override
  State<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<AddRecordSheet> {
  final DateTime _selectedDate = DateTime.now();
  final TimeOfDay _selectedTime = TimeOfDay.now();
  final ImagePicker _picker = ImagePicker();

  dynamic _proofImageFile;
  String? _proofImageBase64;
  bool get _supportsCamera => true;

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          Navigator.pop(context);
          _proofImageFile = image;
          _proofImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _onCameraTap() async {
    if (_supportsNativeCamera) {
      await _openNativeCamera();
    } else {
      await _openDesktopCamera();
    }
  }

  Future<void> _openNativeCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          Navigator.pop(context);
          _proofImageFile = image;
          _proofImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed to open camera: $e');
    }
  }

  Future<void> _openDesktopCamera() async {
    final XFile? captured = await showDialog<XFile?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CameraPreviewDialog(),
    );
    if (captured != null) {
      final bytes = await captured.readAsBytes();
      setState(() {
        Navigator.pop(context);
        _proofImageFile = captured;
        _proofImageBase64 = base64Encode(bytes);
      });
    }
  }

  void _showImageSourcePicker() {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    if (isLandscape) {
      _showImageSourceDialog();
    } else {
      _showImageSourceSheet();
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImageSourceSheetContent(
        showCamera: _supportsCamera,
        onCamera: _onCameraTap,
        onGallery: _pickFromGallery,
        accentColor: const Color(0xFF1B3769),
      ),
    );
  }

  void _showImageSourceDialog() {
    final isDark = ThemeManager.isDark(context);
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeManager.surfaceElevated(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ThemeManager.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Proof Image',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ThemeManager.primary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a source for your proof photo',
                style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context)),
              ),
              const SizedBox(height: 16),
              if (_supportsCamera) ...[
                _dialogSourceTile(
                  context,
                  icon: Icons.camera_alt_rounded,
                  label: 'Take Photo',
                  sub: kIsWeb ? 'Use your device camera' : 'Use your camera',
                  onTap: _onCameraTap,
                  accent: const Color(0xFF1B3769),
                ),
                const SizedBox(height: 8),
              ],
              _dialogSourceTile(
                context,
                icon: Icons.photo_library_rounded,
                label: _isDesktopOrWeb ? 'Upload File' : 'Choose from Gallery',
                sub: 'Pick an existing photo',
                onTap: _pickFromGallery,
                accent: const Color(0xFF1B3769),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ThemeManager.border(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ThemeManager.secondary(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogSourceTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
    required Color accent,
  }) {
    final isDark = ThemeManager.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: ThemeManager.inputFillColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ThemeManager.border(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(isDark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
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
                  Text(sub, style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: ThemeManager.faint(context), size: 18),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return isLandscape ? _buildPcDialog() : _buildMobileSheet();
  }

  Widget _buildPcDialog() {
    final isDark = ThemeManager.isDark(context);
    final hasImage = _proofImageBase64 != null;
    const accent = Color(0xFF1B3769);

    return Center(
      child: Container(
        width: 460,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: ThemeManager.surfaceElevated(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeManager.border(context)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.10), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(isDark ? 0.15 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.login_rounded, color: accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !widget.isInOffice ? 'Add Time In (Work From Home)' : 'Add Time In',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ThemeManager.primary(context),
                            ),
                          ),
                          Text(
                            'Record your attendance',
                            style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context)),
                          ),
                        ],
                      ),
                    ),
                    _iconClose(context),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: ThemeManager.dividerColor(context)),
                const SizedBox(height: 20),

                _dateRow(context),
                const SizedBox(height: 12),
                _timeRow(context, accent),
                const SizedBox(height: 20),
                _proofLabel(context, hasImage, accent),
                const SizedBox(height: 10),
                _proofArea(context, hasImage, isDark),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: _cancelButton(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _saveButton(
                        context,
                        hasImage: hasImage,
                        accent: accent,
                        onSave: () {
                          final record = ScheduleRecord(
                            date: _selectedDate,
                            timeIn: _selectedTime,
                            proofIn: _proofImageBase64,
                            proofInFile: _proofImageFile,
                          );
                          widget.onSave(record);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSheet() {
    final isDark = ThemeManager.isDark(context);
    final hasImage = _proofImageBase64 != null;
    const accent = Color(0xFF1B3769);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ThemeManager.dividerColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(isDark ? 0.15 : 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.login_rounded, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          !widget.isInOffice ? 'Add Time In (Work From Home)' : 'Add Time In',
                          style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: ThemeManager.primary(context),
                          ),
                        ),
                        Text(
                          'Record your attendance',
                          style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _dateRow(context),
              const SizedBox(height: 12),
              _timeRow(context, accent),
              const SizedBox(height: 20),
              _proofLabel(context, hasImage, accent),
              const SizedBox(height: 8),
              _proofArea(context, hasImage, isDark),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: _saveButton(
                  context,
                  hasImage: hasImage,
                  accent: accent,
                  onSave: () {
                    final record = ScheduleRecord(
                      date: _selectedDate,
                      timeIn: _selectedTime,
                      proofIn: _proofImageBase64,
                      proofInFile: _proofImageFile,
                    );
                    widget.onSave(record);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared sub-widgets ─────────────────────────────────────────────────────

  Widget _dateRow(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    const accent = Color(0xFF1B3769);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ThemeManager.inputFillColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeManager.inputBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.calendar_today_rounded, size: 16, color: accent),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: ThemeManager.muted(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM d, yyyy').format(_selectedDate),
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ThemeManager.primary(context),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Today',
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeRow(BuildContext context, Color accent) {
    final isDark = ThemeManager.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ThemeManager.inputFillColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeManager.inputBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(Icons.access_time_rounded, size: 16, color: accent),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time In',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: ThemeManager.muted(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _selectedTime.format(context),
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ThemeManager.primary(context),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Now',
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _proofLabel(BuildContext context, bool hasImage, Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Proof of Time In',
          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeManager.primary(context)),
        ),
        if (!hasImage)
          TextButton.icon(
            onPressed: _showImageSourcePicker,
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 15),
            label: Text('Add', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
          ),
      ],
    );
  }

  Widget _proofArea(BuildContext context, bool hasImage, bool isDark) {
    if (hasImage) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ThemeManager.border(context)),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                base64Decode(_proofImageBase64!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _overlayIconBtn(
                icon: Icons.close_rounded,
                onTap: () => setState(() {
                  _proofImageBase64 = null;
                  _proofImageFile = null;
                }),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: _overlayIconBtn(icon: Icons.edit_rounded, onTap: _showImageSourcePicker),
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: _showImageSourcePicker,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: ThemeManager.inputFillColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ThemeManager.inputBorderColor(context)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 36, color: ThemeManager.faint(context)),
              const SizedBox(height: 8),
              Text(
                'Tap to add proof image',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: ThemeManager.muted(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cancelButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: ThemeManager.border(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        'Cancel',
        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeManager.secondary(context)),
      ),
    );
  }

  Widget _saveButton(
    BuildContext context, {
    required bool hasImage,
    required Color accent,
    required VoidCallback onSave,
  }) {
    return ElevatedButton.icon(
      onPressed: hasImage ? onSave : null,
      icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
      label: Text('Save Record', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        disabledBackgroundColor: ThemeManager.surfaceTint(context),
        disabledForegroundColor: ThemeManager.muted(context),
      ),
    );
  }

  Widget _overlayIconBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
      ),
    );
  }

  Widget _iconClose(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: ThemeManager.inputFillColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ThemeManager.border(context)),
        ),
        child: Icon(Icons.close_rounded, size: 16, color: ThemeManager.secondary(context)),
      ),
    );
  }
}

// ─── Image Source Sheet Content ───────────────────────────────────────────────

class _ImageSourceSheetContent extends StatelessWidget {
  final bool showCamera;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final Color accentColor;

  const _ImageSourceSheetContent({
    required this.showCamera,
    required this.onCamera,
    required this.onGallery,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ThemeManager.dividerColor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Add Proof Image',
            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: ThemeManager.primary(context)),
          ),
          const SizedBox(height: 16),
          if (showCamera) ...[
            _sourceTile(
              context,
              Icons.camera_alt_rounded,
              'Take Photo',
              'Use your camera',
              onCamera,
              accentColor,
              isDark,
            ),
            const SizedBox(height: 8),
          ],
          _sourceTile(
            context,
            Icons.photo_library_rounded,
            'Choose from Gallery',
            'Pick an existing photo',
            onGallery,
            accentColor,
            isDark,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sourceTile(
    BuildContext context,
    IconData icon,
    String label,
    String sub,
    VoidCallback onTap,
    Color accent,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ThemeManager.inputFillColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ThemeManager.border(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(isDark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ThemeManager.primary(context),
                    ),
                  ),
                  Text(sub, style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: ThemeManager.faint(context), size: 20),
          ],
        ),
      ),
    );
  }
}
