import 'dart:convert';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeProfileDialog extends StatefulWidget {
  const ChangeProfileDialog({super.key});

  @override
  State<ChangeProfileDialog> createState() => _ChangeProfileDialogState();
}

class _ChangeProfileDialogState extends State<ChangeProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final admin = LoginStore().superAdmin.value;
    _usernameCtrl = TextEditingController(text: admin['username'] ?? '');
    _emailCtrl = TextEditingController(text: admin['email'] ?? '');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final admin = LoginStore().superAdmin.value;
      final response = await RequestHandler().handleRequest(
        'super-admin/update-profile',
        method: 'POST',
        body: {'id': admin['id'], 'username': _usernameCtrl.text.trim(), 'email': _emailCtrl.text.trim()},
      );

      if (response['success'] == true) {
        final store = LoginStore();
        final updated = Map<String, dynamic>.from(store.superAdmin.value);
        updated['username'] = _usernameCtrl.text.trim();
        updated['email'] = _emailCtrl.text.trim();
        store.superAdmin.value = updated;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_in_super_admin', jsonEncode(updated));

        if (mounted) {
          AppSnackBar.success(context, 'Profile updated successfully.');
          Navigator.pop(context);
        }
      } else {
        if (mounted) AppSnackBar.error(context, response['message'] ?? 'Failed to update profile.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Network error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Super-admin panel stays intentionally always-dark
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(color: ThemeManager.brand.withOpacity(0.2), blurRadius: 32, offset: const Offset(0, 8)),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: ThemeManager.brand.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF60A5FA), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Profile',
                          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Text(
                          'Update username or email',
                          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSaving ? null : () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Icon(Icons.close_rounded, size: 16, color: Colors.white.withOpacity(0.45)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Container(height: 1, color: Colors.white.withOpacity(0.07)),
              const SizedBox(height: 24),

              // ── Username ──────────────────────────────────────────────────
              _inputField(
                controller: _usernameCtrl,
                label: 'Username',
                icon: Icons.person_outline_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Username is required';
                  if (v.trim().length < 3) return 'At least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Email ─────────────────────────────────────────────────────
              _inputField(
                controller: _emailCtrl,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w\.\+\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(v.trim()))
                    return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ── Info note ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 13, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'To change your password, use the Change Password option instead.',
                        style: GoogleFonts.dmSans(fontSize: 11, color: Colors.amber.withOpacity(0.75), height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Container(height: 1, color: Colors.white.withOpacity(0.07)),
              const SizedBox(height: 20),

              // ── Actions ───────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _cancelButton()),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: _saveButton('Save Changes')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _cancelButton() => GestureDetector(
    onTap: _isSaving ? null : () => Navigator.pop(context),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          'Cancel',
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54),
        ),
      ),
    ),
  );

  Widget _saveButton(String label) => GestureDetector(
    onTap: _isSaving ? null : _save,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _isSaving ? Colors.white.withOpacity(0.05) : ThemeManager.brand,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _isSaving ? Colors.white.withOpacity(0.08) : const Color(0x4060A5FA)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isSaving)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withOpacity(0.38)),
            )
          else
            const Icon(Icons.check_rounded, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            _isSaving ? 'Saving...' : label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _isSaving ? Colors.white38 : Colors.white,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.35)),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 16, color: Colors.white.withOpacity(0.25)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        errorStyle: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFFEF4444)),
      ),
    );
  }
}
