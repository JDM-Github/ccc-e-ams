import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const saNavy = Color(0xFF0A0A0F);
const saSurface = Color.fromARGB(255, 7, 16, 31);
const saCard = Color(0x14162B4C);
const saBlue = Color(0xFF60A5FA);
const saGreen = Color(0xFF4ADE80);
const saGreenDk = Color(0xFF16A34A);
const saBorder = Color(0x332D5299); // white 8 %

Future<bool?> showSAConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool isDanger = false,
  Color? confirmColor,
  IconData? confirmIcon,
}) {
  final color = confirmColor ?? (isDanger ? const Color(0xFFDC2626) : saGreenDk);
  final icon = confirmIcon ?? (isDanger ? Icons.warning_rounded : Icons.check_circle_outline_rounded);

  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF090F1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.30)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.10), blurRadius: 32, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDanger ? const Color(0xFFF87171) : Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withOpacity(0.50), height: 1.5),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: saGhostBtn(ctx, 'Cancel', false)),
                const SizedBox(width: 10),
                Expanded(child: saConfirmBtn(ctx, confirmLabel, color)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget saGhostBtn(BuildContext ctx, String label, bool result) {
  return GestureDetector(
    onTap: () => Navigator.pop(ctx, result),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.55)),
        ),
      ),
    ),
  );
}

Widget saConfirmBtn(BuildContext ctx, String label, Color color) {
  return GestureDetector(
    onTap: () => Navigator.pop(ctx, true),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.88), borderRadius: BorderRadius.circular(10)),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    ),
  );
}

/// Empty-state widget
Widget saEmpty(IconData icon, String msg) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: Colors.white.withOpacity(0.10)),
        const SizedBox(height: 12),
        Text(
          msg,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withOpacity(0.25), height: 1.5),
        ),
      ],
    ),
  );
}

/// Section header
Widget saSectionHeader(String title, {Widget? trailing}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.30),
            letterSpacing: 1.0,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    ),
  );
}

class SAStaggerItem extends StatefulWidget {
  final int index;
  final Widget child;
  const SAStaggerItem({super.key, required this.index, required this.child});

  @override
  State<SAStaggerItem> createState() => _SAStaggerItemState();
}

class _SAStaggerItemState extends State<SAStaggerItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final delay = widget.index * 60;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}


/// Stat tile used in dashboard
class SAStatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? sub;

  const SAStatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: saCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.38),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                if (sub != null)
                  Text(sub!, style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withOpacity(0.35))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stagger animation wrapper – wraps a list of widgets with staggered
/// fade+slide entrance driven by index × 60 ms delay.
class SAStaggerList extends StatefulWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  final double spacing;

  const SAStaggerList({super.key, required this.children, this.padding = const EdgeInsets.all(16), this.spacing = 10});

  @override
  State<SAStaggerList> createState() => _SAStaggerListState();
}

class _SAStaggerListState extends State<SAStaggerList> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<Animation<double>> _opacities = [];
  final List<Animation<Offset>> _slides = [];

  @override
  void initState() {
    super.initState();
    final total = widget.children.length;
    final totalMs = total * 60 + 280;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    for (var i = 0; i < total; i++) {
      final start = (i * 60) / totalMs;
      final end = start + 280 / totalMs;
      final interval = Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic);
      _opacities.add(Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: interval)));
      _slides.add(
        Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _ctrl, curve: interval)),
      );
    }
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: widget.padding,
      itemCount: widget.children.length,
      separatorBuilder: (_, __) => SizedBox(height: widget.spacing),
      itemBuilder: (_, i) => FadeTransition(
        opacity: _opacities[i],
        child: SlideTransition(position: _slides[i], child: widget.children[i]),
      ),
    );
  }
}
