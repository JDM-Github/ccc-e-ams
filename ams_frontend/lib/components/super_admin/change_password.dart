import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PasswordStrength { empty, weak, fair, strong, superStrong }

class _StrengthResult {
  final PasswordStrength level;
  final int score;
  final List<String> tips;
  const _StrengthResult(this.level, this.score, this.tips);
}

_StrengthResult _evaluate(String password) {
  if (password.isEmpty) return const _StrengthResult(PasswordStrength.empty, 0, []);

  int score = 0;
  final tips = <String>[];

  if (RegExp(r'.{8,}').hasMatch(password)) {
    score++;
  } else {
    tips.add('At least 8 characters');
  }
  if (RegExp(r'[A-Z]').hasMatch(password)) {
    score++;
  } else {
    tips.add('One uppercase letter (A–Z)');
  }
  if (RegExp(r'[a-z]').hasMatch(password)) {
    score++;
  } else {
    tips.add('One lowercase letter (a–z)');
  }
  if (RegExp(r'[0-9]').hasMatch(password)) {
    score++;
  } else {
    tips.add('One number (0–9)');
  }
  if (RegExp("[!@#\$%^&*()_+\\-=\\[\\]{};':\",./<>?\\\\|`~]").hasMatch(password)) {
    score++;
  } else {
    tips.add('One special character (!@#\$…)');
  }

  final level = score <= 1
      ? PasswordStrength.weak
      : score == 2
      ? PasswordStrength.fair
      : score <= 4
      ? PasswordStrength.strong
      : PasswordStrength.superStrong;

  return _StrengthResult(level, score, tips);
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  _StrengthResult _strength = const _StrengthResult(PasswordStrength.empty, 0, []);

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_strength.level == PasswordStrength.weak || _strength.level == PasswordStrength.empty) {
      AppSnackBar.error(context, 'Please use a stronger password.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final admin = LoginStore().superAdmin.value;
      final response = await RequestHandler().handleRequest(
        'super-admin/change-password',
        method: 'POST',
        body: {'id': admin['id'], 'current_password': _currentCtrl.text, 'new_password': _newCtrl.text},
      );
      if (response['success'] == true) {
        if (mounted) {
          AppSnackBar.success(context, 'Password changed successfully.');
          Navigator.pop(context);
        }
      } else {
        if (mounted) AppSnackBar.error(context, response['message'] ?? 'Failed to change password.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Network error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Strength helpers ───────────────────────────────────────────────────────

  Color get _strengthColor => switch (_strength.level) {
    PasswordStrength.empty => Colors.white.withOpacity(0.12),
    PasswordStrength.weak => const Color(0xFFEF4444),
    PasswordStrength.fair => const Color(0xFFF59E0B),
    PasswordStrength.strong => const Color(0xFF3B82F6),
    PasswordStrength.superStrong => const Color(0xFF22C55E),
  };

  String get _strengthLabel => switch (_strength.level) {
    PasswordStrength.empty => '',
    PasswordStrength.weak => 'Weak',
    PasswordStrength.fair => 'Fair',
    PasswordStrength.strong => 'Strong',
    PasswordStrength.superStrong => 'Super Strong',
  };

  @override
  Widget build(BuildContext context) {
    // This dialog is always dark — it's a super-admin panel, never user-facing light UI
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF60A5FA), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Password',
                          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Text('Super Admin credentials', style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white38)),
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

              // ── Current password ──────────────────────────────────────────
              _passwordField(
                controller: _currentCtrl,
                label: 'Current Password',
                obscure: _obscureCurrent,
                toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (v) => (v == null || v.isEmpty) ? 'Current password is required' : null,
              ),
              const SizedBox(height: 14),

              // ── New password ──────────────────────────────────────────────
              _passwordField(
                controller: _newCtrl,
                label: 'New Password',
                obscure: _obscureNew,
                toggle: () => setState(() => _obscureNew = !_obscureNew),
                onChanged: (v) => setState(() => _strength = _evaluate(v)),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'New password is required';
                  if (v == _currentCtrl.text) return 'New password must differ from current';
                  return null;
                },
              ),

              if (_strength.level != PasswordStrength.empty) ...[const SizedBox(height: 10), _buildStrengthMeter()],
              const SizedBox(height: 14),

              // ── Confirm password ──────────────────────────────────────────
              _passwordField(
                controller: _confirmCtrl,
                label: 'Confirm New Password',
                obscure: _obscureConfirm,
                toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) => v != _newCtrl.text ? 'Passwords do not match' : null,
              ),

              const SizedBox(height: 24),
              Container(height: 1, color: Colors.white.withOpacity(0.07)),
              const SizedBox(height: 20),

              // ── Actions ───────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _cancelButton()),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: _saveButton('Change Password')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Strength meter ─────────────────────────────────────────────────────────

  Widget _buildStrengthMeter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            final filled = i < _strength.score;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: filled ? _strengthColor : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strengthLabel,
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: _strengthColor),
            ),
            if (_strength.tips.isNotEmpty) ...[
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '· ${_strength.tips.join(' · ')}',
                  style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white.withOpacity(0.3), height: 1.4),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Shared sub-widgets ─────────────────────────────────────────────────────

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

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.35)),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.lock_outline_rounded, size: 16, color: Colors.white.withOpacity(0.25)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 17,
            color: Colors.white.withOpacity(0.25),
          ),
          onPressed: toggle,
        ),
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
