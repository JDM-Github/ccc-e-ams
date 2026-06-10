import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSnackBar {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final Map<String, ScaffoldFeatureController<SnackBar, SnackBarClosedReason>> _activeSnackBars = {};
  static final Map<String, OverlayEntry> _loadingOverlays = {};
  static final Map<String, OverlayEntry> _toastOverlays = {};

  // ─── Public API ────────────────────────────────────────────────────────────

  static void success(BuildContext? context, String message, {String? id}) {
    _hideLoading(id);
    _show(_resolve(context), message: message, type: _SnackType.success, id: id);
  }

  static void error(BuildContext? context, String message, {String? id}) {
    _hideLoading(id);
    _show(_resolve(context), message: message, type: _SnackType.error, id: id);
  }

  static void warning(BuildContext? context, String message, {String? id}) {
    _hideLoading(id);
    _show(_resolve(context), message: message, type: _SnackType.warning, id: id);
  }

  static void info(BuildContext? context, String message, {String? id}) {
    _hideLoading(id);
    _show(_resolve(context), message: message, type: _SnackType.info, id: id);
  }

  static void loading(BuildContext? context, String message, {String? id}) {
    final key = id ?? 'default';
    _hideLoading(key);
    final ctx = _resolve(context);
    if (ctx == null) return;
    final bool isDark = ThemeManager.isDark(navigatorKey.currentContext ?? ctx);
    final overlay = OverlayEntry(
      builder: (_) => _LoadingOverlay(message: message, isDark: isDark),
    );
    _safeInsert(ctx, overlay, rootOverlay: true);
    _loadingOverlays[key] = overlay;
  }

  static void hide(BuildContext? context, {String? id}) {
    final key = id ?? 'default';
    _hideLoading(key);
    _hideToast(key);
    final controller = _activeSnackBars[key];
    if (controller != null) {
      controller.close();
      _activeSnackBars.remove(key);
    }
  }

  static void hideAll(BuildContext? context) {
    for (final o in _loadingOverlays.values) {
      _safeRemove(o);
    }
    _loadingOverlays.clear();
    for (final o in _toastOverlays.values) {
      _safeRemove(o);
    }
    _toastOverlays.clear();
    for (final c in _activeSnackBars.values) {
      c.close();
    }
    _activeSnackBars.clear();
  }

  // ─── Context resolution ────────────────────────────────────────────────────

  static BuildContext? _resolve(BuildContext? context) {
    if (context == null) {
      final navCtx = navigatorKey.currentContext;
      if (navCtx != null && _isMounted(navCtx)) return navCtx;
      return null;
    }
    if (_isMounted(context)) return context;
    final navCtx = navigatorKey.currentContext;
    if (navCtx != null && _isMounted(navCtx)) return navCtx;
    return null;
  }

  static bool _isMounted(BuildContext context) {
    if (context is Element) return context.mounted;
    return false;
  }

  // ─── Safe overlay helpers ─────────────────────────────────────────────────
  static void _safeInsert(BuildContext context, OverlayEntry entry, {bool rootOverlay = false}) {
    try {
      final overlayState = navigatorKey.currentState?.overlay;
      if (overlayState == null) {
        debugPrint('[AppSnackBar] No overlay state available');
        return;
      }
      overlayState.insert(entry);
    } catch (e) {
      debugPrint('[AppSnackBar] Could not insert overlay: $e');
    }
  }

  static void _safeRemove(OverlayEntry entry) {
    try {
      entry.remove();
    } catch (_) {}
  }

  // ─── Internal ──────────────────────────────────────────────────────────────

  static void _hideLoading(String? id) {
    final entry = _loadingOverlays.remove(id ?? 'default');
    if (entry != null) _safeRemove(entry);
  }

  static void _hideToast(String? id) {
    final entry = _toastOverlays.remove(id ?? 'default');
    if (entry != null) _safeRemove(entry);
  }

  static void _show(BuildContext? context, {required String message, required _SnackType type, String? id}) {
    if (context == null) {
      debugPrint('[AppSnackBar] No valid context — skipping snack: $message');
      return;
    }
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    if (isLandscape) {
      _showPcToast(context, message: message, type: type, id: id);
    } else {
      _showMobileSnackBar(context, message: message, type: type, id: id);
    }
  }

  // ── PC: top-right overlay toast ────────────────────────────────────────────

  static void _showPcToast(
    BuildContext context, {
    required String message,
    required _SnackType type,
    String? id,
    Duration duration = const Duration(seconds: 4),
  }) {
    final key = id ?? 'default';
    _hideToast(key);
    _activeSnackBars[key]?.close();
    _activeSnackBars.remove(key);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _PcToast(
        message: message,
        type: type,
        duration: duration,
        isDark: ThemeManager.isDark(context),
        onDismiss: () {
          _safeRemove(entry);
          _toastOverlays.remove(key);
        },
      ),
    );

    _safeInsert(context, entry, rootOverlay: true);
    _toastOverlays[key] = entry;
  }

  // ── Mobile: bottom snackbar ────────────────────────────────────────────────

  static void _showMobileSnackBar(
    BuildContext context, {
    required String message,
    required _SnackType type,
    String? id,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (id != null) hide(context, id: id);

    ScaffoldMessengerState? messenger;
    try {
      messenger = ScaffoldMessenger.of(context);
    } catch (_) {
      _showPcToast(context, message: message, type: type, id: id);
      return;
    }

    final isDark = ThemeManager.isDark(context);

    final snackBar = SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
            child: Icon(type.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  type.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.75),
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: isDark ? type.darkBgColor : type.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
      duration: duration,
      elevation: isDark ? 0 : 8,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      dismissDirection: DismissDirection.horizontal,
    );

    try {
      final controller = messenger.showSnackBar(snackBar);
      if (id != null) {
        _activeSnackBars[id] = controller;
        controller.closed.then((_) => _activeSnackBars.remove(id));
      }
    } catch (e) {
      debugPrint('[AppSnackBar] showSnackBar failed, falling back to toast: $e');
      _showPcToast(context, message: message, type: type, id: id);
    }
  }
}

