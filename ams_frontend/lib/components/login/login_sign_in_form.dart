import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'login_widgets.dart';

class LoginSignInForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController cccIdController;
  final TextEditingController passwordController;
  final FocusNode cccIdFocus;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final bool rememberMe;
  final String? loginError;
  final ValueNotifier<bool> isLoading;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onForgotPassword;
  final VoidCallback onLogin;

  const LoginSignInForm({
    super.key,
    required this.formKey,
    required this.cccIdController,
    required this.passwordController,
    required this.cccIdFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.rememberMe,
    required this.loginError,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onRememberMeChanged,
    required this.onForgotPassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loginError != null) ...[LoginErrorBanner(loginError!), const SizedBox(height: 16)],

            // CCC ID / Email
            GlassInputField(
              controller: cccIdController,
              focusNode: cccIdFocus,
              nextFocusNode: passwordFocus,
              label: 'CCC ID or Email',
              hint: 'Enter your CCC ID or email',
              icon: Icons.person_outline_rounded,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Password
            GlassInputField(
              controller: passwordController,
              focusNode: passwordFocus,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onLogin(),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 17,
                  color: ThemeManager.muted(context),
                ),
                onPressed: onTogglePassword,
              ),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (v!.length < 6) return 'Min 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Remember me + Forgot password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 17,
                      height: 17,
                      child: Checkbox(
                        value: rememberMe,
                        onChanged: onRememberMeChanged,
                        activeColor: ThemeManager.accentBlue,
                        checkColor: Colors.white,
                        side: BorderSide(color: ThemeManager.borderStrong(context), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: ThemeManager.secondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onForgotPassword,
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: ThemeManager.blue(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Sign In button
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, _) => GlassPrimaryButton(
                label: 'Sign In',
                isLoading: loading,
                onPressed: loading ? null : onLogin,
                icon: Icons.login_rounded,
              ),
            ),

            const SizedBox(height: 20),

            // Divider
            Row(
              children: [
                Expanded(child: Container(height: 1, color: ThemeManager.dividerColor(context))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'SECURE ACCESS',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: ThemeManager.faint(context),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1, color: ThemeManager.dividerColor(context))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
