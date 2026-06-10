// Author: JDM
// Updated on: 2026-03-15
import 'dart:convert';
import 'dart:io';
import 'package:ccc_ojt_schedule/components/ar/delete_ar.dart';
import 'package:ccc_ojt_schedule/components/camera_preview.dart';
import 'package:ccc_ojt_schedule/components/schedule/proof_image.dart';
import 'package:ccc_ojt_schedule/components/schedule/schedule_record.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/ar_store.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

import 'package:flutter/foundation.dart';
import 'package:ccc_ojt_schedule/components/web_download_stub.dart'
    if (dart.library.html) 'package:ccc_ojt_schedule/components/web_download.dart';

bool get _isDesktopOrWeb => kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS));
bool get _supportsNativeCamera => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class ARPage extends StatefulWidget {
  final ScheduleRecord record;
  final String cccId;
  final String role;
  const ARPage({super.key, required this.record, required this.cccId, required this.role});
  @override
  State<ARPage> createState() => _ARPageState();
}

class _ARPageState extends State<ARPage> {
  final ARStore _arStore = ARStore();
  final LoginStore loginStore = LoginStore();
  final RequestHandler _requestHandler = RequestHandler();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();
  late String currentDateTarget;

  String? _dailySummary;
  String? _summaryId;
  bool _summaryLoading = false;

  // ── Role / SY guards ──────────────────────────────────────────

  bool get _studentIsActive {
    final userSY = loginStore.user.value['user_sy'];
    final currentSY = loginStore.user.value['current_sy'];
    final currentIteration = loginStore.user.value['current_iteration'];
    if (userSY == null || currentSY == null || currentIteration == null) return false;
    return userSY == currentSY + currentIteration - 1;
  }

  bool get _supervisorIsOnActiveSY {
    final currentIteration = loginStore.user.value['current_iteration'];
    final changeableIteration = loginStore.user.value['changeable_current_iteration'];
    if (currentIteration == null) return true;
    return (changeableIteration ?? currentIteration) == currentIteration;
  }

  bool get _isSupervisor => loginStore.user.value['role'] == 'supervisor';
  bool get _isAdmin => loginStore.user.value['isAdmin'] == true;

