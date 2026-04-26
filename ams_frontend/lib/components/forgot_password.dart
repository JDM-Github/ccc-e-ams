import 'dart:math';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  final _cccIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  int _step = 1;
  bool _isVerifying = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isSubmitting = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _otpError;
  String _generatedOtp = '';

  bool get _step1Done => _step > 1;
  bool get _step2Done => _step > 2;
  bool get _busy => _isVerifying || _isSendingOtp || _isVerifyingOtp || _isSubmitting;

  @override
  void dispose() {
    _cccIdController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────

  Future<void> _verify() async {
    if (!_step1FormKey.currentState!.validate()) return;
    setState(() => _isVerifying = true);
    try {
      AppSnackBar.loading(context, 'Verifying identity…', id: 'verifyId');
      final response = await RequestHandler().handleRequest(
        'user/verify-identity',
        method: 'POST',
        body: {'ccc_id': _cccIdController.text.trim(), 'email': _emailController.text.trim()},
      );
      AppSnackBar.hide(context, id: 'verifyId');
      if (response['success'] == true) {
        await _sendOtp();
        if (mounted) setState(() => _step = 2);
      } else {
        throw Exception(response['message'] ?? 'Identity verification failed');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.hide(context, id: 'verifyId');
      AppSnackBar.error(context, 'Verification failed: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _sendOtp() async {
    setState(() => _isSendingOtp = true);
    try {
      final otp = (100000 + Random().nextInt(900000)).toString();
      _generatedOtp = otp;
      await RequestHandler().handleRequest(
        'send-email',
        method: 'POST',
        body: {
          'to': _emailController.text.trim(),
          'subject': 'CCC OJT — Password Reset Code',
          'html':
              '''
            <div style="font-family:sans-serif;max-width:480px;margin:auto">
              <h2 style="color:#1B3769">Password Reset Code</h2>
              <p style="color:#64748B;font-size:14px">
                Use the code below to reset your password. It expires in 10 minutes.
              </p>
              <div style="font-size:36px;font-weight:bold;letter-spacing:12px;
                          text-align:center;padding:24px;background:#F1F5F9;
                          border-radius:8px;color:#1B3769;margin:24px 0">
                $otp
              </div>
            </div>
          ''',
        },
      );
      for (final c in _otpControllers) c.clear();
      if (_otpFocusNodes[0].canRequestFocus) _otpFocusNodes[0].requestFocus();
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed to send code: $e');
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _otpError = null);
    await _sendOtp();
    if (mounted) AppSnackBar.success(context, 'New code sent!');
  }

  Future<void> _verifyOtp() async {
    final entered = _otpControllers.map((c) => c.text).join();
    if (entered.length < 6) {
      setState(() => _otpError = 'Please enter the complete 6-digit code');
      return;
    }
    if (entered != _generatedOtp) {
      setState(() => _otpError = 'Incorrect code. Please try again.');
      return;
    }
    setState(() {
      _isVerifyingOtp = true;
      _otpError = null;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted)
      setState(() {
        _isVerifyingOtp = false;
        _step = 3;
      });
  }

  Future<void> _resetPassword() async {
    if (!_step3FormKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      AppSnackBar.loading(context, 'Resetting password…', id: 'resetId');
      final response = await RequestHandler().handleRequest(
        'user/reset-password',
        method: 'POST',
        body: {
          'ccc_id': _cccIdController.text.trim(),
          'email': _emailController.text.trim(),
          'new_password': _newPasswordController.text,
        },
      );
      AppSnackBar.hide(context, id: 'resetId');
      if (response['success'] == true) {
        if (!mounted) return;
        AppSnackBar.success(context, 'Password reset successfully');
        Navigator.pop(context);
      } else {
        throw Exception(response['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.hide(context, id: 'resetId');
      AppSnackBar.error(context, 'Reset failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 460,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: ThemeManager.surfaceElevated(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeManager.borderStrong(context)),
          boxShadow: ThemeManager.isDark(context)
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
                  _headerIcon(Icons.lock_reset_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forgot Password',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ThemeManager.primary(context),
                          ),
                        ),
                        Text(
                          'Reset your account password',
                          style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context)),
                        ),
                      ],
                    ),
                  ),
                  _closeButton(),
                ],
              ),
            ),

            Divider(height: 1, color: ThemeManager.dividerColor(context)),

            // ── Step indicator ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  _stepChip(1, 'Verify Identity', active: _step == 1, done: _step1Done),
                  _stepLine(done: _step1Done),
                  _stepChip(2, 'Email OTP', active: _step == 2, done: _step2Done),
                  _stepLine(done: _step2Done),
                  _stepChip(3, 'New Password', active: _step == 3, done: false),
                ],
              ),
            ),

            Divider(height: 1, color: ThemeManager.dividerColor(context)),

            // ── Step content ──────────────────────────────────
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: switch (_step) {
                  1 => _buildStep1(key: const ValueKey('s1')),
                  2 => _buildStep2(key: const ValueKey('s2')),
                  _ => _buildStep3(key: const ValueKey('s3')),
                },
              ),
            ),

            Divider(height: 1, color: ThemeManager.dividerColor(context)),

            // ── Actions ───────────────────────────────────────
            _buildActions(),
          ],
        ),
      ),
    );
  }

  // ── Step 1 ────────────────────────────────────────────────────

  Widget _buildStep1({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoBanner(
              icon: Icons.info_outline_rounded,
              color: ThemeManager.blue(context),
              message: 'Enter your CCC ID and registered email to verify your identity.',
            ),
            const SizedBox(height: 16),
            _inputField(
              controller: _cccIdController,
              label: 'CCC ID',
              icon: Icons.badge_outlined,
              validator: (v) => v == null || v.trim().isEmpty ? 'CCC ID is required' : null,
            ),
            const SizedBox(height: 12),
            _inputField(
              controller: _emailController,
              label: 'Registered Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[\w\.\+\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(v)) return 'Enter a valid email';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2 ────────────────────────────────────────────────────

  Widget _buildStep2({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Email icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ThemeManager.green(context).withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: ThemeManager.green(context).withOpacity(0.20)),
            ),
            child: Icon(Icons.mark_email_unread_outlined, color: ThemeManager.green(context), size: 26),
          ),
          const SizedBox(height: 14),

          Text(
            'Check your email',
            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: ThemeManager.primary(context)),
          ),
          const SizedBox(height: 6),
          Text(
            'We sent a 6-digit code to\n${_emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context), height: 1.6),
          ),
          const SizedBox(height: 22),

          if (_otpError != null) ...[_errorBanner(_otpError!), const SizedBox(height: 14)],

          _otpBoxes(),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _isSendingOtp ? null : _resendOtp,
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.dmSans(fontSize: 12),
                children: [
                  TextSpan(
                    text: "Didn't receive it?  ",
                    style: TextStyle(color: ThemeManager.secondary(context)),
                  ),
                  TextSpan(
                    text: _isSendingOtp ? 'Sending…' : 'Resend code',
                    style: TextStyle(
                      color: _isSendingOtp ? ThemeManager.muted(context) : ThemeManager.green(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3 ────────────────────────────────────────────────────

  Widget _buildStep3({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Form(
        key: _step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoBanner(
              icon: Icons.check_circle_outline_rounded,
              color: ThemeManager.green(context),
              message: 'Identity verified. You can now set a new password.',
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: _newPasswordController,
              label: 'New Password',
              obscure: _obscureNew,
              toggle: () => setState(() => _obscureNew = !_obscureNew),
              validator: (v) {
                if (v == null || v.isEmpty) return 'This field is required';
                if (v.length < 8) return 'Minimum 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: _confirmController,
              label: 'Confirm New Password',
              obscure: _obscureConfirm,
              toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) => v != _newPasswordController.text ? 'Passwords do not match' : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions row ───────────────────────────────────────────────

  Widget _buildActions() {
    final VoidCallback? primary;
    final String label;
    final IconData icon;

    switch (_step) {
      case 1:
        primary = _busy ? null : _verify;
        label = 'Verify Identity';
        icon = Icons.verified_user_outlined;
        break;
      case 2:
        primary = _busy ? null : _verifyOtp;
        label = 'Confirm Code';
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        primary = _busy ? null : _resetPassword;
        label = 'Reset Password';
        icon = Icons.lock_reset_rounded;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Back / Cancel
          if (_step > 1) ...[
            OutlinedButton.icon(
              onPressed: _busy ? null : () => setState(() => _step -= 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeManager.secondary(context),
                side: BorderSide(color: ThemeManager.border(context)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 15),
              label: Text('Back', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeManager.secondary(context),
                  side: BorderSide(color: ThemeManager.border(context)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Primary action
          Expanded(
            child: ElevatedButton.icon(
              onPressed: primary,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeManager.blue(context),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                disabledBackgroundColor: ThemeManager.surfaceTint(context),
                disabledForegroundColor: ThemeManager.muted(context),
              ),
              icon: _busy
                  ? SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withOpacity(0.8)),
                    )
                  : Icon(icon, size: 15),
              label: Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared sub-widgets ────────────────────────────────────────

  Widget _headerIcon(IconData icon) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: ThemeManager.blue(context).withOpacity(ThemeManager.isDark(context) ? 0.15 : 0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: ThemeManager.blue(context), size: 20),
  );

  Widget _closeButton() => GestureDetector(
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
  );

  // Step indicator helpers
  Widget _stepLine({required bool done}) => Expanded(
    child: Container(
      height: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: done ? ThemeManager.blue(context).withOpacity(0.35) : ThemeManager.dividerColor(context),
    ),
  );

  Widget _stepChip(int number, String label, {required bool active, required bool done}) {
    final color = active || done ? ThemeManager.blue(context) : ThemeManager.muted(context);
    final bg = active
        ? ThemeManager.blue(context).withOpacity(ThemeManager.isDark(context) ? 0.15 : 0.08)
        : done
        ? ThemeManager.blue(context).withOpacity(0.06)
        : ThemeManager.surfaceTint(context);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(
            child: done
                ? Icon(Icons.check_rounded, size: 13, color: color)
                : Text(
                    '$number',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _otpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextFormField(
            controller: _otpControllers[i],
            focusNode: _otpFocusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
            style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700, color: ThemeManager.primary(context)),
            decoration: InputDecoration(
              filled: true,
              fillColor: ThemeManager.inputFillColor(context),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                borderSide: BorderSide(color: ThemeManager.inputBorderColor(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                borderSide: BorderSide(
                  color: _otpError != null
                      ? ThemeManager.errorTextColor(context)
                      : ThemeManager.inputBorderColor(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                borderSide: BorderSide(color: ThemeManager.inputFocusedColor(context), width: 2),
              ),
            ),
            onChanged: (v) {
              if (v.isNotEmpty && i < 5) _otpFocusNodes[i + 1].requestFocus();
              if (v.isEmpty && i > 0) _otpFocusNodes[i - 1].requestFocus();
              setState(() => _otpError = null);
            },
          ),
        );
      }),
    );
  }

  Widget _infoBanner({required IconData icon, required Color color, required String message}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(ThemeManager.isDark(context) ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
        border: Border.all(color: color.withOpacity(ThemeManager.isDark(context) ? 0.25 : 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeManager.errorBgColor(context),
        borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
        border: Border.all(color: ThemeManager.errorBorderColor(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: ThemeManager.errorTextColor(context), size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                color: ThemeManager.errorTextColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.bodyColor(context)),
      decoration: ThemeManager.inputDeco(context, label: label, icon: icon),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.bodyColor(context)),
      decoration: ThemeManager.inputDeco(
        context,
        label: label,
        icon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 17,
            color: ThemeManager.muted(context),
          ),
          onPressed: toggle,
        ),
      ),
    );
  }
}
