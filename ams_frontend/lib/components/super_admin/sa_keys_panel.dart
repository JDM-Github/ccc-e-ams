import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/super_admin/delete_key.dart';
import 'package:ccc_ojt_schedule/components/super_admin/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SAKeysPanel extends StatefulWidget {
  final List<Map<String, dynamic>> keys;
  final bool loading;
  final VoidCallback onRefresh;

  const SAKeysPanel({super.key, required this.keys, required this.loading, required this.onRefresh});

  @override
  State<SAKeysPanel> createState() => _SAKeysPanelState();
}

class _SAKeysPanelState extends State<SAKeysPanel> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: saSurface,
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
          ),
          child: Row(
            children: [
              const Icon(Icons.vpn_key_rounded, size: 13, color: saGreen),
              const SizedBox(width: 8),
              Text(
                'Active Special Keys',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.80),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onRefresh,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.refresh_rounded, size: 14, color: Colors.white.withOpacity(0.35)),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: widget.loading
              ? const Center(child: CircularProgressIndicator(color: saBlue))
              : widget.keys.isEmpty
              ? saEmpty(Icons.vpn_key_outlined, 'No active keys\nTap "Create Key" to generate one')
              : SAStaggerList(
                  children: widget.keys.map((k) => _KeyCard(keyData: k, onDeleted: widget.onRefresh)).toList(),
                ),
        ),
      ],
    );
  }
}

// ─── Key card ─────────────────────────────────────────────────────────────────

class _KeyCard extends StatelessWidget {
  final Map<String, dynamic> keyData;
  final VoidCallback onDeleted;

  const _KeyCard({required this.keyData, required this.onDeleted});

  DateTime _toPHT(DateTime d) => d.toUtc().add(const Duration(hours: 8));

  String _remaining(Duration d) {
    if (d.isNegative) return 'expired';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m left';
    return '${d.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final expiresAt = keyData['expires_at'] != null ? DateTime.tryParse(keyData['expires_at'].toString()) : null;
    final remaining = expiresAt?.difference(DateTime.now());
    final soon = remaining != null && remaining.inMinutes < 30;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: saCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: soon ? Colors.orange.withOpacity(0.28) : Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key value row
          Row(
            children: [
              Expanded(
                child: Text(
                  keyData['key'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: saGreen,
                    letterSpacing: 2.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              // Copy
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: keyData['key'] ?? ''));
                  AppSnackBar.success(context, 'Key copied to clipboard');
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.copy_rounded, size: 13, color: Colors.white.withOpacity(0.38)),
                ),
              ),
              const SizedBox(width: 6),
              // Delete
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => DeleteSpecialKeyDialog(keyData: keyData, onDeleted: onDeleted),
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withOpacity(0.18)),
                  ),
                  child: Icon(Icons.delete_outline_rounded, size: 13, color: Colors.red.withOpacity(0.65)),
                ),
              ),
            ],
          ),

          // Email
          if (keyData['email'] != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 11, color: Colors.white.withOpacity(0.28)),
                const SizedBox(width: 4),
                Text(keyData['email'], style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white.withOpacity(0.42))),
              ],
            ),
          ],

          // Expiry
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 11, color: soon ? Colors.orange : Colors.white.withOpacity(0.28)),
              const SizedBox(width: 4),
              Text(
                expiresAt != null ? 'Expires ${DateFormat('hh:mm a').format(_toPHT(expiresAt))}' : 'No expiry info',
                style: GoogleFonts.dmSans(fontSize: 11, color: soon ? Colors.orange : Colors.white.withOpacity(0.35)),
              ),
              if (remaining != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: soon ? Colors.orange.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _remaining(remaining),
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: soon ? Colors.orange : Colors.white.withOpacity(0.22),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