  bool _canModify() {
    if (_isSupervisor || _isAdmin) return _supervisorIsOnActiveSY;
    if (!_studentIsActive) return false;
    if (widget.record.timeOut != null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rec = DateTime(widget.record.date.year, widget.record.date.month, widget.record.date.day);
    return rec.isAtSameMomentAs(today);
  }

  // ── Lifecycle ─────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    currentDateTarget =
        '${widget.record.date.year}'
        '${widget.record.date.month.toString().padLeft(2, '0')}'
        '${widget.record.date.day.toString().padLeft(2, '0')}';
    _initializeSchedules();
    _fetchSummary();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────

  Future<void> _initializeSchedules() async {
    final arStore = Provider.of<ARStore>(context, listen: false);
    await arStore.loadFromLocal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.record.alreadyInDatabase) {
        arStore.fetchARActivities(currentDateTarget + widget.cccId);
      }
    });
  }

  Future<void> _fetchSummary() async {
    setState(() => _summaryLoading = true);
    try {
      final response = await _requestHandler.handleRequest(
        'user/fetch-summary/${currentDateTarget + widget.cccId}',
        method: 'GET',
      );
      if (response['success'] == true && response['summary'] != null) {
        setState(() {
          _dailySummary = response['summary'];
          _summaryId = response['id']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch summary: $e');
    } finally {
      setState(() => _summaryLoading = false);
    }
  }

  Future<void> _saveSummary(String text) async {
    AppSnackBar.loading(context, 'Saving summary…', id: 'save-summary');
    try {
      final response = await _requestHandler.handleRequest(
        'user/add-summary',
        method: 'POST',
        body: {'schedule_record_date': currentDateTarget + widget.cccId, 'summary_text': text},
      );
      if (response['success'] == true) {
        setState(() {
          _dailySummary = text;
          _summaryId = response['summary']?['id']?.toString();
        });
        if (mounted) {
          AppSnackBar.hide(context, id: 'save-summary');
          AppSnackBar.success(context, 'Daily summary saved.');
        }
      } else {
        throw Exception('Save failed');
      }
    } catch (e) {
      debugPrint('Failed to save summary: $e');
      if (mounted) {
        AppSnackBar.hide(context, id: 'save-summary');
        AppSnackBar.error(context, 'Failed to save summary.');
      }
    }
  }

  Future<void> _deleteSummary() async {
    if (_summaryId == null) return;
    AppSnackBar.loading(context, 'Deleting summary…', id: 'del-summary');
    try {
      final response = await _requestHandler.handleRequest('user/delete-summary/$_summaryId', method: 'DELETE');
      if (response['success'] == true) {
        setState(() {
          _dailySummary = null;
          _summaryId = null;
        });
        if (mounted) {
          AppSnackBar.hide(context, id: 'del-summary');
          AppSnackBar.success(context, 'Summary deleted.');
        }
      } else {
        throw Exception('Delete failed');
      }
    } catch (e) {
      debugPrint('Failed to delete summary: $e');
      if (mounted) {
        AppSnackBar.hide(context, id: 'del-summary');
        AppSnackBar.error(context, 'Failed to delete summary.');
      }
    }
  }

  // ── Image picking ─────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        Navigator.pop(context);
        final bytes = await image.readAsBytes();
        await _processAddImage(bytes.isEmpty ? '' : base64Encode(bytes));
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
        Navigator.pop(context);
        final bytes = await image.readAsBytes();
        await _processAddImage(bytes.isEmpty ? '' : base64Encode(bytes));
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
      Navigator.pop(context);
      final bytes = await captured.readAsBytes();
      await _processAddImage(bytes.isEmpty ? '' : base64Encode(bytes));
    }
  }

  Future<void> _processAddImage(String base64Image) async {
    AppSnackBar.loading(context, 'Adding AR image…', id: 'add-image');
    try {
      await _arStore.addImage(currentDateTarget + widget.cccId, base64Image, widget.record.alreadyInDatabase);
      if (mounted) {
        AppSnackBar.hide(context, id: 'add-image');
        AppSnackBar.success(context, 'AR image added successfully.');
      }
    } catch (e, st) {
      debugPrint('Failed to add AR image: $e\n$st');
      if (mounted) {
        AppSnackBar.hide(context, id: 'add-image');
        AppSnackBar.error(context, 'Failed to add AR image: $e');
      }
    }
  }

  Future<String?> _downloadAllARImages(BuildContext context, String scheduleRecordId, List<ARImage> images) async {
    if (images.isEmpty) {
      AppSnackBar.warning(context, 'No images to download.');
      return null;
    }
    AppSnackBar.loading(context, 'Preparing ZIP file…', id: 'download');
    try {
      final archive = Archive();
      for (final image in images) {
        try {
          late List<int> bytes;
          if (image.image.startsWith('http')) {
            final response = await http.get(Uri.parse(image.image));
            if (response.statusCode != 200) continue;
            bytes = response.bodyBytes;
          } else {
            bytes = base64Decode(image.image);
          }
          archive.addFile(ArchiveFile('${image.id}.jpg', bytes.length, bytes));
        } catch (e, st) {
          debugPrint('Failed to process image ${image.id}: $e\n$st');
        }
      }
      if (archive.isEmpty) {
        AppSnackBar.hide(context, id: 'download');
        AppSnackBar.error(context, 'Failed to collect image data.');
        return null;
      }
      final zipData = Uint8List.fromList(ZipEncoder().encode(archive)!);
      final zipName = 'CCC_AR_$scheduleRecordId.zip';
      String? savedPath;
      if (kIsWeb) {
        await downloadWebFile(zipData, zipName);
        savedPath = '';
      } else if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          final file = File('${dir.path}/$zipName');
          await file.writeAsBytes(zipData, flush: true);
          savedPath = file.path;
        }
      } else if (Platform.isWindows) {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save ZIP File',
          fileName: zipName,
          type: FileType.custom,
          allowedExtensions: ['zip'],
          bytes: zipData,
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$zipName');
        await file.writeAsBytes(zipData, flush: true);
        savedPath = file.path;
      }
      if (mounted) {
        AppSnackBar.hide(context, id: 'download');
        if (savedPath != null) {
          AppSnackBar.success(context, 'ZIP downloaded successfully.');
        } else {
          AppSnackBar.error(context, 'Failed to save ZIP file.');
        }
      }
      return savedPath;
    } catch (e, st) {
      debugPrint('ZIP creation error: $e\n$st');
      if (mounted) {
        AppSnackBar.hide(context, id: 'download');
        AppSnackBar.error(context, 'An error occurred: $e');
      }
      return null;
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────

  void _showImageSourcePicker() {
    if (!_canModify()) {
      AppSnackBar.warning(context, 'You cannot add images for this date.');
      return;
    }
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    if (isLandscape) {
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: _SourcePickerDialog(
            isDesktopOrWeb: _isDesktopOrWeb,
            onCamera: _onCameraTap,
            onGallery: _pickFromGallery,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            _SourcePickerSheet(isDesktopOrWeb: _isDesktopOrWeb, onCamera: _onCameraTap, onGallery: _pickFromGallery),
      );
    }
  }

  void _showDailySummaryDialog() {
    _descriptionController.text = _dailySummary ?? '';
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final canEdit = _canModify();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _SummaryDialog(
        controller: _descriptionController,
        date: widget.record.date,
        canEdit: canEdit,
        summaryId: _summaryId,
        isSupervisor: _isSupervisor,
        isAdmin: _isAdmin,
        studentIsActive: _studentIsActive,
        isLandscape: isLandscape,
        onSave: (text) {
          Navigator.pop(context);
          if (text.isNotEmpty) _saveSummary(text);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteSummary();
        },
      ),
    );
  }

  Future<void> _showProofImage(BuildContext context, ARImage image) async {
    Uint8List? imageBytes;
    final isUrl = image.image.startsWith('http://') || image.image.startsWith('https://');
    if (isUrl) {
      try {
        final cacheManager = DefaultCacheManager();
        final file = await cacheManager.getSingleFile(image.image);
        imageBytes = await file.readAsBytes();
      } catch (e) {
        debugPrint('Error loading cached image: $e');
      }
    } else {
      try {
        imageBytes = base64Decode(image.image);
      } catch (e) {
        debugPrint('Error decoding Base64 image: $e');
      }
    }
    imageBytes ??= Uint8List(0);
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ProofImageViewer(
          imageBytes: imageBytes!,
          title: image.id,
          date: image.addedAt,
          canModify: _canModify(),
          onDelete: () {
            Navigator.pop(context);
            _showDeleteARImageDialog(context, image);
          },
        ),
      ),
    );
  }

  Future<void> _showDeleteARImageDialog(BuildContext context, ARImage image) async {
    if (!_canModify()) {
      AppSnackBar.warning(context, 'You cannot delete images for this date.');
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: DeleteARImageDialog(
          image: image,
          currentDateTarget: currentDateTarget,
          cccId: widget.cccId,
          arStore: _arStore,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final isDark = ThemeManager.isDark(context);

    return Consumer<ARStore>(
      builder: (context, arStore, _) {
        final images = arStore.getImagesForRecord(currentDateTarget + widget.cccId);

        return Scaffold(
          backgroundColor: ThemeManager.bg(context),
          // ── No appBar — header lives inline in the body Column ──
          body: arStore.isLoading
              ? Center(child: CircularProgressIndicator(color: ThemeManager.blue(context), strokeWidth: 2))
              : Column(
                  children: [
                    _ARInlineHeader(
                      record: widget.record,
                      isDark: isDark,
                      canModify: _canModify(), // ← pass this in
                      onBack: () => Navigator.pop(context),
                      onDownload: () => _downloadAllARImages(context, currentDateTarget + widget.cccId, images),
                      onAddImage: _showImageSourcePicker, // ← new
                      onAddSummary: _showDailySummaryDialog, // ← new
                    ),

                    // ── Read-only banner ──────────────────────────
                    if (!_canModify())
                      _ReadOnlyBanner(
                        isSupervisor: _isSupervisor,
                        isAdmin: _isAdmin,
                        studentIsActive: _studentIsActive,
                      ),

                    // ── Toolbar (PC) or header card (mobile) ──────
                    if (isLandscape)
                      _PCToolbar(
                        images: images,
                        dailySummary: _dailySummary,
                        summaryLoading: _summaryLoading,
                        canModify: _canModify(),
                        onAddSummary: _showDailySummaryDialog,
                        onAddImage: _showImageSourcePicker,
                      )
                    else
                      _MobileHeaderCard(
                        imageCount: images.length,
                        dailySummary: _dailySummary,
                        summaryLoading: _summaryLoading,
                        onSummaryTap: _showDailySummaryDialog,
                      ),

                    // ── Content ───────────────────────────────────
                    Expanded(
                      child: images.isEmpty
                          ? _EmptyState(canModify: _canModify())
                          : _ImageGrid(
                              images: images,
                              isLandscape: isLandscape,
                              onTap: (image) => _showProofImage(context, image),
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline Header — replaces _ARAppBar, matches SchedulePage filter bar style
// ─────────────────────────────────────────────────────────────────────────────

class _ARInlineHeader extends StatelessWidget {
  final ScheduleRecord record;
  final bool isDark;
  final bool canModify;
  final VoidCallback onBack;
  final VoidCallback onDownload;
  final VoidCallback onAddImage;
  final VoidCallback onAddSummary;

  const _ARInlineHeader({
    required this.record,
    required this.isDark,
    required this.canModify,
    required this.onBack,
    required this.onDownload,
    required this.onAddImage,
    required this.onAddSummary,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM d, yyyy').format(record.date);
    final dayOfWeek = DateFormat('EEEE').format(record.date);
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(8, topPadding + 6, 12, 10),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        boxShadow: isDark ? null : [const BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
        border: Border(bottom: BorderSide(color: ThemeManager.dividerColor(context))),
      ),
      child: Row(
        children: [
          // Back
          _HeaderIconButton(
            onTap: onBack,
            tooltip: 'Back',
            color: Colors.transparent,
            borderColor: Colors.transparent,
            child: Icon(Icons.arrow_back_rounded, size: 20, color: ThemeManager.brand),
          ),
          const SizedBox(width: 4),

          // Icon badge
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: ThemeManager.blue(context).withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ThemeManager.blue(context).withOpacity(0.20)),
            ),
            child: Icon(Icons.assessment_rounded, color: ThemeManager.blue(context), size: 16),
          ),
          const SizedBox(width: 10),

          // Title + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Activity Report',
                  style: GoogleFonts.dmSans(
                    color: ThemeManager.primary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                Text(
                  '$dayOfWeek · $formattedDate',
                  style: GoogleFonts.dmSans(
                    color: ThemeManager.muted(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Download
          _HeaderIconButton(
            onTap: onDownload,
            tooltip: 'Download all as ZIP',
            color: ThemeManager.blue(context).withOpacity(0.10),
            borderColor: ThemeManager.blue(context).withOpacity(0.25),
            child: Icon(Icons.download_rounded, size: 17, color: ThemeManager.blue(context)),
          ),

          // Summary — always visible (read-only users can still view it)
          const SizedBox(width: 6),
          _HeaderIconButton(
            onTap: onAddSummary,
            tooltip: 'Daily summary',
            color: ThemeManager.inputFillColor(context),
            borderColor: ThemeManager.border(context),
            child: Icon(Icons.description_rounded, size: 17, color: ThemeManager.secondary(context)),
          ),

          // Add Image — only when canModify
          if (canModify) ...[
            const SizedBox(width: 6),
            _HeaderIconButton(
              onTap: onAddImage,
              tooltip: 'Add image',
              color: const Color(0xFF1B3769).withOpacity(0.10),
              borderColor: const Color(0xFF1B3769).withOpacity(0.30),
              child: const Icon(Icons.add_photo_alternate_rounded, size: 17, color: Color(0xFF1B3769)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable 34×34 icon button for the inline header row — mirrors
/// `_buildCompactIconButton` from SchedulePage.
class _HeaderIconButton extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;
  final String? tooltip;

  const _HeaderIconButton({
    required this.child,
    required this.color,
    required this.borderColor,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PC Toolbar
// ─────────────────────────────────────────────────────────────────────────────

class _PCToolbar extends StatelessWidget {
  final List<ARImage> images;
  final String? dailySummary;
  final bool summaryLoading;
  final bool canModify;
  final VoidCallback onAddSummary;
  final VoidCallback onAddImage;

  const _PCToolbar({
    required this.images,
    required this.dailySummary,
    required this.summaryLoading,
    required this.canModify,
    required this.onAddSummary,
    required this.onAddImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Image count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: ThemeManager.surfaceTint(context),
              borderRadius: BorderRadius.circular(ThemeManager.radiusBtn),
              border: Border.all(color: ThemeManager.border(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library_outlined, size: 14, color: ThemeManager.blue(context)),
                const SizedBox(width: 6),
                Text(
                  '${images.length} image${images.length != 1 ? 's' : ''}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager.blue(context),
                  ),
                ),
              ],
            ),
          ),

          // Summary preview
          if (dailySummary != null && dailySummary!.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: ThemeManager.surface(context),
                  borderRadius: BorderRadius.circular(ThemeManager.radiusBtn),
                  border: Border.all(color: ThemeManager.border(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined, size: 13, color: ThemeManager.muted(context)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        dailySummary!,
                        style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.bodyColor(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (summaryLoading) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: ThemeManager.blue(context)),
            ),
          ],

          const SizedBox(width: 12),
          _OutlineButton(
            icon: dailySummary != null ? Icons.description_rounded : Icons.description_outlined,
            label: dailySummary != null ? 'Edit Summary' : 'Add Summary',
            onTap: onAddSummary,
          ),
          if (canModify) ...[
            const SizedBox(width: 8),
            _PrimaryButton(icon: Icons.add_photo_alternate_rounded, label: 'Add Image', onTap: onAddImage),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Header Card
// ─────────────────────────────────────────────────────────────────────────────

class _MobileHeaderCard extends StatelessWidget {
  final int imageCount;
  final String? dailySummary;
  final bool summaryLoading;
  final VoidCallback onSummaryTap;

  const _MobileHeaderCard({
    required this.imageCount,
    required this.dailySummary,
    required this.summaryLoading,
    required this.onSummaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(ThemeManager.radiusCard),
        border: Border.all(color: ThemeManager.border(context)),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: const Color(0xFF1B3769).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: ThemeManager.blue(context).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                    border: Border.all(color: ThemeManager.blue(context).withOpacity(0.20)),
                  ),
                  child: Icon(Icons.assessment_rounded, color: ThemeManager.blue(context), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Report Images',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: ThemeManager.primary(context),
                        ),
                      ),
                      Text(
                        summaryLoading ? 'Loading summary…' : '$imageCount image${imageCount != 1 ? 's' : ''} added',
                        style: GoogleFonts.dmSans(color: ThemeManager.secondary(context), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onSummaryTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: ThemeManager.surfaceTint(context),
                      borderRadius: BorderRadius.circular(ThemeManager.radiusBtn),
                      border: Border.all(color: ThemeManager.borderStrong(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          dailySummary != null ? Icons.description_rounded : Icons.description_outlined,
                          size: 13,
                          color: ThemeManager.blue(context),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Summary',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ThemeManager.blue(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (dailySummary != null && dailySummary!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ThemeManager.surface(context),
                  borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                  border: Border.all(color: ThemeManager.dividerColor(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY SUMMARY',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: ThemeManager.muted(context),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dailySummary!,
                      style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.bodyColor(context), height: 1.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Read-only Banner
// ─────────────────────────────────────────────────────────────────────────────

class _ReadOnlyBanner extends StatelessWidget {
  final bool isSupervisor;
  final bool isAdmin;
  final bool studentIsActive;

  const _ReadOnlyBanner({required this.isSupervisor, required this.isAdmin, required this.studentIsActive});

  @override
  Widget build(BuildContext context) {
    final String message;
    if (isSupervisor || isAdmin) {
      message = 'Viewing a past school year — records are read-only';
    } else if (!studentIsActive) {
      message = 'Your account is inactive for the current school year';
    } else {
      message = 'You can only modify today\'s Activity Report';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeManager.brand.withAlpha(50),
        borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
        border: Border.all(color: ThemeManager.brand),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: ThemeManager.blue(context), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(color: ThemeManager.blue(context), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Grid
// ─────────────────────────────────────────────────────────────────────────────

class _ImageGrid extends StatelessWidget {
  final List<ARImage> images;
  final bool isLandscape;
  final ValueChanged<ARImage> onTap;

  const _ImageGrid({required this.images, required this.isLandscape, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isLandscape ? 5 : 3;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: images.length,
      itemBuilder: (_, i) => _ImageCard(image: images[i], onTap: () => onTap(images[i])),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final ARImage image;
  final VoidCallback onTap;

  const _ImageCard({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
          border: Border.all(color: ThemeManager.border(context)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ARImageWidget(src: image.image),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.70), Colors.transparent],
                    ),
                  ),
                  child: Text(
                    DateFormat('MMM dd, h:mm a').format(image.addedAt),
                    style: GoogleFonts.dmSans(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ARImageWidget extends StatelessWidget {
  final String src;
  const _ARImageWidget({required this.src});

  @override
  Widget build(BuildContext context) {
    if (src.startsWith('http')) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(child: CircularProgressIndicator(strokeWidth: 2, color: ThemeManager.blue(context)));
        },
        errorBuilder: (_, __, ___) =>
            Center(child: Icon(Icons.broken_image_outlined, size: 32, color: ThemeManager.muted(context))),
      );
    }
    return Image.memory(
      base64Decode(src),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Center(child: Icon(Icons.broken_image_outlined, size: 32, color: ThemeManager.muted(context))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool canModify;
  const _EmptyState({required this.canModify});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: ThemeManager.surfaceTint(context), shape: BoxShape.circle),
            child: Icon(Icons.photo_library_outlined, size: 40, color: ThemeManager.faint(context)),
          ),
          const SizedBox(height: 16),
          Text(
            'No AR images yet',
            style: GoogleFonts.dmSans(
              color: ThemeManager.secondary(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (canModify) ...[
            const SizedBox(height: 4),
            Text(
              'Use the button to add images',
              style: GoogleFonts.dmSans(color: ThemeManager.faint(context), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source Picker — Dialog (landscape)
// ─────────────────────────────────────────────────────────────────────────────

class _SourcePickerDialog extends StatelessWidget {
  final bool isDesktopOrWeb;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _SourcePickerDialog({required this.isDesktopOrWeb, required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(ThemeManager.radiusCard),
        border: Border.all(color: ThemeManager.borderStrong(context)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3769).withOpacity(isDark ? 0.3 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogHeader(title: 'Add AR Image', onClose: () => Navigator.pop(context)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Take Photo',
                  subtitle: isDesktopOrWeb ? 'Use your device camera' : 'Use your camera',
                  onTap: onCamera,
                ),
                const SizedBox(height: 8),
                _SourceOption(
                  icon: Icons.photo_library_rounded,
                  label: isDesktopOrWeb ? 'Upload File' : 'Choose from Gallery',
                  subtitle: 'Pick an existing photo',
                  onTap: onGallery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source Picker — Sheet (portrait)
// ─────────────────────────────────────────────────────────────────────────────

class _SourcePickerSheet extends StatelessWidget {
  final bool isDesktopOrWeb;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _SourcePickerSheet({required this.isDesktopOrWeb, required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: ThemeManager.border(context))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: ThemeManager.faint(context), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 18),
          Text(
            'Add AR Image',
            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: ThemeManager.primary(context)),
          ),
          const SizedBox(height: 14),
          _SourceOption(
            icon: Icons.camera_alt_rounded,
            label: 'Take Photo',
            subtitle: isDesktopOrWeb ? 'Use your device camera' : 'Use your camera',
            onTap: onCamera,
          ),
          const SizedBox(height: 8),
          _SourceOption(
            icon: Icons.photo_library_rounded,
            label: isDesktopOrWeb ? 'Upload File' : 'Choose from Gallery',
            subtitle: 'Pick an existing photo',
            onTap: onGallery,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source Option Row
// ─────────────────────────────────────────────────────────────────────────────

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceOption({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ThemeManager.surface(context),
          borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
          border: Border.all(color: ThemeManager.border(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeManager.blue(context).withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: ThemeManager.blue(context), size: 20),
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
                  Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context))),
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

// ─────────────────────────────────────────────────────────────────────────────
// Summary Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryDialog extends StatelessWidget {
  final TextEditingController controller;
  final DateTime date;
  final bool canEdit;
  final String? summaryId;
  final bool isSupervisor;
  final bool isAdmin;
  final bool studentIsActive;
  final bool isLandscape;
  final ValueChanged<String> onSave;
  final VoidCallback onDelete;

  const _SummaryDialog({
    required this.controller,
    required this.date,
    required this.canEdit,
    required this.summaryId,
    required this.isSupervisor,
    required this.isAdmin,
    required this.studentIsActive,
    required this.isLandscape,
    required this.onSave,
    required this.onDelete,
  });

  String get _readOnlyMessage {
    if (isSupervisor || isAdmin) {
      return 'Viewing a past school year — summaries are read-only';
    } else if (!studentIsActive) {
      return 'Your account is inactive for the current school year';
    }
    return 'You can only edit summaries for today';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isLandscape ? const EdgeInsets.symmetric(horizontal: 120, vertical: 40) : const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(ThemeManager.radiusCard),
          border: Border.all(color: ThemeManager.borderStrong(context)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B3769).withOpacity(isDark ? 0.25 : 0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              title: 'Daily Summary',
              subtitle: DateFormat('MMM dd, yyyy').format(date),
              icon: Icons.description_rounded,
              onClose: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 6,
                    enabled: canEdit,
                    style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.bodyColor(context)),
                    decoration: InputDecoration(
                      hintText: 'Describe your activities, tasks completed, challenges faced…',
                      hintStyle: GoogleFonts.dmSans(color: ThemeManager.hint(context), fontSize: 13),
                      filled: true,
                      fillColor: canEdit ? ThemeManager.inputFillColor(context) : ThemeManager.surfaceTint(context),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                        borderSide: BorderSide(color: ThemeManager.inputBorderColor(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                        borderSide: BorderSide(color: ThemeManager.inputBorderColor(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                        borderSide: BorderSide(color: ThemeManager.inputFocusedColor(context), width: 1.5),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                        borderSide: BorderSide(color: ThemeManager.dividerColor(context)),
                      ),
                    ),
                  ),
                  if (!canEdit) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeManager.brand.withAlpha(50),
                        borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                        border: Border.all(color: ThemeManager.brand),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: ThemeManager.blue(context), size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _readOnlyMessage,
                              style: GoogleFonts.dmSans(
                                color: ThemeManager.blue(context),
                                fontSize: 12,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (canEdit && summaryId != null) ...[_DeleteIconButton(onTap: onDelete), const SizedBox(width: 8)],
                  Expanded(child: _CancelButton()),
                  if (canEdit) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _SaveButton(onTap: () => onSave(controller.text.trim()))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small dialog components
// ─────────────────────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onClose;

  const _DialogHeader({required this.title, this.subtitle, this.icon, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ThemeManager.dividerColor(context))),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: ThemeManager.blue(context).withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ThemeManager.blue(context).withOpacity(0.20)),
              ),
              child: Icon(icon, color: ThemeManager.blue(context), size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ThemeManager.primary(context),
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.secondary(context))),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: ThemeManager.muted(context), size: 18),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ThemeManager.surface(context),
          borderRadius: BorderRadius.circular(ThemeManager.radiusBtn),
          border: Border.all(color: ThemeManager.borderStrong(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: ThemeManager.blue(context)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeManager.blue(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B3769), Color(0xFF2D5299)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(ThemeManager.radiusBtn),
          border: Border.all(color: const Color(0x4060A5FA)),
          boxShadow: ThemeManager.isDark(context)
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF1B3769).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: ThemeManager.surface(context),
          borderRadius: BorderRadius.circular(ThemeManager.radiusBtn),
          border: Border.all(color: ThemeManager.border(context)),
        ),
        child: Center(
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
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B3769), Color(0xFF2D5299)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(ThemeManager.radiusBtn),
          border: Border.all(color: const Color(0x4060A5FA)),
        ),
        child: Center(
          child: Text(
            'Save',
            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _DeleteIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DeleteIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ThemeManager.errorBgColor(context),
          borderRadius: BorderRadius.circular(ThemeManager.radiusBtn),
          border: Border.all(color: ThemeManager.errorBorderColor(context)),
        ),
        child: Icon(Icons.delete_outline_rounded, color: ThemeManager.errorTextColor(context), size: 18),
      ),
    );
  }
}
