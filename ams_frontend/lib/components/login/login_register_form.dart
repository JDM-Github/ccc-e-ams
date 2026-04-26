import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'login_widgets.dart';

class LoginRegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController cccIdController;
  final TextEditingController customIdController;
  final TextEditingController emailController;
  final TextEditingController officeNameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController creatorPasswordController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool isLoading;
  final String? regError;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  const LoginRegisterForm({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.cccIdController,
    required this.customIdController,
    required this.emailController,
    required this.officeNameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.creatorPasswordController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.isLoading,
    required this.regError,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LoginInfoBanner(
              icon: Icons.admin_panel_settings_outlined,
              message: 'Admin registration — creates a new office',
            ),
            const SizedBox(height: 14),

            if (regError != null) ...[LoginErrorBanner(regError!), const SizedBox(height: 12)],

            // First + Last name
            Row(
              children: [
                Expanded(
                  child: GlassInputField(
                    controller: firstNameController,
                    label: 'First Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassInputField(
                    controller: lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            GlassInputField(
              controller: middleNameController,
              label: 'Middle Name (Optional)',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 10),

            // CCC ID + Custom ID
            Row(
              children: [
                Expanded(
                  child: GlassInputField(
                    controller: cccIdController,
                    label: 'CCC ID',
                    icon: Icons.badge_outlined,
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassInputField(
                    controller: customIdController,
                    label: 'Custom ID',
                    icon: Icons.tag_rounded,
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) return 'Required';
                      if (v!.trim().length < 2) return 'Too short';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            GlassInputField(
              controller: officeNameController,
              label: 'Office Name',
              hint: 'e.g. CCS Office',
              icon: Icons.business_outlined,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 10),

            GlassInputField(
              controller: emailController,
              label: 'Email',
              hint: 'your@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v?.trim().isEmpty ?? true) return 'Required';
                if (!v!.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Password + Confirm
            Row(
              children: [
                Expanded(
                  child: GlassInputField(
                    controller: passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    obscureText: obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 15,
                        color: ThemeManager.muted(context),
                      ),
                      onPressed: onTogglePassword,
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (v!.length < 6) return 'Min 6 chars';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassInputField(
                    controller: confirmPasswordController,
                    label: 'Confirm',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    obscureText: obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 15,
                        color: ThemeManager.muted(context),
                      ),
                      onPressed: onToggleConfirm,
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (v != passwordController.text) return 'No match';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _CreatorPasswordField(controller: creatorPasswordController),
            const SizedBox(height: 18),

            GlassPrimaryButton(
              label: isLoading ? 'Sending code…' : 'Continue — Verify Email',
              isLoading: isLoading,
              onPressed: isLoading ? null : onSubmit,
              icon: Icons.email_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Creator Password Field
// ─────────────────────────────────────────────────────────────────────────────

class _CreatorPasswordField extends StatelessWidget {
  final TextEditingController controller;
  const _CreatorPasswordField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.bodyColor(context)),
      decoration: InputDecoration(
        labelText: 'Creator Password',
        hintText: 'Required to register',
        labelStyle: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context)),
        hintStyle: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.faint(context)),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.key_rounded, size: 15, color: ThemeManager.muted(context)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return TextButton(
              onPressed: () => controller.clear(),
              style: TextButton.styleFrom(
                foregroundColor: ThemeManager.muted(context),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Clear', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600)),
            );
          },
        ),
        filled: true,
        fillColor: ThemeManager.inputFillColor(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
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
          borderSide: BorderSide(color: ThemeManager.purple(context), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
          borderSide: BorderSide(color: ThemeManager.errorTextColor(context)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
          borderSide: BorderSide(color: ThemeManager.errorTextColor(context), width: 1.5),
        ),
        errorStyle: GoogleFonts.dmSans(color: ThemeManager.errorTextColor(context), fontSize: 11),
      ),
      validator: (v) {
        if (v?.trim().isEmpty ?? true) return 'Creator password is required';
        return null;
      },
    );
  }
}