// ─── Type enum ─────────────────────────────────────────────────────────────────

enum _SnackType { success, error, warning, info }

extension _SnackTypeX on _SnackType {
  Color get color => switch (this) {
    _SnackType.success => const Color(0xFF1B3769),
    _SnackType.error => const Color(0xFFDC2626),
    _SnackType.warning => const Color(0xFFD97706),
    _SnackType.info => const Color(0xFF2563EB),
  };

  Color get darkBgColor => switch (this) {
    _SnackType.success => const Color(0xFF1E3A6E),
    _SnackType.error => const Color(0xFF991B1B),
    _SnackType.warning => const Color(0xFF92400E),
    _SnackType.info => const Color(0xFF1D4ED8),
  };

  Color get lightToastBg => switch (this) {
    _SnackType.success => const Color(0xFFF0F5FF),
    _SnackType.error => const Color(0xFFFEF2F2),
    _SnackType.warning => const Color(0xFFFFFBEB),
    _SnackType.info => const Color(0xFFEFF6FF),
  };

  Color get darkToastBg => switch (this) {
    _SnackType.success => const Color(0xFF0D1F3C),
    _SnackType.error => const Color(0xFF1C0A0A),
    _SnackType.warning => const Color(0xFF1C1200),
    _SnackType.info => const Color(0xFF0A1628),
  };

  Color get lightBorder => switch (this) {
    _SnackType.success => const Color(0xFFBFCFEC),
    _SnackType.error => const Color(0xFFFECACA),
    _SnackType.warning => const Color(0xFFFDE68A),
    _SnackType.info => const Color(0xFFBFDBFE),
  };

  Color get darkBorder => switch (this) {
    _SnackType.success => const Color(0x991B3769),
    _SnackType.error => const Color(0xB27F1D1D),
    _SnackType.warning => const Color(0xB278350F),
    _SnackType.info => const Color(0xB21E3A5F),
  };

  Color get iconColor => switch (this) {
    _SnackType.success => const Color(0xFF2563EB),
    _SnackType.error => const Color(0xFFDC2626),
    _SnackType.warning => const Color(0xFFD97706),
    _SnackType.info => const Color(0xFF2563EB),
  };

  Color get darkIconColor => switch (this) {
    _SnackType.success => const Color(0xFF60A5FA),
    _SnackType.error => const Color(0xFFF87171),
    _SnackType.warning => const Color(0xFFFBBF24),
    _SnackType.info => const Color(0xFF60A5FA),
  };

  IconData get icon => switch (this) {
    _SnackType.success => Icons.check_circle_rounded,
    _SnackType.error => Icons.error_rounded,
    _SnackType.warning => Icons.warning_rounded,
    _SnackType.info => Icons.info_rounded,
  };

  String get label => switch (this) {
    _SnackType.success => 'Success',
    _SnackType.error => 'Error',
    _SnackType.warning => 'Warning',
    _SnackType.info => 'Info',
  };
}

class _LoadingOverlay extends StatelessWidget {
  final String message;
  final bool isDark;

  const _LoadingOverlay({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          ModalBarrier(dismissible: false, color: isDark ? Colors.black.withOpacity(0.6) : Colors.black45),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1B3769).withOpacity(isDark ? 0.15 : 0.07),
                      border: Border.all(color: const Color(0xFF1B3769).withOpacity(isDark ? 0.25 : 0.12)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B3769)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white.withOpacity(0.90) : const Color(0xFF0F172A),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please wait…',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white.withOpacity(0.35) : const Color(0xFF94A3B8),
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
}

// ─── PC Toast widget ───────────────────────────────────────────────────────────

class _PcToast extends StatefulWidget {
  final String message;
  final _SnackType type;
  final Duration duration;
  final bool isDark;
  final VoidCallback onDismiss;

  const _PcToast({
    required this.message,
    required this.type,
    required this.duration,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  State<_PcToast> createState() => _PcToastState();
}

class _PcToastState extends State<_PcToast> with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _progressCtrl;

  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _opacity = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.12, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _progressCtrl = AnimationController(vsync: this, duration: widget.duration);

    _entryCtrl.forward();
    _progressCtrl.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    await _entryCtrl.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.type;
    final isDark = widget.isDark;
    final bg = isDark ? t.darkToastBg : t.lightToastBg;
    final border = isDark ? t.darkBorder : t.lightBorder;
    final ic = isDark ? t.darkIconColor : t.iconColor;
    final textColor = isDark ? Colors.white.withOpacity(0.90) : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white.withOpacity(0.45) : const Color(0xFF6B7280);

    return Positioned(
      top: 16,
      right: 16,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 330,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(color: ic.withOpacity(isDark ? 0.08 : 0.12), blurRadius: 20, offset: const Offset(0, 6)),
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: ic.withOpacity(isDark ? 0.15 : 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(t.icon, color: ic, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  t.label,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ic,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.message,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12.5,
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _dismiss,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: ic.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(Icons.close_rounded, size: 13, color: subColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _progressCtrl,
                      builder: (_, __) => Container(
                        height: 3,
                        color: ic.withOpacity(isDark ? 0.08 : 0.06),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1.0 - _progressCtrl.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: ic.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
