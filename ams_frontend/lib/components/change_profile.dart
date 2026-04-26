import 'dart:convert';
import 'dart:io';

import 'package:ccc_ojt_schedule/components/camera_preview.dart';
import 'package:ccc_ojt_schedule/components/dialogue_helpers.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

bool get _isDesktopOrWeb => kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS));
bool get _supportsNativeCamera => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class ChangeProfilePictureDialog extends StatefulWidget {
  final String initial;
  final Function loadData;
  const ChangeProfilePictureDialog({super.key, required this.loadData, required this.initial});

  @override
  State<ChangeProfilePictureDialog> createState() => ChangeProfilePictureDialogState();
}

class ChangeProfilePictureDialogState extends State<ChangeProfilePictureDialog> {
  final LoginStore _loginStore = LoginStore();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  XFile? _imageFile;
  String? _imageBase64;

  Future<void> _pickFromGallery() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (img != null) {
        final bytes = await img.readAsBytes();
        setState(() {
          _imageFile = img;
          _imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _openCamera() async {
    try {
      if (_supportsNativeCamera) {
        final img = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        if (img != null) {
          final bytes = await img.readAsBytes();
          setState(() {
            _imageFile = img;
            _imageBase64 = base64Encode(bytes);
          });
        }
      } else {
        final captured = await showDialog<XFile?>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const CameraPreviewDialog(),
        );
        if (captured != null) {
          final bytes = await captured.readAsBytes();
          setState(() {
            _imageFile = captured;
            _imageBase64 = base64Encode(bytes);
          });
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed to open camera: $e');
    }
  }

  Future<void> _upload() async {
    if (_imageFile == null) return;
    setState(() => _isUploading = true);
    try {
      final bytes = await _imageFile!.readAsBytes();
      if (bytes.isEmpty) throw Exception('Selected image is empty.');
      final uri = Uri.parse('${RequestHandler().baseUrl}/.netlify/functions/api/user/upload-proof');
      final request = http.MultipartRequest('POST', uri);
      final filename = _imageFile!.name.isNotEmpty
          ? _imageFile!.name
          : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final uploadRes = await request.send();
      final respStr = await uploadRes.stream.bytesToString();
      if (uploadRes.statusCode != 200) throw Exception('Upload failed (${uploadRes.statusCode}).');
      final respJson = jsonDecode(respStr);
      if (respJson['success'] != true || respJson['url'] == null) throw Exception('Invalid server response.');
      final imageUrl = respJson['url'];
      final store = LoginStore();
      final user = store.user.value;
      final response = await RequestHandler().handleRequest(
        'user/update-profile',
        method: 'POST',
        body: {'ccc_id': user['ccc_id'], 'image_profile': imageUrl},
      );
      if (response['success'] != true) throw Exception('Failed to update profile picture.');
      store.user.value['profile_link'] = imageUrl;
      store.saveUser(store.user.value, store.rememberMe.value);
      widget.loadData();
      if (!mounted) return;
      AppSnackBar.success(context, 'Profile picture updated successfully');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Failed to update profile picture: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    final hasImage = _imageBase64 != null;
    final profileLink = _loginStore.user.value['profile_link'] as String?;

    return Center(
      child: Container(
        width: 400,
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
                      color: const Color(0xFF1B3769).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_outline_rounded, color: Color(0xFF1B3769), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change profile picture',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ThemeManager.primary(context),
                          ),
                        ),
                        Text(
                          'Upload a new profile photo',
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
                  // Avatar preview
                  Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ThemeManager.inputFillColor(context),
                          border: Border.all(color: ThemeManager.border(context), width: 2.5),
                        ),
                        child: ClipOval(
                          child: hasImage
                              ? Image.memory(base64Decode(_imageBase64!), fit: BoxFit.cover)
                              : (profileLink != null && profileLink.isNotEmpty)
                              ? Image.network(
                                  profileLink,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _initialCircle(),
                                )
                              : _initialCircle(),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B3769),
                            shape: BoxShape.circle,
                            border: Border.all(color: ThemeManager.surfaceElevated(context), width: 2),
                          ),
                          child: const Icon(Icons.edit_rounded, size: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _sourceBtn(
                          icon: Icons.photo_library_rounded,
                          label: _isDesktopOrWeb ? 'Upload file' : 'Gallery',
                          onTap: _pickFromGallery,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _sourceBtn(
                          icon: Icons.camera_alt_rounded,
                          label: 'Camera',
                          onTap: _openCamera,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: ThemeManager.dividerColor(context)),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(child: cancelBtn(context, isDark)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isUploading || !hasImage) ? null : _upload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3769),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        disabledBackgroundColor: ThemeManager.surfaceTint(context),
                        disabledForegroundColor: ThemeManager.muted(context),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Update photo', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
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

  Widget _initialCircle() => Center(
    child: Text(
      widget.initial,
      style: GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w700, color: ThemeManager.muted(context)),
    ),
  );

  Widget _sourceBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: ThemeManager.inputFillColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ThemeManager.border(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3769).withOpacity(0.08),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: const Color(0xFF1B3769), size: 15),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ThemeManager.primary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
