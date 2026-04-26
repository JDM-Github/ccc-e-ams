import 'package:ccc_ojt_schedule/components/dialogue_helpers.dart';
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
  PasswordStrength level;
  if (score <= 1)
    level = PasswordStrength.weak;
  else if (score == 2)
    level = PasswordStrength.fair;
  else if (score <= 4)
    level = PasswordStrength.strong;
  else
    level = PasswordStrength.superStrong;
  return _StrengthResult(level, score, tips);
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => ChangePasswordDialogState();
}

class ChangePasswordDialogState extends State<ChangePasswordDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  _StrengthResult _strength = const _StrengthResult(PasswordStrength.empty, 0, []);

  late AnimationController _barCtrl;
  late Animation<double> _barAnim;
  double _prevBarVal = 0.0;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _barAnim = Tween<double>(begin: 0.0, end: 0.0).animate(CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut));
    _newCtrl.addListener(_onNewChanged);
  }

  void _onNewChanged() {
    final result = _evaluate(_newCtrl.text);
    final target = result.score / 5.0;
    _barAnim = Tween<double>(
      begin: _prevBarVal,
      end: target,
    ).animate(CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut));
    _barCtrl
      ..reset()
      ..forward();
    _prevBarVal = target;
    setState(() => _strength = result);
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Color _strengthColor(bool isDark) {
    switch (_strength.level) {
      case PasswordStrength.empty:
        return ThemeManager.faint(context);
      case PasswordStrength.weak:
        return const Color(0xFFEF4444);
      case PasswordStrength.fair:
        return const Color(0xFFF97316);
      case PasswordStrength.strong:
        return const Color(0xFF22C55E);
      case PasswordStrength.superStrong:
        return const Color(0xFF0EA5E9);
    }
  }

  String get _strengthLabel {
    switch (_strength.level) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.superStrong:
        return 'Super strong';
    }
  }

  IconData get _strengthIcon {
    switch (_strength.level) {
      case PasswordStrength.empty:
        return Icons.lock_outline_rounded;
      case PasswordStrength.weak:
        return Icons.lock_open_rounded;
      case PasswordStrength.fair:
        return Icons.lock_outline_rounded;
      case PasswordStrength.strong:
        return Icons.lock_rounded;
      case PasswordStrength.superStrong:
        return Icons.shield_rounded;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      AppSnackBar.loading(context, 'Updating password…', id: 'cp-loading');
      final user = LoginStore().user.value;
      final response = await RequestHandler().handleRequest(
        'user/change-password',
        method: 'POST',
        body: {'ccc_id': user['ccc_id'], 'current_password': _currentCtrl.text, 'new_password': _newCtrl.text},
      );
      AppSnackBar.hide(context, id: 'cp-loading');
      if (response['success'] == true) {
        if (!mounted) return;
        AppSnackBar.success(context, 'Password changed successfully');
      } else {
        throw Exception(response['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.hide(context, id: 'cp-loading');
      AppSnackBar.error(context, 'Failed to change password: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    return Center(
      child: Container(
        width: 420,
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
                    child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF1B3769), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change password',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ThemeManager.primary(context),
                          ),
                        ),
                        Text(
                          'Update your account password',
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

            // Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _passwordField(
                      ctrl: _currentCtrl,
                      label: 'Current password',
                      obscure: _obscureCurrent,
                      toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      isDark: isDark,
                      validator: (v) => v == null || v.isEmpty ? 'This field is required' : null,
                    ),
                    const SizedBox(height: 12),
                    _passwordField(
                      ctrl: _newCtrl,
                      label: 'New password',
                      obscure: _obscureNew,
                      toggle: () => setState(() => _obscureNew = !_obscureNew),
                      isDark: isDark,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'This field is required';
                        final r = _evaluate(v);
                        if (r.level == PasswordStrength.weak || r.level == PasswordStrength.fair) {
                          return 'Password is too weak';
                        }
                        return null;
                      },
                    ),
                    if (_strength.level != PasswordStrength.empty) ...[
                      const SizedBox(height: 10),
                      _buildStrengthMeter(isDark),
                    ],
                    const SizedBox(height: 12),
                    _passwordField(
                      ctrl: _confirmCtrl,
                      label: 'Confirm new password',
                      obscure: _obscureConfirm,
                      toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      isDark: isDark,
                      validator: (v) => v != _newCtrl.text ? 'Passwords do not match' : null,
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: ThemeManager.dividerColor(context)),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(child: cancelBtn(context, isDark, onTap: _isSubmitting ? null : null)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3769),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        disabledBackgroundColor: ThemeManager.surfaceTint(context),
                        disabledForegroundColor: ThemeManager.muted(context),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Update password',
                              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
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

  Widget _buildStrengthMeter(bool isDark) {
    final color = _strengthColor(isDark);
    return AnimatedBuilder(
      animation: _barAnim,
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(_strengthIcon, key: ValueKey(_strengthIcon), size: 13, color: color),
              ),
              const SizedBox(width: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _strengthLabel,
                  key: ValueKey(_strengthLabel),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(left: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _strength.score ? color : ThemeManager.dividerColor(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Container(color: ThemeManager.dividerColor(context)),
                  FractionallySizedBox(
                    widthFactor: _barAnim.value,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_strength.tips.isNotEmpty &&
              _strength.level != PasswordStrength.strong &&
              _strength.level != PasswordStrength.superStrong) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.08 : 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Missing:',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                  const SizedBox(height: 4),
                  ..._strength.tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.radio_button_unchecked_rounded, size: 10, color: color.withOpacity(0.7)),
                          const SizedBox(width: 6),
                          Text(tip, style: GoogleFonts.dmSans(fontSize: 11, color: color.withOpacity(0.85))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_strength.level == PasswordStrength.strong || _strength.level == PasswordStrength.superStrong) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.08 : 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 13, color: color),
                  const SizedBox(width: 6),
                  Text(
                    _strength.level == PasswordStrength.superStrong
                        ? 'Excellent! Your password is very secure.'
                        : 'Good password. You\'re all set.',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController ctrl,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.primary(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.muted(context)),
        prefixIcon: Icon(Icons.lock_outline_rounded, size: 16, color: ThemeManager.muted(context)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 17,
            color: ThemeManager.muted(context),
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: ThemeManager.inputFillColor(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1B3769), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.errorTextColor(context)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.errorTextColor(context), width: 1.5),
        ),
        errorStyle: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.errorTextColor(context)),
      ),
    );
  }
}
