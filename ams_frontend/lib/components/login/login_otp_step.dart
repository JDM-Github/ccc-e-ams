import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'login_widgets.dart';

class LoginOtpStep extends StatelessWidget {
  final String email;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final bool isLoading;
  final String? otpError;
  final VoidCallback onBack;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  const LoginOtpStep({
    super.key,
    required this.email,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.isLoading,
    required this.otpError,
    required this.onBack,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Row(
              children: [
                Icon(Icons.arrow_back_rounded, size: 15, color: ThemeManager.secondary(context)),
                const SizedBox(width: 6),
                Text(
                  'Back',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: ThemeManager.secondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Email icon
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ThemeManager.green(context).withOpacity(0.12),
                borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                border: Border.all(color: ThemeManager.green(context).withOpacity(0.25)),
              ),
              child: Icon(Icons.mark_email_unread_outlined, color: ThemeManager.green(context), size: 26),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Check your email',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: ThemeManager.primary(context)),
          ),
          const SizedBox(height: 6),

          Text(
            'We sent a 6-digit code to\n$email',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context), height: 1.6),
          ),
          const SizedBox(height: 24),

          if (otpError != null) ...[LoginErrorBanner(otpError!), const SizedBox(height: 14)],

          // OTP boxes
          _OtpBoxes(controllers: otpControllers, focusNodes: otpFocusNodes),
          const SizedBox(height: 22),

          GlassPrimaryButton(
            label: isLoading ? 'Creating account…' : 'Verify & Create Account',
            isLoading: isLoading,
            onPressed: isLoading ? null : onVerify,
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 14),

          Center(
            child: GestureDetector(
              onTap: isLoading ? null : onResend,
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.dmSans(fontSize: 12),
                  children: [
                    TextSpan(
                      text: "Didn't receive it? ",
                      style: TextStyle(color: ThemeManager.secondary(context)),
                    ),
                    TextSpan(
                      text: 'Resend code',
                      style: TextStyle(color: ThemeManager.green(context), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP box row
// ─────────────────────────────────────────────────────────────────────────────

class _OtpBoxes extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  const _OtpBoxes({required this.controllers, required this.focusNodes});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 44,
          height: 52,
          child: TextFormField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
            style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: ThemeManager.primary(context)),
            decoration: InputDecoration(
              filled: true,
              fillColor: ThemeManager.inputFillColor(context),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                borderSide: BorderSide(color: ThemeManager.border(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                borderSide: BorderSide(color: ThemeManager.border(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
                borderSide: BorderSide(color: ThemeManager.green(context), width: 1.5),
              ),
            ),
            onChanged: (v) {
              if (v.isNotEmpty && i < 5) {
                focusNodes[i + 1].requestFocus();
              } else if (v.isEmpty && i > 0) {
                focusNodes[i - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}
