// Author: JDM

import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── tokens (dark-only, matches SAOfficeMembersPanel) ─────────────────────────
const Color _surface = Color(0xFF111827);
const Color _surfaceCard = Color(0x14162B4C);
const Color _surfaceTint = Color(0x1A1B3769);
const Color _borderDim = Color(0x1A2D5299);
const Color _borderMed = Color(0x332D5299);
const Color _borderStrong = Color(0x4D2D5299);
const Color _divider = Color(0x262D5299);

const Color _blue = Color(0xFF60A5FA);
const Color _green = Color(0xFF34D399);
const Color _amber = Color(0xFFFBBF24);
const Color _red = Color(0xFFFC8181);

const Color _textPri = Color(0xE6FFFFFF);
const Color _textSec = Color(0x80FFFFFF);
const Color _textMut = Color(0x66FFFFFF);
const Color _textHint = Color(0x59FFFFFF);

/// A dialog that lets a super admin edit any user's non-sensitive fields.
class EditMemberDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final ValueChanged<Map<String, dynamic>> onSaved;

  const EditMemberDialog({super.key, required this.user, required this.onSaved});

  @override
  State<EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<EditMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // ── controllers ───────────────────────────────────────────────────────────
  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _course;
  late final TextEditingController _targetHours;
  late final TextEditingController _customId;
  late final TextEditingController _extensionName;
  late String _selectedSuffix;

  // ── toggles ───────────────────────────────────────────────────────────────
  late bool _isAdmin;
  late String _role;
  late String _status;

  static const List<String> _roles = ['student', 'supervisor'];
  static const List<String> _statuses = ['active', 'pending_for_delete', 'deleted'];
  static const List<String> _suffixes = ['', 'Jr.', 'Sr.', 'II', 'III', 'IV', 'V'];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _firstName = TextEditingController(text: u['first_name'] as String? ?? '');
    _middleName = TextEditingController(text: u['middle_name'] as String? ?? '');
    _lastName = TextEditingController(text: u['last_name'] as String? ?? '');
    _email = TextEditingController(text: u['email'] as String? ?? '');
    _course = TextEditingController(text: u['course'] as String? ?? '');
    _targetHours = TextEditingController(text: '${u['target_hours'] ?? 450}');
    _customId = TextEditingController(text: u['custom_id'] as String? ?? '');
    _extensionName = TextEditingController(text: (u['extension_name'] as String? ?? '').trim());

    final suffix = (u['suffix_name'] as String? ?? '').trim();
    _selectedSuffix = _suffixes.contains(suffix) ? suffix : '';

    _isAdmin = (u['isAdmin'] as bool?) ?? false;
    _role = (u['role'] as String?) ?? 'student';
    _status = (u['status'] as String?) ?? 'active';
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _email.dispose();
    _course.dispose();
    _targetHours.dispose();
    _customId.dispose();
    _extensionName.dispose();
    super.dispose();
  }

  // ── save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final cccId = widget.user['ccc_id'] as String;
    final body = <String, dynamic>{
      'first_name': _firstName.text.trim(),
      'middle_name': _middleName.text.trim(),
      'last_name': _lastName.text.trim(),
      'suffix_name': _selectedSuffix.trim().isEmpty ? null : _selectedSuffix.trim(),
      'extension_name': _extensionName.text.trim().isEmpty ? null : _extensionName.text.trim(),
      'email': _email.text.trim(),
      'course': _course.text.trim(),
      'target_hours': int.tryParse(_targetHours.text.trim()) ?? 450,
      'custom_id': _customId.text.trim(),
      'isAdmin': _isAdmin,
      'role': _role,
      'status': _status,
    };

    try {
      final r = await RequestHandler().handleRequest('super-admin/member/$cccId', method: 'POST', body: body);
      if (!mounted) return;

      if (r['success'] == true) {
        final updated = Map<String, dynamic>.from(r['user'] as Map);
        Navigator.pop(context, updated);
        widget.onSaved(updated);
      } else {
        AppSnackBar.error(context, r['message'] ?? 'Update failed.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  /// Returns the full name (first + middle initial + last) for the avatar fallback.
  String _initials() {
    final f = _firstName.text.isNotEmpty ? _firstName.text[0] : '';
    final l = _lastName.text.isNotEmpty ? _lastName.text[0] : '';
    return '$f$l'.toUpperCase();
  }

  /// Shows the avatar image if profile_link exists, otherwise initials.
  Widget _buildAvatar() {
    final profileLink = widget.user['profile_link'] as String?;
    final hasImage = profileLink != null && profileLink.isNotEmpty;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _blue.withOpacity(0.14),
        border: Border.all(color: _blue.withOpacity(0.22)),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(profileLink, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initialsAvatar())
            : _initialsAvatar(),
      ),
    );
  }

  Widget _initialsAvatar() {
    return Center(
      child: Text(
        _initials(),
        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: _blue),
      ),
    );
  }

  // ── sub‑widgets ───────────────────────────────────────────────────────────

  Widget _dividerLine() => Divider(height: 1, thickness: 1, color: _divider);

  Widget _sectionLabel(String label) => Text(
    label.toUpperCase(),
    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: _textMut),
  );

  Widget _warningBanner(String message, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.dmSans(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.dmSans(fontSize: 13, color: _textPri),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator ?? (required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 12, color: _textMut),
        hintStyle: GoogleFonts.dmSans(fontSize: 13, color: _textHint),
        prefixIcon: Icon(icon, size: 15, color: _textMut),
        filled: true,
        fillColor: _surfaceCard,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderDim),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderDim),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _red, width: 1.5),
        ),
        errorStyle: GoogleFonts.dmSans(fontSize: 10, color: _red),
      ),
    );
  }

  Widget _dropdownTile<T>({
    required IconData icon,
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) display,
    required ValueChanged<T?> onChanged,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderDim),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _textMut),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(fontSize: 11, color: _textMut, fontWeight: FontWeight.w500),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isDense: true,
                    dropdownColor: _surface,
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? _textPri),
                    icon: Icon(Icons.unfold_more_rounded, size: 16, color: _textMut),
                    items: items
                        .map(
                          (item) => DropdownMenuItem<T>(
                            value: item,
                            child: Text(display(item), style: GoogleFonts.dmSans(fontSize: 13, color: _textPri)),
                          ),
                        )
                        .toList(),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasWarning = _status != 'active';

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: 480,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderStrong),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.40), blurRadius: 32, offset: const Offset(0, 12))],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Row(
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Member',
                              style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: _textPri),
                            ),
                            Text(
                              widget.user['ccc_id'] as String? ?? '',
                              style: GoogleFonts.dmMono(fontSize: 11, color: _textMut),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _surfaceTint,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _borderMed),
                          ),
                          child: const Icon(Icons.close_rounded, size: 16, color: _textSec),
                        ),
                      ),
                    ],
                  ),
                ),

                _dividerLine(),

                // ── Body ─────────────────────────────────────────────────────
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.62),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasWarning) ...[
                          _warningBanner(
                            _status == 'deleted'
                                ? 'This account is soft-deleted. Changes will still be saved.'
                                : 'This account is pending deletion.',
                            _status == 'deleted' ? _red : _amber,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Name (first, middle, last, suffix, extension) ────
                        _sectionLabel('Full Name'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                controller: _firstName,
                                label: 'First name',
                                icon: Icons.person_outline_rounded,
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _field(
                                controller: _lastName,
                                label: 'Last name',
                                icon: Icons.person_outline_rounded,
                                required: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                controller: _middleName,
                                label: 'Middle name (optional)',
                                icon: Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _dropdownTile<String>(
                                icon: Icons.text_fields_rounded,
                                label: 'Suffix (optional)',
                                value: _selectedSuffix,
                                items: _suffixes,
                                display: (v) => v.isEmpty ? 'None' : v,
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedSuffix = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _field(
                          controller: _extensionName,
                          label: 'Extension (e.g., PhD, MD)',
                          icon: Icons.emoji_objects_outlined,
                        ),

                        const SizedBox(height: 16),

                        // ── Contact ──────────────────────────────────────────
                        _sectionLabel('Contact'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _email,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          required: true,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final ok = RegExp(r'^[\w\.\+\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(v.trim());
                            return ok ? null : 'Invalid email';
                          },
                        ),

                        const SizedBox(height: 16),

                        // ── Academic ─────────────────────────────────────────
                        _sectionLabel('Academic'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _course,
                          label: 'Course / Program',
                          icon: Icons.school_outlined,
                          required: _role == 'student',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                controller: _targetHours,
                                label: 'Target hours',
                                icon: Icons.timer_outlined,
                                required: _role == 'student',
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) {
                                  if (_role != 'student') return null;
                                  final n = int.tryParse(v?.trim() ?? '');
                                  if (n == null || n < 1) return 'Enter a valid number';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _field(
                                controller: _customId,
                                label: 'Custom ID (optional)',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Role & Permissions ───────────────────────────────
                        _sectionLabel('Role & Permissions'),
                        const SizedBox(height: 8),
                        _dropdownTile<String>(
                          icon: Icons.manage_accounts_outlined,
                          label: 'Role',
                          value: _role,
                          items: _roles,
                          display: (v) => v == 'student' ? 'Student' : 'Supervisor',
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _role = v;
                                if (v == 'supervisor') _isAdmin = false;
                              });
                            }
                          },
                        ),

                        // (Admin toggle removed – handled by role)
                        const SizedBox(height: 16),

                        // ── Account Status ───────────────────────────────────
                        _sectionLabel('Account Status'),
                        const SizedBox(height: 8),
                        _dropdownTile<String>(
                          icon: Icons.info_outline_rounded,
                          label: 'Status',
                          value: _status,
                          items: _statuses,
                          display: (v) => switch (v) {
                            'active' => 'Active',
                            'pending_for_delete' => 'Pending deletion',
                            'deleted' => 'Deleted (soft)',
                            _ => v,
                          },
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                          valueColor: switch (_status) {
                            'active' => _green,
                            'pending_for_delete' => _amber,
                            'deleted' => _red,
                            _ => _textSec,
                          },
                        ),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),

                _dividerLine(),

                // ── Footer ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textSec,
                            side: BorderSide(color: _borderMed),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: _textSec),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline_rounded, size: 16),
                          label: Text(
                            _saving ? 'Saving…' : 'Save Changes',
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _blue.withOpacity(0.45),
                            disabledForegroundColor: Colors.white54,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
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
        ),
      ),
    );
  }
}
