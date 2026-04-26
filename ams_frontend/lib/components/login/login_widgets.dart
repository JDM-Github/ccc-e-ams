import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Error Banner
// ─────────────────────────────────────────────────────────────────────────────

class LoginErrorBanner extends StatelessWidget {
  final String message;
  const LoginErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Banner  (blue tint — "Admin registration" notice)
// ─────────────────────────────────────────────────────────────────────────────

class LoginInfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  const LoginInfoBanner({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x1560A5FA) : const Color(0xFFEBF5FF),
        borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
        border: Border.all(
          color: isDark ? const Color(0x3360A5FA) : const Color(0xFFBFD8F5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: ThemeManager.blue(context), size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                color: ThemeManager.blue(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Input Field
// ─────────────────────────────────────────────────────────────────────────────

class GlassInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;

  const GlassInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.focusNode,
    this.nextFocusNode,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: GoogleFonts.dmSans(
        color: ThemeManager.bodyColor(context),
        fontSize: 13,
      ),
      onFieldSubmitted: onFieldSubmitted ??
          (nextFocusNode != null
              ? (_) => FocusScope.of(context).requestFocus(nextFocusNode)
              : null),
      decoration: ThemeManager.inputDeco(
        context,
        label: label,
        icon: icon,
        hint: hint,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary Button  (brand-blue gradient)
// ─────────────────────────────────────────────────────────────────────────────

class GlassPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const GlassPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null;
    return SizedBox(
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF1B3769), Color(0xFF2D5299)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : ThemeManager.surfaceTint(context),
          borderRadius: BorderRadius.circular(ThemeManager.radiusBtn),
          border: Border.all(
            color: active
                ? const Color(0x4060A5FA)
                : ThemeManager.border(context),
          ),
          boxShadow: active && !ThemeManager.isDark(context)
              ? [
                  BoxShadow(
                    color: ThemeManager.brand.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeManager.radiusBtn),
            ),
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: ThemeManager.muted(context),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 15),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: ThemeManager.buttonStyle(context)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Tab Bar
// ─────────────────────────────────────────────────────────────────────────────

class GlassTabBar extends StatelessWidget {
  final TabController controller;
  const GlassTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeManager.surface(context),
        borderRadius: BorderRadius.circular(ThemeManager.radiusInner),
        border: Border.all(color: ThemeManager.border(context)),
      ),
      padding: const EdgeInsets.all(3),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFF1B3769), Color(0xFF2D5299)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0x3360A5FA)),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: ThemeManager.secondary(context),
        labelStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Sign In'),
          Tab(text: 'Register'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Accent Badge  (branding panel pill)
// ─────────────────────────────────────────────────────────────────────────────

class AccentBadge extends StatelessWidget {
  final String text;
  final Color accent;
  const AccentBadge({super.key, required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: accent.withOpacity(0.12),
        border: Border.all(color: accent.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Branding Stat Cell
// ─────────────────────────────────────────────────────────────────────────────

class BrandingStatCell extends StatelessWidget {
  final String value;
  final String label;
  final bool showDivider;

  const BrandingStatCell({
    super.key,
    required this.value,
    required this.label,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ThemeManager.accentBlue,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: ThemeManager.faint(context),
                height: 1.4,
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          Container(
            width: 1,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: ThemeManager.dividerColor(context),
          ),
        ],
      ],
    );
  }
}